using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using CraftManagementAPI.Data;
using CraftManagementAPI.Models;

[ApiController]
[Route("api/[controller]")]

public class ArtisanController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public ArtisanController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet("my-products")]
    [Authorize]
    public async Task<IActionResult> GetMyProducts()
    {
        var artisanSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (artisanSSN == null)
        {
            return Unauthorized(new { Message = "Invalid token." });
        }

        // الرابط الأساسي للصور — عدله حسب مشروعك
        var baseUrl = $"{Request.Scheme}://{Request.Host}/";

        // جلب بيانات الحرفي مع المنتجات
        var artisanWithProducts = await _context.Users
            .Where(u => u.SSN == artisanSSN && u.Role == "Artisan")
            .Include(u => u.Products!.Where(p => p.Status != "Deleted"))
            .ThenInclude(p => p.ProductImages)
            .Include(u => u.Products!.Where(p => p.Status != "Deleted"))
            .ThenInclude(p => p.Category)
            .Select(u => new
            {
                FullName = u.Full_Name,
                ProfileImage = !string.IsNullOrEmpty(u.Image) ? $"{baseUrl}uploads_Profile_image/{u.Image}" : null,
                RatingAverage = u.Rating_Average,
                Products = u.Products!.Select(p => new
                {
                    ArtisanSSN = p.User_SSN,
                    ProductID = p.Product_ID,
                    ProductName = p.Name,
                    Description = p.Description,
                    Price = p.Price,
                    Quantity = p.Quantity,
                    Status = p.Status,
                    RatingAverage = p.Rating_Average,
                    CategoryName = p.Category != null ? p.Category.Cat_Type : "No Category",
                    Images = p.ProductImages.Select(img => $"{baseUrl}{img.Images.TrimStart('/')}").ToList()
                }).ToList()
            })
            .FirstOrDefaultAsync();

        if (artisanWithProducts == null)
            return NotFound(new { Message = "Artisan not found or has no products." });

        return Ok(artisanWithProducts);
    }
    [Authorize(Roles = "Artisan")]
    [HttpPut("edit-product/{productId}")]
    public async Task<IActionResult> UpdateProduct(int productId, [FromForm] UpdateProductRequest request, List<IFormFile>? productImages)
    {
        var artisanSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (artisanSSN == null)
            return Unauthorized(new { Message = "Invalid token." });

        var product = await _context.Products
            .Include(p => p.Category)
            .Include(p => p.ProductImages)
            .FirstOrDefaultAsync(p => p.Product_ID == productId && p.User_SSN == artisanSSN);

        if (product == null)
            return NotFound(new { Message = "Product not found or you don't have permission to edit it." });

        // ✅ تعديل بيانات المنتج
        product.Name = request.Name ?? product.Name;
        product.Price = request.Price ?? product.Price;
        product.Quantity = request.Quantity ?? product.Quantity;
        product.Description = request.Description ?? product.Description;

        // ✅ تعديل حالة المنتج يدويًا
        if (!string.IsNullOrEmpty(request.Status))
        {
            product.Status = request.Status;
        }
        else
        {
            product.Status = product.Quantity == 0 ? "OutOfStock" : "Available";
        }

        // ✅ تعديل الفئة بناءً على Cat_Type
        if (!string.IsNullOrWhiteSpace(request.Cat_Type))
        {
            var category = await _context.Categories.FirstOrDefaultAsync(c => c.Cat_Type.ToLower() == request.Cat_Type.ToLower());
            if (category == null)
                return NotFound(new { Message = "Category not found." });

            product.Cat_ID = category.Cat_ID;
        }

        // ✅ حذف الصور بناءً على الفهارس
        if (request.ImagesToDelete != null && request.ImagesToDelete.Any())
        {
            // تحويل الصور إلى قائمة مع فهارس
            var imagesList = product.ProductImages.ToList();
            var imagesToDelete = new List<ProductImage>();

            foreach (var index in request.ImagesToDelete.OrderByDescending(i => i))
            {
                if (index >= 0 && index < imagesList.Count)
                {
                    imagesToDelete.Add(imagesList[index]);
                }
            }

            foreach (var image in imagesToDelete)
            {
                var filePath = Path.Combine("wwwroot", image.Images);
                if (System.IO.File.Exists(filePath))
                    System.IO.File.Delete(filePath);

                _context.ProductImages.Remove(image);
            }
        }

        // ✅ إضافة الصور الجديدة
        if (productImages != null && productImages.Any())
        {
            var uploadsFolder = Path.Combine("wwwroot/uploads_Products");
            Directory.CreateDirectory(uploadsFolder);

            foreach (var image in productImages)
            {
                var uniqueFileName = $"{Guid.NewGuid()}_{image.FileName}";
                var filePath = Path.Combine(uploadsFolder, uniqueFileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await image.CopyToAsync(stream);
                }

                _context.ProductImages.Add(new ProductImage
                {
                    Product_ID = product.Product_ID,
                    Images = $"uploads_Products/{uniqueFileName}"
                });
            }
        }

        await _context.SaveChangesAsync();

        // ✅ استرجاع الصور مع فهارسها (معالجة على الجانب العميل)
        var updatedImages = await _context.ProductImages
            .Where(pi => pi.Product_ID == product.Product_ID)
            .Select(pi => pi.Images) // استرجع مسارات الصور فقط
            .ToListAsync();

        // تحويل المسارات إلى كائنات تحتوي على فهارس وروابط
        var formattedImages = updatedImages
            .Select((image, index) => new
            {
                Index = index,
                Url = $"{Request.Scheme}://{Request.Host}/{image.TrimStart('/')}"
            })
            .ToList();

        return Ok(new
        {
            Message = "Product updated successfully.",
            UpdatedProduct = new
            {
                product.Product_ID,
                product.Name,
                product.Price,
                product.Quantity,
                product.Status,
                Images = formattedImages,
                Category = product.Category?.Cat_Type ?? "No Category"
            }
        });
    }

           
    [HttpGet("artisan/{ssn}")]
    public async Task<IActionResult> GetArtisanProfile(string ssn)
    {
        // الرابط الأساسي للصور — عدله حسب مشروعك
        var baseUrl = $"{Request.Scheme}://{Request.Host}/";

        var artisan = await _context.Users
            .Where(u => u.SSN == ssn && u.Role == "Artisan")
            .Include(u => u.Products!.Where(p => p.Status != "Deleted")) // جلب المنتجات
            .ThenInclude(p => p.ProductImages) // جلب صور المنتجات
            .Select(u => new
            {
                FullName = u.Full_Name,
                ProfileImage = !string.IsNullOrEmpty(u.Image) ? $"{baseUrl}uploads_Profile_image/{u.Image}" : null, // صورة البروفايل
                RatingAverage = u.Rating_Average,
                Products = u.Products!.Select(p => new
                {
                    ProductID = p.Product_ID,
                    ProductName = p.Name,
                    Description = p.Description,
                    Price = p.Price,
                    RatingAverage = p.Rating_Average,
                    ProductImages = p.ProductImages!.Select(img => $"{baseUrl}{img.Images.TrimStart('/')}").ToList() // صور المنتجات
                }).ToList()
            })
            .FirstOrDefaultAsync();

        if (artisan == null)
            return NotFound(new { Message = "Artisan not found." });

        return Ok(artisan);
    }



    public class UpdateProductRequest
    {
        public string? Name { get; set; }
        public decimal? Price { get; set; }
        public int? Quantity { get; set; }
        public string? Description { get; set; }
        public string? Cat_Type { get; set; } // بدل Cat_ID
        public string? Status { get; set; }   // ✅ حالة المنتج (اختياري)
        public List<int>? ImagesToDelete { get; set; } // روابط الصور المراد حذفها    }
    }
}