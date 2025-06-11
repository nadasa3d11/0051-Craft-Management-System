using CraftManagementAPI.Data;
using CraftManagementAPI.Hubs;
using CraftManagementAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using CraftManagementAPI.Hubs;

namespace CraftManagementAPI.Controllers
{
   
    [ApiController]
    [Route("api/[controller]")]
    public class ProductController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly IWebHostEnvironment _env;

        public ProductController(ApplicationDbContext context, IWebHostEnvironment env, IHubContext<NotificationHub> hubContext)
        {
            _context = context;
            _env = env;
            _hubContext = hubContext;
        }

        [HttpPost("add")]
        [Authorize(Roles = "Artisan")]
        public async Task<IActionResult> AddProduct([FromForm] ProductDto productDto, [FromForm] List<IFormFile>? Images)
        {
            // التحقق من صحة البيانات
            if (productDto.Price < 0 || productDto.Quantity <= 0)
                return BadRequest(new { Message = "السعر يجب أن يكون >= 0 والكمية > 0" });

            if (string.IsNullOrWhiteSpace(productDto.Name) || productDto.Name.Length > 100)
                return BadRequest(new { Message = "اسم المنتج مطلوب ويجب ألا يزيد عن 100 حرف" });

            if (string.IsNullOrWhiteSpace(productDto.Cat_Type))
                return BadRequest(new { Message = "نوع الفئة مطلوب." });

            // الحصول على SSN الخاص بالحرفي
            var artisanSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (artisanSSN == null)
                return Unauthorized(new { Message = "لم يتم العثور على المستخدم" });

            // جلب الحرفي (لإظهار اسمه في الإشعارات)
            var artisan = await _context.Users.FirstOrDefaultAsync(u => u.SSN == artisanSSN);
            if (artisan == null)
                return NotFound(new { Message = "الحرفي غير موجود." });

            // البحث عن الفئة عبر Cat_Type
            var category = await _context.Categories.FirstOrDefaultAsync(c => c.Cat_Type.ToLower() == productDto.Cat_Type.ToLower());
            if (category == null)
                return NotFound(new { Message = "الفئة غير موجودة." });

            // إنشاء المنتج
            var product = new Product
            {
                Name = productDto.Name,
                Price = productDto.Price,
                Quantity = productDto.Quantity,
                Description = productDto.Description,
                Cat_ID = category.Cat_ID, // ✅ الربط عبر Cat_ID بناءً على Cat_Type
                Add_Date = DateTime.Now,
                Status = "Available",
                User_SSN = artisanSSN
            };

            _context.Products.Add(product);
            await _context.SaveChangesAsync();

            // ✅ إضافة الصور (إن وجدت)
            if (Images != null && Images.Count > 0)
            {
                var uploadPath = Path.Combine(_env.WebRootPath, "uploads_Products");
                if (!Directory.Exists(uploadPath))
                    Directory.CreateDirectory(uploadPath);

                foreach (var image in Images)
                {
                    var fileName = $"{Guid.NewGuid()}_{image.FileName}";
                    var filePath = Path.Combine(uploadPath, fileName);

                    using (var stream = new FileStream(filePath, FileMode.Create))
                    {
                        await image.CopyToAsync(stream);
                    }

                    var productImage = new ProductImage
                    {
                        Images = $"uploads_Products/{fileName}",
                        Product_ID = product.Product_ID
                    };

                    _context.ProductImages.Add(productImage);
                }
            }

            // ✅ إشعار الإدمن باسم الحرفي وليس الـ SSN
            var admins = await _context.Users.Where(u => u.Role == "Admin").ToListAsync();
            foreach (var admin in admins)
            {
                var notification = new Notification
                {
                    SSN = admin.SSN,
                    Message = $"📢 New product '{product.Name}' added by artisan: {artisan.Full_Name}.",
                    CreatedAt = DateTime.UtcNow,
                    IsRead = false,
                    SenderSSN = artisan.SSN,
                    NotificationType = "NewProduct"
                };

                _context.Notifications.Add(notification);
                await _hubContext.Clients.Group(admin.SSN).SendAsync("ReceiveNotification", notification.Message);
                Console.WriteLine($"✅ Notification sent to Admin {admin.Full_Name}: {notification.Message}");
            }

            await _context.SaveChangesAsync();
            await _hubContext.Clients.Group("Admin").SendAsync("ReceiveNotification", "A new product has been added by an artisan!");
            Console.WriteLine("✅ General notification sent to Admin group.");
            return Ok(new { Message = "تم إضافة المنتج بنجاح", Product_ID = product.Product_ID });
        }
        [Authorize(Roles = "Artisan")]
        [HttpDelete("delete-my-product/{productId}")]
        public async Task<IActionResult> DeleteProductByArtisan(int productId)
        {
            var artisanSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(artisanSSN))
                return Unauthorized(new { Message = "Invalid artisan identity." });

