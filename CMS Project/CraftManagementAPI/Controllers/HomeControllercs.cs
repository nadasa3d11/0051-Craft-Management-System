using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CraftManagementAPI.Data;
using CraftManagementAPI.Models;
using Microsoft.AspNetCore.Authorization;

namespace CraftManagementAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HomeController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public HomeController(ApplicationDbContext context)
        {
            _context = context;
        }

        // ✅ عرض كل المنتجات المتاحة للجميع (حتى بدون تسجيل دخول)
        [Authorize]
        [HttpGet("products")]
        public async Task<IActionResult> GetAllProducts([FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 10)
        {
            var baseUrl = $"{Request.Scheme}://{Request.Host}/";

            var query = _context.Products
                .Where(p => p.Status != "Deleted" && p.Quantity > 0)
                .Include(p => p.ProductImages)
                .Include(p => p.Category);

            var totalCount = await query.CountAsync();

            var products = await query
                .OrderByDescending(p => p.Product_ID) // الأحدث أولًا
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .Select(p => new
                {
                    p.Product_ID,
                    p.Name,
                    p.Price,
                    p.Description,
                    Category = p.Category != null ? p.Category.Cat_Type : "No Category",
                    Images = p.ProductImages
                        .Select(img => $"{baseUrl}{img.Images.TrimStart('/')}").ToList()
                })
                .ToListAsync();

            return Ok(new
            {
                TotalCount = totalCount,
                PageNumber = pageNumber,
                PageSize = pageSize,
                Products = products
            });
        }

        [Authorize]
        [HttpGet("latest-products")]
        public async Task<IActionResult> GetLatestProducts()
        {
            var baseUrl = $"{Request.Scheme}://{Request.Host}/";

            var products = await _context.Products
                .Include(p => p.Category)
                .Include(p => p.ProductImages)
                .Include(p => p.User) // artisan
                .OrderByDescending(p => p.Product_ID)
                .Take(20)
                .Select(p => new
                {
                    p.Product_ID,
                    p.Name,
                    p.Description,
                    p.Price,
                    p.Quantity,
                 
                    Images = p.ProductImages.Select(img => $"{baseUrl}{img.Images.TrimStart('/')}")
                })
                .ToListAsync();

            return Ok(products);
        }

        // ✅ عرض تفاصيل منتج معين
        [AllowAnonymous]
        [HttpGet("product/{Product_ID}")]
        public async Task<IActionResult> GetProductDetails(int productId)
        {
            // الرابط الأساسي للصور — عدله حسب مشروعك
            var baseUrl = $"{Request.Scheme}://{Request.Host}/";

            var product = await _context.Products
                .Include(p => p.ProductImages)
                .Include(p => p.Category)
                .Include(p => p.User) // الحرفي صاحب المنتج
                .Where(p => p.Product_ID == productId && p.Status != "Deleted")
                .Select(p => new
                {
                    p.Product_ID,
                    p.Name,
                    p.Price,
                    p.Quantity,
                    p.Description,
                    p.Rating_Average,
                    p.Status,
                    Artisan = new
                    {
                        p.User!.SSN,
                        p.User.Full_Name,
                        ProfileImage = p.User.Image != null
                            ? $"{baseUrl}uploads_Profile_image/{p.User.Image.TrimStart('/')}"
                            : null
                    },
                    Category = p.Category != null ? p.Category.Cat_Type : "No Category",
                    Images = p.ProductImages.Select(img => $"{baseUrl}{img.Images.TrimStart('/')}").ToList()
                })
                .FirstOrDefaultAsync();

            if (product == null)
            {
                return NotFound(new { Message = "Product not found." });
            }

            return Ok(product);
        }


        // ✅ البحث عن المنتجات حسب الاسم
        [Authorize]

        [HttpGet("search_product")]
        public async Task<IActionResult> FilterProducts(
        [FromQuery] string? category,
        [FromQuery] int? minPrice,
        [FromQuery] int? maxPrice,
        [FromQuery] int? minRating)
        {
            // الرابط الأساسي للصور
            var baseUrl = $"{Request.Scheme}://{Request.Host}/";

            var products = _context.Products
                .Include(p => p.Category)
                .Include(p => p.ProductImages) // لجلب الصور
                .Where(p => p.Status != "Deleted");

            // الفلترة حسب الفئات والأسعار والتقييم
            if (!string.IsNullOrEmpty(category))
            {
                products = products.Where(p => p.Category.Cat_Type == category);
            }

            if (minPrice.HasValue)
            {
                products = products.Where(p => p.Price >= minPrice.Value);
            }

            if (maxPrice.HasValue)
            {
                products = products.Where(p => p.Price <= maxPrice.Value);
            }

            if (minRating.HasValue)
            {
                products = products.Where(p => p.Rating_Average >= minRating.Value);
            }

            // تحديد البيانات المراد عرضها
            var result = await products.Select(p => new
            {
                p.Product_ID,
                p.Name,
                p.Price,
                p.Quantity,
                p.Status,
                Category = p.Category != null ? p.Category.Cat_Type : "No Category",
                p.Rating_Average,
                ProductImage = p.ProductImages
                    .Select(img => $"{baseUrl}{img.Images.TrimStart('/')}")
                    .ToList()
            }).ToListAsync();

            return Ok(result);
        }

    }
}
