using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CraftManagementAPI.Data;
using CraftManagementAPI.Models;
using Microsoft.AspNetCore.Authorization;
using System.ComponentModel.DataAnnotations;

namespace CraftManagementAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CategoryController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public CategoryController(ApplicationDbContext context)
        {
            _context = context;
        }

        // ✅ جلب كل الفئات مع عدد المنتجات
        [Authorize]
        [HttpGet("all-with-products")]
        public async Task<IActionResult> GetAllCategoriesWithProducts()
        {
            var categories = await _context.Categories
                .Select(c => new
                {
                    c.Cat_ID,
                    c.Cat_Type,
                    ProductCount = _context.Products.Count(p => p.Cat_ID == c.Cat_ID),
                    FirstProductImage = _context.Products
                        .Where(p => p.Cat_ID == c.Cat_ID)
                        .SelectMany(p => p.ProductImages)
                        .Select(img => $"{Request.Scheme}://{Request.Host}/{img.Images.TrimStart('/')}") // ✅ عرض URL الصورة
                        .FirstOrDefault() // ✅ أول صورة لأول منتج داخل الكاتجوري
                })
                .ToListAsync();

            return Ok(categories);
        }
        // ✅ جلب الفئة مع المنتجات المرتبطة بها بالتفاصيل
        [Authorize]
        [HttpGet("products/{catType}")]
        public async Task<IActionResult> GetCategoryWithProducts(string catType)
        {
            var baseUrl = $"{Request.Scheme}://{Request.Host}/";

            var category = await _context.Categories
                .Where(c => c.Cat_Type.ToLower() == catType.ToLower())
                .Select(c => new
                {
                    c.Cat_ID,
                    c.Cat_Type,
                    Products = _context.Products
                        .Where(p => p.Cat_ID == c.Cat_ID)
                        .Select(p => new
                        {
                            ProductID = p.Product_ID,
                            ProductName = p.Name,
                            p.Price,
                            p.Quantity,
                            p.Status,
                            p.Description,
                            p.Rating_Average,
                            Images = p.ProductImages!
                                .Select(img => $"{baseUrl}{img.Images.TrimStart('/')}")
                                .ToList(),

                            // ✅ بيانات الحرفي صاحب المنتج
                            Artisan = new
                            {
                                SSN = p.User!.SSN,
                                FullName = p.User.Full_Name,
                                ProfileImage = string.IsNullOrEmpty(p.User.Image)
                                    ? null
                                    : $"{baseUrl}uploads_Profile_image/{p.User.Image}"
                            }
                        })
                        .ToList()
                })
                .FirstOrDefaultAsync();

            if (category == null)
                return NotFound(new { message = "Category not found." });

            return Ok(category);
        }




        // ✅ إضافة فئة جديدة - Admin فقط
        [HttpPost("add")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> AddCategory([FromBody] AddCategoryRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Cat_Type))
                return BadRequest(new { message = "Category type is required." });

            // التحقق من وجود الفئة مسبقًا (غير مسموح بالتكرار)
            bool categoryExists = await _context.Categories
                .AnyAsync(c => c.Cat_Type.ToLower() == request.Cat_Type.ToLower());

            if (categoryExists)
                return BadRequest(new { message = "Category already exists." });

            // إضافة الفئة الجديدة
            var newCategory = new Category
            {
                Cat_Type = request.Cat_Type
            };

            _context.Categories.Add(newCategory);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Category added successfully.",
                newCategory.Cat_Type
            });
        }
        // ✅ تعديل فئة - Admin فقط
        [HttpPut("update/{catType}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateCategory(string catType, [FromBody] AddCategoryRequest updatedCategory)
        {
            if (string.IsNullOrWhiteSpace(updatedCategory.Cat_Type))
                return BadRequest(new { message = "New category type is required." });

            // البحث عن الفئة المطلوب تعديلها
            var existingCategory = await _context.Categories
                .FirstOrDefaultAsync(c => c.Cat_Type.ToLower() == catType.ToLower());

            if (existingCategory == null)
                return NotFound(new { message = "Category not found." });

            // التحقق من وجود فئة بنفس الاسم (غير الفئة الحالية)
            bool categoryExists = await _context.Categories
                .AnyAsync(c => c.Cat_Type.ToLower() == updatedCategory.Cat_Type.ToLower() && c.Cat_ID != existingCategory.Cat_ID);

            if (categoryExists)
                return BadRequest(new { message = "Another category with the same type already exists." });

            // تعديل الفئة
            existingCategory.Cat_Type = updatedCategory.Cat_Type;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Category updated successfully.",
                OldCategory = catType,
                UpdatedCategory = existingCategory.Cat_Type
            });
        }


        // ✅ حذف فئة - Admin فقط
        [HttpDelete("delete/{Cat_Type}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> DeleteCategory(string catType)
        {
            var category = await _context.Categories
                .FirstOrDefaultAsync(c => c.Cat_Type.ToLower() == catType.ToLower());

            if (category == null)
                return NotFound(new { message = "Category not found." });

            _context.Categories.Remove(category);
            await _context.SaveChangesAsync();

            return Ok(new { message = $"Category '{catType}' deleted successfully." });
        }
    }
    public class AddCategoryRequest
    {
        [Required(ErrorMessage = "Category type is required.")]
        [MaxLength(30, ErrorMessage = "Category type must be 30 characters or fewer.")]
        public string Cat_Type { get; set; } = null!;
    }


}