            var product = await _context.Products
                .FirstOrDefaultAsync(p => p.Product_ID == productId && p.User_SSN == artisanSSN);

            if (product == null)
                return NotFound(new { Message = "Product not found or not owned by you." });

            // ❌ التحقق من وجود أوردرات مرتبطة بالمنتج
            bool hasOrders = await _context.OrderItems.AnyAsync(o => o.Product_ID == productId);
            if (hasOrders)
            {
                return BadRequest(new
                {
                    Message = "You cannot delete this product because it is linked to an existing order."
                });
            }

            var carts = await _context.Carts.Where(c => c.Product_ID == productId).ToListAsync();
            var favourites = await _context.Favourites.Where(f => f.Product_ID == productId).ToListAsync();
            var images = await _context.ProductImages.Where(i => i.Product_ID == productId).ToListAsync();
            var ratings = await _context.ProductRates.Where(r => r.Product_ID == productId).ToListAsync();

            _context.Carts.RemoveRange(carts);
            _context.Favourites.RemoveRange(favourites);
            _context.ProductImages.RemoveRange(images);
            _context.ProductRates.RemoveRange(ratings);
            _context.Products.Remove(product);

            

            await _context.SaveChangesAsync();
            return Ok(new { Message = "Product deleted successfully." });
        }


        [Authorize(Roles = "Admin")]
        [HttpDelete("delete-product-admin/{productId}")]
        public async Task<IActionResult> DeleteProductByAdmin(int productId)
        {
            var adminSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(adminSSN))
                return Unauthorized(new { Message = "Invalid admin identity." });

            var product = await _context.Products
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.Product_ID == productId);

            if (product == null)
                return NotFound(new { Message = "Product not found." });

            // ❌ التحقق من وجود أوردرات مرتبطة
            bool hasOrders = await _context.OrderItems.AnyAsync(o => o.Product_ID == productId);
            if (hasOrders)
            {
                return BadRequest(new
                {
                    Message = "This product cannot be deleted because it is linked to existing orders."
                });
            }
            var notification = new Notification
            {
                SSN = product.User_SSN!,
                SenderSSN = adminSSN,
                NotificationType = "ProductRemoval",
                Message = $"Your product '{product.Name}' has been removed by the admin due to policy violations.",
                CreatedAt = DateTime.UtcNow,
                IsRead = false
            };
            _context.Notifications.Add(notification);

            await _context.SaveChangesAsync();

            await _hubContext.Clients.Group(product.User_SSN!).SendAsync("ReceiveNotification", new
            {
                Type = notification.NotificationType,
                Message = notification.Message,
                Sender = notification.SenderSSN
            });
            var carts = await _context.Carts.Where(c => c.Product_ID == productId).ToListAsync();
            var favourites = await _context.Favourites.Where(f => f.Product_ID == productId).ToListAsync();
            var images = await _context.ProductImages.Where(i => i.Product_ID == productId).ToListAsync();
            var ratings = await _context.ProductRates.Where(r => r.Product_ID == productId).ToListAsync();

            _context.Carts.RemoveRange(carts);
            _context.Favourites.RemoveRange(favourites);
            _context.ProductImages.RemoveRange(images);
            _context.ProductRates.RemoveRange(ratings);
            _context.Products.Remove(product);
            await _context.SaveChangesAsync();
            


            return Ok(new { Message = "Product deleted successfully." });
        }



    }
    public class ProductDto
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = null!;

        [Required]
        [Range(0, double.MaxValue, ErrorMessage = "السعر يجب أن يكون رقمًا موجبًا")]
        public decimal Price { get; set; }

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "الكمية يجب أن تكون رقمًا موجبًا")]
        public int Quantity { get; set; }

        public string? Description { get; set; }
        public string? Cat_Type { get; set; }
    }

}
