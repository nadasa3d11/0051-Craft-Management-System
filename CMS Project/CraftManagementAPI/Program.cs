using CraftManagementAPI.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using CraftManagementAPI.Hubs;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.OpenApi.Models;
using CraftManagementAPI.Services;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.FileProviders;
    using Microsoft.AspNetCore.Builder;

var builder = WebApplication.CreateBuilder(args);

// ✅ ربط SQL Server بقاعدة البيانات (Production or Development)
var environment = builder.Environment.EnvironmentName;
var connectionString = environment == "Production"
    ? builder.Configuration.GetConnectionString("DefaultConnection")
    : builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

// ✅ إضافة JWT Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))
        };

        // دعم SignalR للتعامل مع JWT
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;

                if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("Hubs/NotificationsHub"))
                {
                    context.Token = accessToken;
                }
                return Task.CompletedTask;
            }
        };
    });

// ✅ إضافة Swagger مع JWT
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter 'Bearer' [space] and then your valid token.",
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        policy => policy.AllowAnyOrigin()
                        .AllowAnyHeader()
                        .AllowAnyMethod());
});
builder.Services.AddSingleton<TokenStorage>();
builder.Services.AddScoped<PayPalService>();
builder.Services.AddScoped<PaymobService>();
builder.Services.AddSingleton<SmsSender>();        // لو SmsSender مفيهوش state و stateless
builder.Services.AddSingleton<OtpService>();       // نفس الشيء
builder.Services.AddHttpClient();

// ✅ إضافة Firebase Admin SDK
FirebaseApp.Create(new AppOptions
{
    Credential = GoogleCredential.FromFile("config/phone-56fe5-firebase-adminsdk-fbsvc-00664e4f0c.json")
});
// إضافة خدمات SignalR
builder.Services.AddSignalR();


// ✅ إضافة Authorization
builder.Services.AddAuthorization();

// ✅ إضافة Controllers
builder.Services.AddControllers().AddJsonOptions(options =>
{
    options.JsonSerializerOptions.PropertyNamingPolicy = null;
});


// ✅ إضافة Swagger (يعمل في كل البيئات)
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// ✅ تفعيل Swagger في Production + Development
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Craft_ManagementAPI v2");
    c.RoutePrefix = "swagger";
});

// ✅ التعامل مع الأخطاء (بدون تفاصيل في Production)
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseCors("AllowAll");
app.UseStaticFiles();
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(
        Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads_Profile_image")),
    RequestPath = "/uploads_Profile_image"
});

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(
        Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads_SSN_image")),
    RequestPath = "/uploads_SSN_image"
});

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(
        Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads_Products")),
    RequestPath = "/uploads_Products"
});


app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
// تكوين مسار الـ Hub
app.MapHub<NotificationHub>("/notificationHub");
app.MapHub<NotificationHub>("/notificationHub").RequireAuthorization();
app.MapControllers();
app.Run();
