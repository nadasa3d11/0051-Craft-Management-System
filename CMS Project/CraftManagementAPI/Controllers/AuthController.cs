using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using CraftManagementAPI.Data;
using CraftManagementAPI.Models;
using System.Collections.Concurrent;
using FirebaseAdmin.Messaging;
using System.Security.Cryptography;
using CraftManagementAPI.Services;
using Google.Apis.Auth.OAuth2.Requests;
using FirebaseAdmin.Auth;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;


[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _config;
    private static readonly ConcurrentDictionary<string, (string otp, DateTime expiry)> _otpStorage = new();
    private static readonly Dictionary<string, (string UserSSN, DateTime Expiry)> _refreshTokens = new();
    private readonly OtpService _otpService;
    public AuthController(ApplicationDbContext context, IConfiguration config, OtpService otpService)
    {
        _context = context;
        _config = config;
        _otpService = otpService;
    }
    // ✅ تسجيل مستخدم جديد + رفع صورة البطاقة
    [HttpPost("register-with-image")]
    [AllowAnonymous]
    public async Task<IActionResult> RegisterWithImage([FromForm] RegisterRequest request, IFormFile file)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest(new { Message = "SSN image is required." });
        }

        // التحقق من نوع الصورة
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp" };
        var fileExtension = Path.GetExtension(file.FileName).ToLower();
        if (!allowedExtensions.Contains(fileExtension))
        {
            return BadRequest(new { Message = "Invalid file type. Only images are allowed." });
        }

        if (await _context.Users.AnyAsync(u => u.SSN == request.SSN))
        {
            return BadRequest(new { Message = "SSN already exists." });
        }

        if (!new[] { "Client", "Artisan", "Admin" }.Contains(request.Role))
        {
            return BadRequest(new { Message = "Invalid role. Choose from Client, Artisan, Admin." });
        }

        if (string.IsNullOrWhiteSpace(request.Full_Name) || string.IsNullOrWhiteSpace(request.Phone) ||
            string.IsNullOrWhiteSpace(request.Password) || string.IsNullOrWhiteSpace(request.Address) ||
            string.IsNullOrWhiteSpace(request.Role) || string.IsNullOrWhiteSpace(request.SSN) || string.IsNullOrWhiteSpace(request.Gender) ||
            request.Birth_Date == null)
        {
            return BadRequest(new { Message = "All fields are required." });
        }

        // حفظ صورة البطاقة
        var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads_ssn_image");
        if (!Directory.Exists(uploadsFolder))
        {
            Directory.CreateDirectory(uploadsFolder);
        }

        var uniqueFileName = $"{Guid.NewGuid()}{fileExtension}";
        var filePath = Path.Combine(uploadsFolder, uniqueFileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        var ssnImageUrl = $"{Request.Scheme}://{Request.Host}/uploads_SSN_image/{uniqueFileName}";

        var newUser = new User
        {
            SSN = request.SSN,
            Full_Name = request.Full_Name,
            Phone = request.Phone,
            Role = request.Role,
            Password = PasswordHasher.HashPassword(request.Password),
            Address = request.Address,
            Birth_Date = request.Birth_Date,
            Gender = request.Gender,
            Active = true,
            Rating_Average = 0,
            SSN_Image = ssnImageUrl
        };

        _context.Users.Add(newUser);
        await _context.SaveChangesAsync();

        return Ok(new { Message = "User registered successfully." });
    }

    // ✅ تسجيل الدخول مع Access و Refresh Tokens
    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Phone == request.Phone);

        if (user == null)
        {
            return Unauthorized(new { Message = "Your account Invalid or deleted by an administrator." });
        }

        if (!user.Active)
        {
            return Unauthorized(new { Message = "Your account deactivated by an administrator." });
        }

        bool isPasswordValid = false;

        // تحقق هل كلمة المرور مشفرة بصيغة Bcrypt
        if (user.Password.StartsWith("$2a$") || user.Password.StartsWith("$2b$") || user.Password.StartsWith("$2y$"))
        {
            // مشفرة → استخدم Bcrypt
            isPasswordValid = PasswordHasher.VerifyPassword(request.Password, user.Password);
        }
        else
        {
            // غير مشفرة → قارن نصًا مباشرًا
            isPasswordValid = request.Password == user.Password;
        }

        if (!isPasswordValid)
        {
            return Unauthorized(new { Message = "Invalid  password." });
        }

        // يمكنك تحديث كلمة المرور لتكون مشفرة هنا (اختياري)
        if (!user.Password.StartsWith("$2a$") && !user.Password.StartsWith("$2b$") && !user.Password.StartsWith("$2y$"))
        {
            user.Password = PasswordHasher.HashPassword(request.Password);
            _context.Users.Update(user);
            await _context.SaveChangesAsync();
        }

        var accessToken = GenerateJwtToken(user);
        var refreshToken = GenerateRefreshToken();

        _refreshTokens[refreshToken] = (user.SSN, DateTime.UtcNow.AddDays(7));

        var imageUrl = user.Image != null
            ? $"{Request.Scheme}://{Request.Host}/uploads_Profile_image/{user.Image}"
            : null;

        return Ok(new
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            Message = "Login successful!",
            user.Full_Name,
            user.Role,
            user.Phone,
            ImageUrl = imageUrl
        });
    }



    // ✅ توليد Access Token
    private string GenerateJwtToken(User user)
    {
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.SSN),
            new Claim("SSN", user.SSN),
            new Claim(ClaimTypes.Role, user.Role),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        int expiryMinutes = int.Parse(_config["Jwt:ExpiryMinutes"]);
        var expires = DateTime.UtcNow.AddMinutes(expiryMinutes);

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: expires,
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    // ✅ توليد Refresh Token
    private string GenerateRefreshToken()
    {
        var randomNumber = new byte[32];
        using (var rng = RandomNumberGenerator.Create())
        {
            rng.GetBytes(randomNumber);
            return Convert.ToBase64String(randomNumber);
        }
    }
    // ✅ تحديث التوكن باستخدام Refresh Token
    [HttpPost("refresh-token")]
    public IActionResult RefreshToken([FromBody] RefreshTokenRequest request)
    {
        if (!_refreshTokens.TryGetValue(request.RefreshToken, out var tokenData) || tokenData.Expiry <= DateTime.UtcNow)
        {
            return Unauthorized(new { Message = "Invalid or expired refresh token." });
        }

        // ✅ جلب المستخدم عبر SSN
        var user = _context.Users.FirstOrDefault(u => u.SSN == tokenData.UserSSN);
        if (user == null)
        {
            return Unauthorized(new { Message = "User not found." });
        }

        // ✅ توليد التوكنات الجديدة
        var newAccessToken = GenerateJwtToken(user);
        var newRefreshToken = GenerateRefreshToken();

        // ✅ تحديث قائمة التوكنات
        _refreshTokens.Remove(request.RefreshToken); // حذف التوكن القديم
        _refreshTokens.Add(newRefreshToken, (user.SSN, DateTime.UtcNow.AddDays(7)));

        return Ok(new
        {
            AccessToken = newAccessToken,
            RefreshToken = newRefreshToken
        });
    }
    // ✅ تسجيل الخروج (إلغاء التوكن)
    [Authorize]
    [HttpPost("logout")]
    public IActionResult Logout([FromBody] LogoutRequest request)
    {
        if (_refreshTokens.ContainsKey(request.RefreshToken))
        {
            _refreshTokens.Remove(request.RefreshToken); // إزالة التوكن
        }

        return Ok(new { Message = "Logged out successfully." });
    }


    // ✅ 1️⃣ نسيت كلمة المرور (إرسال OTP عبر Firebase)
    [HttpPost("forgot-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Phone == request.Phone);
        if (user == null)
            return NotFound(new { Message = "Phone number is not registered." });

        return Ok(new { Message = "Account found. Please verify your SSN to proceed with password reset." });
    }


    [HttpPost("reset-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Phone == request.Phone && u.SSN == request.SSN);

        if (user == null)
            return BadRequest(new { Message = "Invalid phone number or SSN." });

        user.Password = PasswordHasher.HashPassword(request.NewPassword);
        await _context.SaveChangesAsync();

        return Ok(new { Message = "Password has been reset successfully." });
    }
    [HttpPost("change-password")]
    [Authorize]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        var ssn = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(ssn))
            return Unauthorized(new { Message = "Invalid user identity." });

        var user = await _context.Users.FindAsync(ssn);
        if (user == null || !user.Active)
            return Unauthorized(new { Message = "User not found or inactive." });

        bool isOldPasswordValid = false;

        // تحقق هل كلمة المرور القديمة مشفرة أم لا
        if (user.Password.StartsWith("$2a$") || user.Password.StartsWith("$2b$") || user.Password.StartsWith("$2y$"))
        {
            isOldPasswordValid = PasswordHasher.VerifyPassword(request.OldPassword, user.Password);
        }
        else
        {
            isOldPasswordValid = request.OldPassword == user.Password;
        }

        if (!isOldPasswordValid)
        {
            return BadRequest(new { Message = "Old password is incorrect." });
        }

        // تحديث كلمة المرور الجديدة بعد التشفير
        user.Password = PasswordHasher.HashPassword(request.NewPassword);
        _context.Users.Update(user);
        await _context.SaveChangesAsync();

        return Ok(new { Message = "Password changed successfully." });
    }

    public static class PasswordHasher
    {
        public static string HashPassword(string password)
        {
            return BCrypt.Net.BCrypt.HashPassword(password);
        }

        public static bool VerifyPassword(string password, string hashedPassword)
        {
            return BCrypt.Net.BCrypt.Verify(password, hashedPassword);
        }
    }



    // ✅ نماذج الطلبات
    public class RegisterRequest
    {
        public string SSN { get; set; } = null!;
        public string Full_Name { get; set; } = null!;
        public string Phone { get; set; } = null!;
        public string Role { get; set; } = null!;
        public string Password { get; set; } = null!;
        public string Address { get; set; } = null!;
        public DateTime? Birth_Date { get; set; }
        public string Gender { get; set; } = null!;
       
    }

    public class LoginRequest
    {
        public string Phone { get; set; } = null!;
        public string Password { get; set; } = null!;
    }

    public class ForgotPasswordRequest
    {
        public string Phone { get; set; } = null!;
    }


    public class ResetPasswordRequest
    {
        public string Phone { get; set; }
        public string SSN { get; set; }
        public string NewPassword { get; set; }
    }
    public class RefreshTokenRequest
    {
        public string RefreshToken { get; set; } = null!;
    }
    public class LogoutRequest
    {
        public string RefreshToken { get; set; } = null!;
    }
    public class ChangePasswordRequest
    {
        public string OldPassword { get; set; } = null!;
        public string NewPassword { get; set; } = null!;
    }

}
