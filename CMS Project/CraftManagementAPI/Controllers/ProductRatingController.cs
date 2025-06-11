using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using CraftManagementAPI.Data;
using CraftManagementAPI.Models;
using System.Threading.Tasks;
using System.Linq;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.SignalR;
using CraftManagementAPI.Hubs;

namespace CraftManagementAPI.Controllers
{
    
    [Route("api/[controller]")]
    [ApiController]
    public class ProductRatingController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<NotificationHub> _hubContext;
        public ProductRatingController(ApplicationDbContext context , IHubContext<NotificationHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        // ✅ إضافة تقييم لمنتج
        [Authorize(Roles = "Client")]
        [HttpPost("rate/{productId}")]
        public async Task<IActionResult> RateProduct(int productId, [FromBody] ProductRateDto ratingDto)
        {
            if (ratingDto.Product_Rate < 1 || ratingDto.Product_Rate > 5)
                return BadRequest(new { Message = "التقييم يجب أن يكون بين 1 و 5" });

            // التحقق من وجود المنتج
            var product = await _context.Products
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.Product_ID == productId);

            if (product == null)
                return NotFound(new { Message = "product not vaild" });

            // الحصول على SSN الخاص بالعميل
            var clientSSN = GetCurrentUserSSN();
            var client = await _context.Users.FirstOrDefaultAsync(u => u.SSN == clientSSN && u.Role == "Client");

            if (client == null)
                return Unauthorized(new { Message = "Customer data is incorrect" });

            // التأكد من أن العميل لم يقم بتقييم المنتج مسبقًا
            var existingRating = await _context.ProductRates
                .FirstOrDefaultAsync(r => r.Product_ID == productId && r.SSN_Client == clientSSN);

            if (existingRating != null)
                return BadRequest(new { Message = "You have already rated this product." });

            // إضافة التقييم
            var newRating = new ProductRate
            {
                Product_ID = productId,
                SSN_Client = clientSSN,
                Product_Rate = ratingDto.Product_Rate,
                Comment = ratingDto.Comment,
                CreatedAt = DateTime.UtcNow
            };

            _context.ProductRates.Add(newRating);
            await _context.SaveChangesAsync();

            // إشعار للحرفي
            var notification = new Notification
            {
                SSN = product.User_SSN!,
                Message = $"🌟 حصل منتجك '{product.Name}' على تقييم ⭐ {ratingDto.Product_Rate}.",
                CreatedAt = DateTime.UtcNow,
                IsRead = false,
                SenderSSN = client.SSN,
                NotificationType = "ProductRating"
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();
            await _hubContext.Clients.Group(product.User_SSN!)
           .SendAsync("ReceiveNotification", new
            {
               Type = notification.NotificationType,  // ✅ إرسال نوع الإشعار
               Message = notification.Message,
               CreatedAt = notification.CreatedAt
               });
            Console.WriteLine($"🔔 Notification Sent: {notification.Message} at {notification.CreatedAt}");

            // تحديث متوسط التقييم للمنتج
            var averageRating = await _context.ProductRates
                .Where(r => r.Product_ID == productId)
                .AverageAsync(r => r.Product_Rate);

            product.Rating_Average = averageRating;
            await _context.SaveChangesAsync();


            return Ok(new
            {
                Message = "تم إضافة التقييم بنجاح",
                ClientName = client.Full_Name,
                ProductName = product.Name,
                ratingDto.Product_Rate,
                ratingDto.Comment
            });
           
        }

        // ✅ عرض تقييمات المنتج
        [Authorize]
        [HttpGet("Rating_product/{productId}")]
        public async Task<IActionResult> GetProductReviews(int productId)
        {
            var product = await _context.Products.FirstOrDefaultAsync(p => p.Product_ID == productId);
            if (product == null)
                return NotFound(new { Message = "المنتج غير موجود" });

            var baseUrl = $"{Request.Scheme}://{Request.Host}/";

            var reviews = await _context.ProductRates
                .Include(r => r.Client)
                .Where(r => r.Product_ID == productId)
                .Select(r => new
                {
                    ClientName = r.Client.Full_Name,
                    ClientImage = r.Client.Image != null
                        ? $"{baseUrl}uploads_Profile_image/{r.Client.Image.TrimStart('/')}"
                        : null,
                    r.Product_Rate,
                    r.Comment,
                    r.CreatedAt
                })
                 .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return Ok(new
            {
                ProductName = product.Name,
                Reviews = reviews
            });
        }

        // ✅ استخراج SSN الخاص بالعميل من JWT
        private string GetCurrentUserSSN()
        {
            return User.FindFirst(ClaimTypes.NameIdentifier)?.Value!;
        }
    }

    // ✅ نموذج التقييم
    public class ProductRateDto
    {
        [Required]
        [Range(1, 5, ErrorMessage = "يجب أن يكون التقييم بين 1 و 5")]
        public int Product_Rate { get; set; }

        public string? Comment { get; set; }
    }
}
