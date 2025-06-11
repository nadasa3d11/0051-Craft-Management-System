using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using CraftManagementAPI.Data;
using CraftManagementAPI.Models;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.SignalR;
using CraftManagementAPI.Hubs;

namespace CraftManagementAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AppRatingController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<NotificationHub> _hubContext;
        public AppRatingController(ApplicationDbContext context, IHubContext<NotificationHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        // ✅ إضافة تقييم للتطبيق
        [HttpPost("rate-app")]
        [Authorize]
        public async Task<IActionResult> RateApp([FromBody] AppRatingDto ratingDto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(ModelState);

                var ssn = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(ssn))
                    return Unauthorized(new { Message = "Invalid token." });

                var user = await _context.Users
                    .Where(u => u.SSN == ssn)
                    .Select(u => new { u.SSN, u.Full_Name })
                    .FirstOrDefaultAsync();

                if (user == null)
                    return NotFound(new { Message = "User not found." });

                var appRating = new AppRating
                {
                    SSN = user.SSN,
                    Rating = ratingDto.Rating,
                    Comment = ratingDto.Comment,
                    CreatedAt = DateTime.UtcNow
                };

                _context.AppRatings.Add(appRating);
                await _context.SaveChangesAsync();

                // إشعار لكل الأدمن
                var admins = await _context.Users.Where(u => u.Role == "Admin").ToListAsync();
                foreach (var admin in admins)
                {
                    var notification = new Notification
                    {
                        SSN = admin.SSN,
                        Message = $"🌟 New app rating from {user.Full_Name}: {ratingDto.Rating}⭐.",
                        CreatedAt = DateTime.UtcNow,
                        IsRead = false,
                        SenderSSN = ssn,
                        NotificationType = "AppRating"
                    };

                    _context.Notifications.Add(notification);
              
                }

                await _context.SaveChangesAsync();
                // ✅ إرسال الإشعارات الفورية لكل الأدمن عبر `SignalR`
                foreach (var admin in admins)
                {
                    try
                    {
                        await _hubContext.Clients.Group(admin.SSN).SendAsync("ReceiveNotification", new
                        {
                            Message = $"🌟 New app rating from {user.Full_Name}: {ratingDto.Rating}⭐.",
                            NotificationType = "AppRating"
                            
                        });

                        Console.WriteLine($"✅ App rating notification sent to Admin {admin.Full_Name}.");
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"❌ Failed to send app rating notification to Admin {admin.Full_Name}: {ex.Message}");
                    }
                }

                return Ok(new
                {
                    Message = "Thanks for your feedback!",
                    RatedBy = user.Full_Name,
                    appRating.Rating,
                    appRating.Comment
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { Message = "An error occurred while submitting the rating.", Error = ex.Message });
            }
        }

        [HttpGet("app-ratings")]
        [Authorize]
        public async Task<IActionResult> GetAppRatings()
        {
            var baseUrl = $"{Request.Scheme}://{Request.Host}/";

            var ratings = await _context.AppRatings
                .Include(ar => ar.User)
                .Select(ar => new
                {
                    RatedBy = ar.User.Full_Name,
                    ProfileImage = ar.User.Image != null
                        ? $"{baseUrl}uploads_Profile_image/{ar.User.Image.TrimStart('/')}"
                        : null,
                    ar.Rating,
                    ar.Comment,
                    ar.CreatedAt
                })
                .OrderByDescending(ar => ar.CreatedAt)
                .ToListAsync();


            // ✅ حساب متوسط التقييم وعدد التقييمات
            var averageRating = await _context.AppRatings.AverageAsync(ar => ar.Rating);
            var totalRatings = await _context.AppRatings.CountAsync();

            return Ok(new
            {
                AverageRating = averageRating,
                TotalRatings = totalRatings,
                Ratings = ratings // ✅ دمج التقييمات مع البيانات الإحصائية
            });
        }

    }

    // DTO
    public class AppRatingDto
    {
        [Range(1, 5, ErrorMessage = "Rating must be between 1 and 5.")]
        public int Rating { get; set; }

        [MaxLength(300)]
        public string? Comment { get; set; }
    }
}
