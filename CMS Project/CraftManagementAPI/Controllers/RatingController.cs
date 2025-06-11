using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Threading.Tasks;
using System.Linq;
using System;
using CraftManagementAPI.Data;
using CraftManagementAPI.Models;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.SignalR;
using CraftManagementAPI.Hubs;

namespace CraftManagementAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RatingController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<NotificationHub> _hubContext;
        public RatingController(ApplicationDbContext context, IHubContext<NotificationHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        // ✅ إضافة تقييم من العميل للحرفي
        [HttpPost("add_Rating/{artisanSSN}")]
        [Authorize(Roles = "Client")]
        public async Task<IActionResult> AddRating(string artisanSSN, [FromBody] AddRatingDto model)
        {
            if (model.Artisan_Rate < 1 || model.Artisan_Rate > 5)
                return BadRequest(new { Message = "Rating must be between 1 and 5." });

            // التحقق من وجود الحرفي
            var artisan = await _context.Users.FirstOrDefaultAsync(u => u.SSN == artisanSSN && u.Role == "Artisan");
            if (artisan == null)
                return NotFound(new { Message = "Artisan not found." });

            // الحصول على SSN الخاص بالعميل من الـ JWT
            var clientSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(clientSSN))
                return Unauthorized(new { Message = "Invalid client identity." });
            
            // ✅ التحقق من وجود تقييم سابق
            var existingRating = await _context.UserRates
                .FirstOrDefaultAsync(r => r.SSN_Client == clientSSN && r.SSN_Artisan == artisanSSN);

            if (existingRating != null)
            {
                return BadRequest(new
                {
                    Message = "You have already rated this artisan. You can't submit another rating."
                });
            }
            // التحقق من أن SSN يتوافق مع الاسم في جدول المستخدمين
            var client = await _context.Users.FirstOrDefaultAsync(u => u.SSN == clientSSN && u.Role == "Client");
            if (client == null)
                return Unauthorized(new { Message = "Invalid client data." });

            // إضافة التقييم
            var rating = new UserRate
            {
                SSN_Client = clientSSN,
                SSN_Artisan = artisanSSN,
                Artisan_Rate = model.Artisan_Rate,
                Comment = model.Comment,
                CreatedAt = DateTime.UtcNow
            };

            _context.UserRates.Add(rating);
            await _context.SaveChangesAsync();
            // بعد تقييم الحرفي
            var notification = new Notification
            {
                SSN = artisan.SSN,
                NotificationType = "Rating",
                Message = $"You've received a new rating from {client.Full_Name}: {model.Artisan_Rate}⭐.",
                CreatedAt = DateTime.UtcNow,
                SenderSSN = client.SSN,
                IsRead = false
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();
            Console.WriteLine($"[LOG] Notification Sent to {artisan.SSN} - Type: {notification.NotificationType}, Message: {notification.Message}");
            await _hubContext.Clients.Group(artisan.SSN).SendAsync("ReceiveNotification", new
            {
                Type = notification.NotificationType, // ✅ إرسال النوع بشكل منفصل
                Message = notification.Message
            });


            // تحديث التقييم المتوسط للحرفي
            var artisanRatings = await _context.UserRates
                .Where(r => r.SSN_Artisan == artisanSSN)
                .ToListAsync();

            artisan.Rating_Average = artisanRatings.Any() ? artisanRatings.Average(r => r.Artisan_Rate) : 0;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Rating submitted successfully.",
                ClientName = client.Full_Name,
                ArtisanName = artisan.Full_Name,
                model.Artisan_Rate,
                model.Comment
            });
        }
        [Authorize]
        [HttpGet("artisan_ratings/{artisanSSN?}")]
        public async Task<IActionResult> GetArtisanRatingsWithAverage(string? artisanSSN = null)
        {
            // ✅ استخراج بيانات المستخدم من التوكن
            var userSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

            // ✅ إذا لم يتم إدخال `artisanSSN`، والحساب المسجل هو `Artisan`، يتم استخدام `SSN` الخاص به تلقائيًا
            if (string.IsNullOrEmpty(artisanSSN))
            {
                if (userRole == "Artisan")
                {
                    artisanSSN = userSSN;
                }
                else
                {
                    return BadRequest(new { Message = "You must provide an artisan SSN." });
                }
            }

            // ✅ البحث عن الحرفي
            var artisan = await _context.Users.FirstOrDefaultAsync(u => u.SSN == artisanSSN && u.Role == "Artisan");
            if (artisan == null)
                return NotFound(new { Message = "Artisan not found." });

            var baseUrl = $"{Request.Scheme}://{Request.Host}/";

            var ratings = await _context.UserRates
                .Where(r => r.SSN_Artisan == artisanSSN)
                .Select(r => new
                {
                    ClientName = _context.Users
                        .Where(u => u.SSN == r.SSN_Client)
                        .Select(u => u.Full_Name)
                        .FirstOrDefault(),

                    ClientImage = _context.Users
                        .Where(u => u.SSN == r.SSN_Client)
                        .Select(u => u.Image != null
                            ? $"{baseUrl}uploads_Profile_image/{u.Image.TrimStart('/')}"
                            : null)
                        .FirstOrDefault(),

                    r.Artisan_Rate,
                    r.Comment,
                    r.CreatedAt
                })
                 .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();


            // ✅ حساب متوسط التقييم وعدد التقييمات
            var averageRating = await _context.UserRates
                .Where(ur => ur.SSN_Artisan == artisanSSN)
                .AverageAsync(ur => (double?)ur.Artisan_Rate) ?? 0.0;

            var totalRatings = await _context.UserRates
                .CountAsync(ur => ur.SSN_Artisan == artisanSSN);

            return Ok(new
            {
                Artisan_SSN = artisanSSN,
                Artisan_Name = artisan.Full_Name,
                AverageRating = Math.Round(averageRating, 2),
                TotalRatings = totalRatings,
                Ratings = ratings
            });
        }

    

    // ✅ نموذج بيانات التقييم
    public class AddRatingDto
        {
            [Range(1, 5)]
            public int Artisan_Rate { get; set; }
            public string? Comment { get; set; }
        }
    }
}