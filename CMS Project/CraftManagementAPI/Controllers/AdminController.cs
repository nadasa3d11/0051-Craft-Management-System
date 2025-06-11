using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CraftManagementAPI.Data;
using CraftManagementAPI.Enums;
using CraftManagementAPI.Models;

namespace CraftManagementAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin")]
    public class AdminController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public AdminController(ApplicationDbContext context)
        {
            _context = context;
        }

        // ✅ 1️⃣ جلب كل العملاء
        [HttpGet("get-all-clients")]
        public async Task<IActionResult> GetAllClients()
        {
           

            var clients = await _context.Users
                .Where(u => u.Role == "Client")
                .Select(u => new
                {
                    u.SSN,
                    u.Full_Name,
                    u.Phone,
                    u.Password,
                    u.Address,
                    u.Birth_Date,
                    u.Gender,
                    u.Active,
                    SSNImage = !string.IsNullOrEmpty(u.SSN_Image) ? $"{u.SSN_Image.TrimStart('/')}" : null
                })
                .ToListAsync();

            return Ok(clients);
        }

        // ✅ 2️⃣ تعديل بيانات العميل (ما عدا الدور)
        [HttpPut("update-client/{SSN}")]
        public async Task<IActionResult> UpdateClient(string ssn, [FromBody] UpdateClientRequest request)
        {
            var client = await _context.Users.FirstOrDefaultAsync(u => u.SSN == ssn && u.Role == "Client");
            if (client == null)
                return NotFound(new { Message = "Client not found." });

            client.Full_Name = request.Full_Name ?? client.Full_Name;
            client.Phone = request.Phone ?? client.Phone;
            client.Address = request.Address ?? client.Address;
            client.Birth_Date = request.Birth_Date ?? client.Birth_Date;
            client.Gender = request.Gender ?? client.Gender;

            await _context.SaveChangesAsync();

            return Ok(new { Message = "Client data updated successfully." });
        }

        // ✅ 3️⃣ تعطيل أو تفعيل حساب العميل
        [HttpPut("toggle-client-status/{SSN}")]
        public async Task<IActionResult> ToggleClientStatus(string ssn)
        {
            var client = await _context.Users.FirstOrDefaultAsync(u => u.SSN == ssn && u.Role == "Client");

            if (client == null)
                return NotFound(new { Message = "Client not found." });

            client.Active = !client.Active;
            await _context.SaveChangesAsync();

            var status = client.Active ? "activated" : "deactivated";
            return Ok(new { Message = $"Client account {status} successfully." });
        }

        // ✅ 4️⃣ حذف حساب العميل
        [HttpDelete("delete-client/{ssn}")]
        public async Task<IActionResult> DeleteClient(string ssn)
        {
            var client = await _context.Users
                .Include(u => u.Orders)
                .Include(u => u.Carts)
                .Include(u => u.Favourites)
                .Include(u => u.ProductRates)
                .Include(u => u.ClientRates)
                .Include(u => u.AppRatings)
                .Include(u => u.Notifications)
                .Include(u => u.Complaints)
                .FirstOrDefaultAsync(u => u.SSN == ssn && u.Role == "Client");

            if (client == null)
                return NotFound(new { Message = "Client not found." });

            // حذف الطلبات المرتبطة
            if (client.Orders?.Any() == true)
                _context.Orders.RemoveRange(client.Orders);

            // حذف السلة
            if (client.Carts?.Any() == true)
                _context.Carts.RemoveRange(client.Carts);

            // حذف التقييمات
            if (client.ProductRates?.Any() == true)
                _context.ProductRates.RemoveRange(client.ProductRates);

            if (client.ClientRates?.Any() == true)
                _context.UserRates.RemoveRange(client.ClientRates);

            // حذف المفضلات
            if (client.Favourites?.Any() == true)
                _context.Favourites.RemoveRange(client.Favourites);

            // حذف تقييمات التطبيق
            if (client.AppRatings?.Any() == true)
                _context.AppRatings.RemoveRange(client.AppRatings);

            // حذف الإشعارات
            if (client.Notifications?.Any() == true)
                _context.Notifications.RemoveRange(client.Notifications);

            // حذف الشكاوى
            if (client.Complaints?.Any() == true)
                _context.Complaints.RemoveRange(client.Complaints);

            // حذف المستخدم نفسه
            _context.Users.Remove(client);

            await _context.SaveChangesAsync();

            return Ok(new { Message = "Client and all related data deleted successfully." });
        }


        // ✅ 5️⃣ جلب كل الحرفيين
        [HttpGet("get-all-artisans")]
        public async Task<IActionResult> GetAllArtisans()
        {        
            var artisans = await _context.Users
                .Where(u => u.Role == "Artisan")
                .Select(u => new
                {
                    u.SSN,
                    u.Full_Name,
                    u.Phone,
                    u.Address,
                    u.Birth_Date,
                    u.Gender,
                    u.Active,
                    SSNImage = !string.IsNullOrEmpty(u.SSN_Image) ? $"{u.SSN_Image.TrimStart('/')}" : null
                })
                .ToListAsync();

            return Ok(artisans);
        }


        // ✅ 6️⃣ تعديل بيانات الحرفي (ما عدا الدور)
        [HttpPut("update-artisan/{SSN}")]
        public async Task<IActionResult> UpdateArtisan(string ssn, [FromBody] UpdateClientRequest request)
        {
            var artisan = await _context.Users.FirstOrDefaultAsync(u => u.SSN == ssn && u.Role == "Artisan");
            if (artisan == null)
                return NotFound(new { Message = "Artisan not found." });

            artisan.Full_Name = request.Full_Name ?? artisan.Full_Name;
            artisan.Phone = request.Phone ?? artisan.Phone;
            artisan.Address = request.Address ?? artisan.Address;
            artisan.Birth_Date = request.Birth_Date ?? artisan.Birth_Date;
            artisan.Gender = request.Gender ?? artisan.Gender;

            await _context.SaveChangesAsync();

            return Ok(new { Message = "Artisan data updated successfully." });
        }

        // ✅ 7️⃣ حذف حساب الحرفي
        [HttpDelete("delete-artisan/{ssn}")]
        public async Task<IActionResult> DeleteArtisan(string ssn)
        {
            var artisan = await _context.Users
                .Include(u => u.Products)
                    .ThenInclude(p => p.OrderItems)
                .Include(u => u.Products)
                    .ThenInclude(p => p.ProductImages)
                .Include(u => u.Products)
                    .ThenInclude(p => p.Favourites)
                .Include(u => u.Products)
                    .ThenInclude(p => p.Carts)
                .Include(u => u.ProductRates) // تقييمات منتجات الحرفي
                .Include(u => u.ArtisanRates) // التقييمات اللي اتقالت عن الحرفي
                .Include(u => u.AppRatings)   // تقييم التطبيق
                .Include(u => u.Complaints)   // الشكاوي
                .Include(u => u.Notifications)
                .FirstOrDefaultAsync(u => u.SSN == ssn && u.Role == "Artisan");

            if (artisan == null)
                return NotFound(new { Message = "Artisan not found." });

            // حذف كل شيء متعلق بالمنتجات
            foreach (var product in artisan.Products)
            {
                // حذف الطلبات (عبر OrderItems)
                var orderItems = await _context.OrderItems
                    .Where(oi => oi.Product_ID == product.Product_ID)
                    .ToListAsync();
                _context.OrderItems.RemoveRange(orderItems);

                // حذف الصور
                _context.ProductImages.RemoveRange(product.ProductImages!);

                // حذف من المفضلة
                _context.Favourites.RemoveRange(product.Favourites!);

                // حذف من السلة
                _context.Carts.RemoveRange(product.Carts!);

                // حذف التقييمات المرتبطة بالمنتج
                var productRatings = await _context.ProductRates
                    .Where(pr => pr.Product_ID == product.Product_ID)
                    .ToListAsync();
                _context.ProductRates.RemoveRange(productRatings);
            }

            // حذف المنتجات نفسها
            _context.Products.RemoveRange(artisan.Products);

            // حذف تقييمات التطبيق
            _context.AppRatings.RemoveRange(artisan.AppRatings);

            // حذف التقييمات اللي اتقالت عن الحرفي
            _context.UserRates.RemoveRange(artisan.ArtisanRates);

            // حذف الإشعارات
            _context.Notifications.RemoveRange(artisan.Notifications!);

            // حذف الشكاوي
            _context.Complaints.RemoveRange(artisan.Complaints);

            // أخيرًا حذف الحرفي
            _context.Users.Remove(artisan);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Artisan and all related data deleted successfully." });
        }


        // ✅ 8️⃣ تعطيل أو تفعيل حساب الحرفي
        [HttpPut("toggle-artisan-status/{SSN}")]
        public async Task<IActionResult> ToggleArtisanStatus(string ssn)
        {
            var artisan = await _context.Users.FirstOrDefaultAsync(u => u.SSN == ssn && u.Role == "Artisan");

            if (artisan == null)
                return NotFound(new { Message = "Artisan not found." });

            artisan.Active = !artisan.Active;
            await _context.SaveChangesAsync();

            var status = artisan.Active ? "activated" : "deactivated";
            return Ok(new { Message = $"Artisan account {status} successfully." });
        }
        [HttpGet("all-orders")]
        public async Task<IActionResult> GetAllOrders()
        {
            var orders = await _context.Orders
                .Include(o => o.User) // العميل
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
                .ThenInclude(p => p.User) // الحرفيين
                .Include(o => o.ConfirmationCode) // كود التأكيد
                .Select(o => new
                {
                    o.Order_ID,
                    o.Order_Date,
                    o.Arrived_Date,
                    Order_Status = o.Order_Status.ToString(), // ✅ النص بدل الرقم
                    Payment_Status = o.Payment_Status.ToString(), // ✅ النص بدل الرقم
                    o.Order_Price,
                    o.Receive_Address,
                    ClientName = o.User.Full_Name,
                    ClientPhone = o.User.Phone,
                    ArtisanNames = o.OrderItems.Select(oi => oi.Product.User.Full_Name).Distinct(),
                    Products = o.OrderItems.Select(oi => new
                    {
                        oi.Product_ID,
                        ProductName = oi.Product.Name,
                        oi.Quantity,
                        oi.Total_Price
                    }),
                    // ✅ عرض كود التأكيد لو الطلب في حالة Delivered
                    Conform_Code = o.Order_Status == OrderStatus.Delivered
                        ? o.ConfirmationCode != null ? o.ConfirmationCode.Code : "Not Available"
                        : null
                })
                .OrderByDescending(o => o.Order_Date)
                .ToListAsync();

            return Ok(orders);
        }


        // ✅ 📊 الـ Dashboard
        [HttpGet("dashboard")]
        public async Task<IActionResult> GetDashboard()
        {
            // جلب البيانات
            var artisansCount = await _context.Users.CountAsync(u => u.Role == "Artisan");
            var clientsCount = await _context.Users.CountAsync(u => u.Role == "Client");
            var ordersCount = await _context.Orders.CountAsync();
            var complaintsCount = await _context.Complaints.CountAsync();
            var categoriesCount = await _context.Categories.CountAsync();

            // بناء الرد النهائي
            var dashboardData = new
            {
                Artisans = new { Name = "Artisans", Count = artisansCount },
                Clients = new { Name = "Clients", Count = clientsCount },
                Orders = new { Name = "Orders", Count = ordersCount },
                Complaints = new { Name = "Complaints", Count = complaintsCount },
                Categories = new { Name = "Categories", Count = categoriesCount }
            };

            return Ok(dashboardData);
        }


        // ✅ 5️⃣ البحث عن مستخدمين عبر رقم الهاتف أو SSN
        [HttpGet("search-users")]
        public async Task<IActionResult> SearchUsers([FromQuery] string? phone, [FromQuery] string? ssn)
        {
            if (string.IsNullOrWhiteSpace(phone) && string.IsNullOrWhiteSpace(ssn))
            {
                return BadRequest(new { Message = "Please provide either a phone number or SSN to search." });
            }

            var usersQuery = _context.Users.AsQueryable();

            if (!string.IsNullOrWhiteSpace(phone))
            {
                usersQuery = usersQuery.Where(u => u.Phone.Contains(phone));
            }

            if (!string.IsNullOrWhiteSpace(ssn))
            {
                usersQuery = usersQuery.Where(u => u.SSN.Contains(ssn));
            }

            var users = await usersQuery.Select(u => new
            {
                u.SSN,
                u.Full_Name,
                u.Phone,
                u.Role,
                u.Address,
                u.Birth_Date,
                u.Gender,
                u.Active,
                SSNImage = u.SSN_Image
            }).ToListAsync();

            if (!users.Any())
            {
                return NotFound(new { Message = "No users found matching the provided criteria." });
            }

            return Ok(users);
        }
        [Authorize(Roles = "Admin")]
        [HttpPut("update-order/{orderId}")]
        public async Task<IActionResult> UpdateOrderByAdmin(int orderId, [FromBody] UpdateOrderRequest request)
        {
            var order = await _context.Orders
                .Include(o => o.User)
                .FirstOrDefaultAsync(o => o.Order_ID == orderId);

            if (order == null)
            {
                return NotFound(new { Message = "Order not found." });
            }

            // ✅ تعديل البيانات حسب الصورة
            order.Order_Date = request.Order_Date ?? order.Order_Date;
            order.Arrived_Date = request.Arrived_Date ?? order.Arrived_Date;
            // تحديث Payment_Method إذا كانت القيمة صالحة
            if (Enum.TryParse(typeof(PaymentMethod), request.Payment_Method, true, out var paymentMethod))
            {
                order.Payment_Method = (PaymentMethod)paymentMethod;
            }
            order.Receive_Address = request.Receive_Address ?? order.Receive_Address;
            order.Order_Price = request.Order_Price ?? order.Order_Price;
            // تحديث Payment_Status إذا كانت القيمة صالحة
            if (Enum.TryParse(typeof(PaymentStatus), request.Payment_Status, true, out var paymentStatus))
            {
                order.Payment_Status = (PaymentStatus)paymentStatus;
            }

            // ✅ تعديل العميل (Order From) والـ Artisan (Order To)
            if (!string.IsNullOrEmpty(request.Order_From))
            {
                var client = await _context.Users.FirstOrDefaultAsync(u => u.Full_Name == request.Order_From && u.Role == "Client");
                if (client == null) return BadRequest(new { Message = "Invalid client name." });
                order.User = client; // تعديل العميل
            }

            if (!string.IsNullOrEmpty(request.Order_To))
            {
                var artisan = await _context.Users.FirstOrDefaultAsync(u => u.Full_Name == request.Order_To && u.Role == "Artisan");
                if (artisan == null) return BadRequest(new { Message = "Invalid artisan name." });
                // يمكن تعديل الـ Artisan إذا كان له علاقة بالطلب
                foreach (var item in order.OrderItems)
                {
                    item.Product.User = artisan;
                }
            }

            await _context.SaveChangesAsync();

            return Ok(new { Message = "Order updated successfully by Admin." });
        }

        // ✅ حذف الطلب
        [HttpDelete("delete-order/{orderId}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> DeleteOrder(int orderId)
        {
            var order = await _context.Orders.Include(o => o.OrderItems)
                                             .FirstOrDefaultAsync(o => o.Order_ID == orderId);

            if (order == null)
            {
                return NotFound(new { Message = "Order not found." });
            }

            _context.OrderItems.RemoveRange(order.OrderItems); // حذف المنتجات المرتبطة بالطلب
            _context.Orders.Remove(order); // حذف الطلب نفسه
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Order deleted successfully." });
        }

    }

    public class UpdateClientRequest
    {
        public string? Full_Name { get; set; }
        public string? Phone { get; set; }
        public string? Address { get; set; }
        public DateTime? Birth_Date { get; set; }
        public string? Gender { get; set; }
    }
   public class UpdateOrderRequest
    {
        public DateTime? Order_Date { get; set; }
        public DateTime? Arrived_Date { get; set; }
        public string? Payment_Status { get; set; } // "Paid" أو "Not"
        public string? Order_From { get; set; } // اسم العميل
        public string? Order_To { get; set; } // اسم الحرفي
        public string? Receive_Address { get; set; }
        public decimal? Order_Price { get; set; }
        public string? Payment_Method { get; set; } // "Vodafone Cash" أو غير
    }
}
