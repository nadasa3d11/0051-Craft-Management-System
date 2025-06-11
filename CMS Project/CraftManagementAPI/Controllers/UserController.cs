using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using CraftManagementAPI.Data;
using CraftManagementAPI.Models;

namespace CraftManagementAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize] // ✅ تأكيد إن التوكن مطلوب
    public class UserController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _env;

        public UserController(ApplicationDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        // ✅ استخراج SSN من التوكن مع تسجيل اللوج
        private string? GetSSNFromToken()
        {
            var claims = User.Claims.ToList();

            if (!claims.Any())
            {
                Console.WriteLine("No claims found in the token.");
                return null;
            }

            foreach (var claim in claims)
            {
                Console.WriteLine($"Claim Type: {claim.Type}, Value: {claim.Value}");
            }

            var ssn = User.FindFirst("SSN")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(ssn))
            {
                Console.WriteLine("SSN not found in token.");
            }
            else
            {
                Console.WriteLine($"Extracted SSN: {ssn}");
            }

            return ssn;
        }

        // ✅ عرض بيانات البروفايل
        [HttpGet("my-profile")]
        public async Task<IActionResult> GetProfile()
        {
            var token = Request.Headers["Authorization"].ToString();
            Console.WriteLine($"Received Token: {token}");

            var ssn = GetSSNFromToken();
            if (string.IsNullOrEmpty(ssn))
            {
                return Unauthorized(new { Message = "Invalid or missing token." });
            }

            var user = await _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.SSN == ssn);
            if (user == null)
            {
                return NotFound(new { Message = "User not found." });
            }

            var imageUrl = string.IsNullOrEmpty(user.Image)
                ? null
                : $"{Request.Scheme}://{Request.Host}/uploads_Profile_image/{user.Image}";

            return Ok(new
            {
                user.Full_Name,
                user.Birth_Date,
                user.Phone,
                user.Gender,
                user.SSN,
                user.Address,
                Image = imageUrl
            });
        }

        // ✅ تعديل بيانات البروفايل + رفع صورة بروفايل
        [HttpPut("update-profile")]
        public async Task<IActionResult> UpdateProfile([FromForm] UpdateProfileRequest request)
        {
            var ssn = GetSSNFromToken();
            if (string.IsNullOrEmpty(ssn))
            {
                return Unauthorized(new { Message = "Invalid or missing token." });
            }

            var user = await _context.Users.FirstOrDefaultAsync(u => u.SSN == ssn);
            if (user == null)
            {
                return NotFound(new { Message = "User not found." });
            }

            // ✅ تحديث البيانات الشخصية
            user.Full_Name = request.Full_Name ?? user.Full_Name;
            user.Birth_Date = request.Birth_Date ?? user.Birth_Date;
            user.Phone = request.Phone ?? user.Phone;
            user.Gender = request.Gender ?? user.Gender;
            user.Address = request.Address ?? user.Address;
            user.Password = request.Password ?? user.Password;

            // ✅ رفع صورة البروفايل
            if (request.Image != null && request.Image.Length > 0)
            {
                try
                {
                    // ✅ السماح بامتدادات الصور الشائعة فقط
                    var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif" };
                    var fileExtension = Path.GetExtension(request.Image.FileName).ToLower();

                    if (!allowedExtensions.Contains(fileExtension))
                    {
                        return BadRequest(new { Message = "Invalid image format. Allowed formats: JPG, JPEG, PNG, GIF" });
                    }

                    // ✅ التأكد من أن `WebRootPath` ليس `null`
                    if (string.IsNullOrEmpty(_env.WebRootPath))
                    {
                        _env.WebRootPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
                    }

                    // ✅ إنشاء `wwwroot` والمجلد الفرعي إذا لم يكن موجودًا
                    var uploadsFolder = Path.Combine(_env.WebRootPath, "uploads_Profile_image");
                    if (!Directory.Exists(uploadsFolder))
                    {
                        Directory.CreateDirectory(uploadsFolder);
                    }

                    // ✅ حفظ الصورة باسم فريد
                    var fileName = $"{Guid.NewGuid()}{fileExtension}";
                    var filePath = Path.Combine(uploadsFolder, fileName);

                    using (var stream = new FileStream(filePath, FileMode.Create))
                    {
                        await request.Image.CopyToAsync(stream);
                    }

                    user.Image = fileName; // ✅ تخزين اسم الصورة في قاعدة البيانات
                }
                catch (Exception ex)
                {
                    return StatusCode(500, new { Message = "An error occurred while uploading the image.", Error = ex.Message });
                }
            }

            await _context.SaveChangesAsync();

            // ✅ إنشاء رابط الصورة
            var imageUrl = user.Image != null
                ? $"{Request.Scheme}://{Request.Host}/uploads_Profile_image/{user.Image}"
                : null;

            // ✅ إرجاع جميع بيانات المستخدم بعد التحديث
            return Ok(new
            {
                Message = "Profile updated successfully.",
                User = new
                {
                    user.SSN,
                    user.Full_Name,
                    user.Birth_Date,
                    user.Phone,
                    user.Gender,
                    user.Address,
                    user.Active,
                    user.Rating_Average,
                    ImageUrl = imageUrl
                }
            });
        }



        // ✅ موديل تعديل البروفايل
        public class UpdateProfileRequest
        {
            public string? Full_Name { get; set; }
            public DateTime? Birth_Date { get; set; }
            public string? Phone { get; set; }
            public string? Gender { get; set; }
            public string? Address { get; set; }
            public string? Password { get; set; }
            public IFormFile? Image { get; set; } // ✅ دعم رفع الصور
        }
    }
}