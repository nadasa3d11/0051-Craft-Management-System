using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using CraftManagementAPI.Data;
using CraftManagementAPI.Hubs;
using CraftManagementAPI.Models;

namespace CraftManagementAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NotificationController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<NotificationHub> _hubContext;

        public NotificationController(ApplicationDbContext context, IHubContext<NotificationHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        [Authorize(Roles = "Admin")]
        [HttpPost("send")]
        public async Task<IActionResult> SendNotification([FromBody] SendNotificationRequest request)
        {
            // التأكد من وجود المستخدم المستهدف
            var user = await _context.Users.FirstOrDefaultAsync(u => u.SSN == request.SSN);
            if (user == null)
                return NotFound(new { Message = "User not found." });

            // تسجيل الإشعار
            var notification = new Notification
            {
                SSN = request.SSN, // SSN المستخدم الذي سيستقبل الإشعار
                Message = request.Message,
                CreatedAt = DateTime.UtcNow,
                IsRead = false,
                SenderSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value // SSN الخاص بالـ Admin الذي يرسل الإشعار
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            // إرسال الإشعار الفوري عبر SignalR
            try
            {
                await _hubContext.Clients.Group(request.SSN).SendAsync("ReceiveNotification", new
                {
                    Message = request.Message,
                    NotificationType = "AdminNotification", // نوع الإشعار يمكن أن يتم تحديده حسب الحاجة
                    SenderSSN = notification.SenderSSN // إرسال SSN للـ Admin الذي أرسل الإشعار
                });

                Console.WriteLine($"✅ Notification sent to {request.SSN}: {request.Message}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to send notification to {request.SSN}: {ex.Message}");
            }

            return Ok(new { Message = "Notification sent successfully." });
        }

        //عرض اشعاارات لكل مستخدمين
        [HttpGet("my-notifications")]
        [Authorize]
        public async Task<IActionResult> GetUserNotifications()
        {
            var userSSN = User.Claims.FirstOrDefault(c => c.Type == "SSN")?.Value;
            if (userSSN == null) return Unauthorized(new { Message = "Invalid user." });

            var baseUrl = $"{Request.Scheme}://{Request.Host}/";

            var notifications = await _context.Notifications
                .Include(n => n.SenderUser) // 🆕 بدل User
                .Where(n => n.SSN == userSSN)
                .OrderByDescending(n => n.CreatedAt)
                .Select(n => new
                {
                    n.NotificationId,
                    SenderName = n.SenderUser != null ? n.SenderUser.Full_Name : "System",
                    ProfileImage = n.SenderUser != null && n.SenderUser.Image != null
                        ? $"{baseUrl}uploads_Profile_image/{n.SenderUser.Image.TrimStart('/')}"
                        : null,
                    n.Message,
                    n.IsRead,
                    n.CreatedAt,
                    n.NotificationType
                })
                .ToListAsync();

            return Ok(notifications);
        }



        // ✅ تعيين الإشعار كمقروء
        [Authorize]
        [HttpPut("mark-as-read/{notificationId}")]
        public async Task<IActionResult> MarkNotificationAsRead(int notificationId)
        {
            var userSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userSSN))
                return Unauthorized(new { Message = "Invalid token." });

            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.NotificationId == notificationId && n.SSN == userSSN);

            if (notification == null)
                return NotFound(new { Message = "Notification not found." });

            notification.IsRead = true;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Notification marked as read." });
        }

        // ✅ حذف إشعار
        [Authorize]
        [HttpDelete("delete/{notificationId}")]
        public async Task<IActionResult> DeleteNotification(int notificationId)
        {
            var userSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userSSN))
                return Unauthorized(new { Message = "Invalid token." });

            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.NotificationId == notificationId && n.SSN == userSSN);

            if (notification == null)
                return NotFound(new { Message = "Notification not found." });

            _context.Notifications.Remove(notification);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Notification deleted successfully." });
        }
    }

    // ✅ طلب الإرسال (Request DTO)
    public class SendNotificationRequest
    {
        public string SSN { get; set; } = null!;
        public string Message { get; set; } = null!;
    }
}
