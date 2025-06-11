using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CraftManagementAPI.Data;
using CraftManagementAPI.Models;
using CraftManagementAPI.Enums;
using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;
using CraftManagementAPI.Hubs;

namespace CraftManagementAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ComplaintController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<NotificationHub> _hubContext;

        public ComplaintController(ApplicationDbContext context, IHubContext<NotificationHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        // ✅ إضافة شكوى (Client وArtisan)
        [Authorize(Roles = "Client,Artisan")]
        [HttpPost("create-complaint")]
        public async Task<IActionResult> CreateComplaint([FromBody] ComplaintRequest request)
        {
            var userSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userSSN))
            {
                return Unauthorized(new { Message = "Invalid user token." });
            }

            var complaint = new Complaint
            {
                SSN = userSSN,
                Problem = request.Problem,
                PhoneNumber = request.PhoneNumber,
                Complainer = request.Complainer,
                ProblemDate = DateTime.UtcNow,
                ProblemStatus = ComplaintStatus.New
            };

            _context.Complaints.Add(complaint);
            await _context.SaveChangesAsync();

            var admins = await _context.Users.Where(u => u.Role == "Admin").Select(u => u.SSN).ToListAsync();

            foreach (var adminSSN in admins)
            {
                var notification = new Notification
                {
                    SSN = adminSSN,
                    Message = $"⚠️ New complaint received from: {complaint.Complainer}.",
                    CreatedAt = DateTime.UtcNow,
                    IsRead = false,
                    SenderSSN = userSSN,
                    NotificationType = "NewComplaint"
                };

                _context.Notifications.Add(notification);
               
            }

            await _context.SaveChangesAsync();
            // ✅ إرسال الإشعارات للإداريين عبر `SignalR`
            foreach (var adminSSN in admins)
            {
                try
                {
                    await _hubContext.Clients.Group(adminSSN).SendAsync("ReceiveNotification", new
                    {
                        Message = $"⚠️ New complaint received from: {complaint.Complainer}.",
                        NotificationType = "NewComplaint",
                        ComplaintID = complaint.ComplaintId
                    });

                    Console.WriteLine($"✅ New complaint notification sent to Admin {adminSSN} for Complaint {complaint.ComplaintId}.");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"❌ Failed to send complaint notification to Admin {adminSSN}: {ex.Message}");
                }
            }
            return Ok(new { Message = "Complaint submitted successfully." });
        }

        // ✅ جلب جميع الشكاوى (Admin)
        [Authorize(Roles = "Admin")]
        [HttpGet("all-complaints")]
        public async Task<IActionResult> GetAllComplaints()
        {
            var complaints = await _context.Complaints
                .Include(c => c.User)
                .OrderByDescending(c => c.ProblemDate)
                .Select(c => new
                {
                    c.ComplaintId,
                    c.Problem,
                    c.PhoneNumber,
                    c.Complainer,
                    c.ProblemDate,
                    c.Response,
                    c.ResponseDate,
                    c.ProblemStatus,
                    c.SSN
                })
                .ToListAsync();

            return Ok(complaints);
        }

        // ✅ تحديث حالة الشكوى (Admin)
        [Authorize(Roles = "Admin")]
        [HttpPut("update-status/{id}")]
        public async Task<IActionResult> UpdateComplaintStatus(int id, [FromBody] UpdateComplaintStatusRequest request)
        {
            if (!Enum.TryParse(typeof(ComplaintStatus), request.NewStatus, true, out var status))
            {
                return BadRequest(new { Message = "Invalid status. Valid statuses: New, UnderReview, Resolved." });
            }

            var complaint = await _context.Complaints.FindAsync(id);
            if (complaint == null)
            {
                return NotFound(new { Message = "Complaint not found." });
            }

            complaint.ProblemStatus = (ComplaintStatus)status;
            await _context.SaveChangesAsync();

            await _hubContext.Clients.Group(complaint.SSN).SendAsync("ReceiveNotification", $"تم تحديث حالة الشكوى إلى: {request.NewStatus}");

            return Ok(new { Message = $"Complaint status updated to {request.NewStatus}." });
        }

        [Authorize(Roles = "Admin")]
        [HttpPost("respond/{id}")]
        public async Task<IActionResult> RespondToComplaint(int id, [FromBody] RespondToComplaintRequest request)
        {
            var userSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userSSN))
            {
                return Unauthorized(new { Message = "Invalid user token." });
            }
            var complaint = await _context.Complaints.Include(c => c.User).FirstOrDefaultAsync(c => c.ComplaintId == id);
            if (complaint == null)
            {
                return NotFound(new { Message = "Complaint not found." });
            }

            if (complaint.ProblemStatus != ComplaintStatus.New)
            {
                return BadRequest(new { Message = "Only 'New' complaints can be responded to." });
            }

            // تحديث بيانات الشكوى
            complaint.Response = request.Response;
            complaint.ResponseDate = DateTime.UtcNow;
            complaint.ProblemStatus = ComplaintStatus.Resolved;
            var admins = await _context.Users.Where(u => u.Role == "Admin").Select(u => u.SSN).ToListAsync();
            // إنشاء إشعار جديد للمستخدم
            var notification = new Notification
            {
                SSN = complaint.SSN, // صاحب الشكوى
                Message = $"تم الرد على شكواك بخصوص: '{complaint.Problem}'. الرد: {request.Response}",
                CreatedAt = DateTime.UtcNow,
                IsRead = false,
                SenderSSN = userSSN,
                NotificationType = "ComplaintResponse"
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();
            // ✅ إرسال الإشعار إلى صاحب الشكوى عبر `SignalR`
            try
            {
                await _hubContext.Clients.Group(complaint.SSN).SendAsync("ReceiveNotification", new
                {
                    Message = $"🔔 Your complaint regarding '{complaint.Problem}' has been responded to:{request.Response}.",
                    NotificationType = "ComplaintResponse",
                    ComplaintID = complaint.ComplaintId
                });

                Console.WriteLine($"✅ Complaint response notification sent to {complaint.SSN} for Complaint {complaint.ComplaintId}.");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to send complaint response notification to {complaint.SSN}: {ex.Message}");
            }

            return Ok(new { Message = "Response submitted and user notified successfully." });
        }

        [Authorize(Roles = "Admin")]
        [HttpGet("filter")]
        public async Task<IActionResult> FilterComplaints([FromQuery] string status)
        {
            if (!Enum.TryParse<ComplaintStatus>(status, true, out var parsedStatus))
            {
                return BadRequest(new { Message = "Invalid status filter." });
            }

            var complaints = await _context.Complaints
                .Where(c => c.ProblemStatus == parsedStatus)
                .Select(c => new
                {
                    c.ComplaintId,
                    c.Complainer,
                    c.Problem,
                    Status = c.ProblemStatus.ToString(),
                    c.ProblemDate
                })
                .ToListAsync();

            return Ok(complaints);
        }
        [Authorize(Roles = "Admin")]
        [HttpGet("details/{complaintId}")]
        public async Task<IActionResult> GetComplaintDetails(int complaintId)
        {
            var complaint = await _context.Complaints
                .Include(c => c.User) // لو عايز تجيب بيانات المستخدم كمان
                .FirstOrDefaultAsync(c => c.ComplaintId == complaintId);

            if (complaint == null)
                return NotFound(new { Message = "Complaint not found." });

            return Ok(new
            {
                complaint.ComplaintId,
                complaint.Complainer,
                complaint.Problem,
                complaint.Response,
                Status = complaint.ProblemStatus.ToString(),
                complaint.ProblemDate,
                RespondedAt = complaint.ResponseDate
            });
        }

        [Authorize]
        [HttpGet("my-complaints")]
        public async Task<IActionResult> GetUserComplaints()
        {
            var userSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userSSN))
                return Unauthorized(new { Message = "Invalid user identity." });

            // ✅ جلب الشكاوى الخاصة بالمستخدم
            var complaints = await _context.Complaints
                .Where(c => c.SSN == userSSN)
                .OrderByDescending(c => c.ProblemDate)
                .Select(c => new
                {
                    c.ComplaintId,
                    c.Problem,
                    c.ProblemDate,
                    Status = c.ProblemStatus.ToString(),
                    Response = string.IsNullOrEmpty(c.Response) ? "No response yet" : c.Response,
                    ResponseDate = c.ResponseDate
                })
                .ToListAsync();

            if (!complaints.Any())
                return NotFound(new { Message = "No complaints found for this user." });

            return Ok(complaints);
        }

    }
    // ✅ لإرسال شكوى جديدة
    public class ComplaintRequest
    {
        public string Problem { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string Complainer { get; set; } = string.Empty;
    }

    // ✅ لتحديث حالة الشكوى
    public class UpdateComplaintStatusRequest
    {
        public string NewStatus { get; set; } = string.Empty; // New, UnderReview, Resolved
    }

    // ✅ للرد على الشكوى
    public class RespondToComplaintRequest
    {
        public string Response { get; set; } = string.Empty;
    }

    // ✅ لعرض بيانات الشكوى في الـ Responses
    public class ComplaintResponse
    {
        public int ComplaintId { get; set; }
        public string Problem { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string Complainer { get; set; } = string.Empty;
        public string Response { get; set; } = string.Empty;
        public DateTime ProblemDate { get; set; }
        public DateTime? ResponseDate { get; set; }
        public string ProblemStatus { get; set; } = string.Empty;
        public string SSN { get; set; } = string.Empty; // صاحب الشكوى
    }
}
