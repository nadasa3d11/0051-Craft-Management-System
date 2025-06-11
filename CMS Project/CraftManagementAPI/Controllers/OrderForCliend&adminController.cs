using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using CraftManagementAPI.Data;
using CraftManagementAPI.Models;
using CraftManagementAPI.Enums;
using Microsoft.AspNetCore.SignalR;
using CraftManagementAPI.Hubs;
using CraftManagementAPI.Services;
using static CraftManagementAPI.Controllers.CartController;
using System;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json;
using System.Net.Http.Headers;
using System.Text;

namespace CraftManagementAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OrderController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly PayPalService _payPalService;
        private readonly PaymobService _paymobService;

        public OrderController(ApplicationDbContext context, PayPalService payPalService, PaymobService paymobService, IHubContext<NotificationHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
            _payPalService = payPalService;
            _paymobService = paymobService;
        }
        [Authorize(Roles = "Client")]
        [HttpGet("order-details-Client/{orderId}")]
        public async Task<IActionResult> GetOrderDetailsForClient(int orderId)
        {
            var clientSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(clientSSN))
                return Unauthorized(new { Message = "Invalid client identity." });

            // جلب الطلب ومنتجاته والحرفيين بالإضافة إلى كود التأكيد
            var order = await _context.Orders
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
                .ThenInclude(p => p.User) // لجلب بيانات الحرفي
                .Include(o => o.ConfirmationCode) // ✅ علاقة One-to-One
                .Where(o => o.Order_ID == orderId && o.User_SSN == clientSSN)
                .FirstOrDefaultAsync();

            if (order == null)
                return NotFound(new { Message = "Order not found or you don't have permission to view its details." });

            // تجهيز بيانات الرد
            var orderDetails = new
            {
                order.Order_ID,
                Order_Status = order.Order_Status.ToString(), // ✅ نص بدل الأرقام
                Shipping_Method = order.Shipping_Method.ToString(),

                order.Order_Price,
                order.Shipping_Cost,
                order.Total_Amount,
                Products = order.OrderItems.Select(oi => new
                {
                    oi.Product.Product_ID,
                    Product_Name = oi.Product.Name,
                    Artisan_Name = oi.Product.User!.Full_Name,
                    oi.Quantity,
                    oi.Total_Price
                }).ToList(),
                // ✅ عرض Conform Code لو الحالة  Shipped
                Conform_Code = order.Order_Status == OrderStatus.Shipped
                    ? order.ConfirmationCode?.Code ?? "Not Available"
                    : null
            };

            return Ok(orderDetails);
        }

        [Authorize(Roles = "Admin")]
        [HttpGet("order-details-Admin/{orderId}")]
        public async Task<IActionResult> GetOrderDetailsForAdmin(int orderId)
        {
            // جلب الطلب بالكامل
            var order = await _context.Orders
                .Include(o => o.User) // بيانات العميل
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
                .ThenInclude(p => p.User) // بيانات الحرفي
                .Include(o => o.ConfirmationCode) // كود التأكيد
                .FirstOrDefaultAsync(o => o.Order_ID == orderId);

            if (order == null)
                return NotFound(new { Message = "Order not found." });

            // جلب كود التأكيد لو الحالة Delivered
            var conformCode = order.Order_Status == OrderStatus.Delivered
                ? order.ConfirmationCode?.Code ?? "Not Available"
                : null;

            // تجهيز تفاصيل الطلب
            var orderDetails = new
            {
                Order_ID = order.Order_ID,
                Order_Status = order.Order_Status.ToString(), // ✅ نص بدل الأرقام
                Payment_Method = order.Payment_Method.ToString(), // ✅ نص بدل الأرقام
                Payment_Status = order.Payment_Status.ToString(), // ✅ نص بدل الأرقام
                Shipping_Method = order.Shipping_Method.ToString(),
                Payment_Reference = order.Payment_Reference,
                Order_Date = order.Order_Date,
                Order_Price = order.Order_Price,
                Shipping_Cost = order.Shipping_Cost,
                Total_Amount = order.Total_Amount,
                Client = new
                {
                    Full_Name = order.User?.Full_Name,
                    Phone_Number = order.User?.Phone,
                    Address = order.Receive_Address
                },
                Products = order.OrderItems.Select(oi => new
                {
                    Product_ID = oi.Product.Product_ID,
                    Product_Name = oi.Product.Name,
                    Artisan_Name = oi.Product.User?.Full_Name,
                    Quantity = oi.Quantity,
                    Total_Price = oi.Total_Price
                }).ToList(),
                Conform_Code = conformCode
            };

            return Ok(orderDetails);
        }
        [Authorize(Roles = "Artisan")]
        [HttpGet("order-details-Artisan/{orderId}")]
        public async Task<IActionResult> GetOrderDetailsForArtisan(int orderId)
        {
            var artisanSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(artisanSSN))
                return Unauthorized(new { Message = "Invalid artisan identity." });

            // التحقق من أن الطلب يحتوي على منتجات تخص الحرفي
            var order = await _context.Orders
                .Include(o => o.User) // بيانات العميل (صاحب الطلب)
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
                .Where(o => o.Order_ID == orderId && o.OrderItems.Any(oi => oi.Product.User_SSN == artisanSSN))
                .FirstOrDefaultAsync();

            if (order == null)
                return NotFound(new { Message = "Order not found or you don't have permission to view its details." });

            // تجهيز بيانات الرد
            var orderDetails = new
            {
                order.Order_ID,
                Order_Status = order.Order_Status.ToString(), // ✅ النص بدل الرقم
                Shipping_Method = order.Shipping_Method.ToString(),
                order.Order_Price,
                order.Shipping_Cost,
                order.Zip_Code,
                Client = new
                {
                    Full_Name = order.User?.Full_Name,
                    Phone_Number = order.User?.Phone,
                    Address = order.Receive_Address
                },
                Products = order.OrderItems
                    .Where(oi => oi.Product.User_SSN == artisanSSN)
                    .Select(oi => new
                    {
                        oi.Product.Product_ID,
                        Product_Name = oi.Product.Name,
                        oi.Quantity,
                        oi.Total_Price
                    }).ToList()
            };

            return Ok(orderDetails);
        }
        [Authorize]
        [HttpGet("Myorders-status")]
        public async Task<IActionResult> GetOrdersByStatus([FromQuery] string status)
        {
            if (!Enum.TryParse<OrderStatus>(status, true, out var parsedStatus))
                return BadRequest(new { Message = "Invalid order status." });

            var ssn = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(ssn))
                return Unauthorized(new { Message = "Invalid user identity." });

            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

            IQueryable<Order> query = _context.Orders;

            // 🔍 لو المستخدم حرفي
            if (userRole == "Artisan")
            {
                query = query
                    .Include(o => o.OrderItems)
                        .ThenInclude(oi => oi.Product)
                    .Where(o => o.OrderItems.Any(oi => oi.Product.User_SSN == ssn));
            }
            // 👨‍💼 لو المستخدم عميل
            else if (userRole == "Client")
            {
                query = query.Where(o => o.User_SSN == ssn);
            }
            else
            {
                return Unauthorized(new { Message = "Only Clients or Artisans can access their orders." });
            }

            // ✅ فلترة بالحالة المطلوبة
            var filteredOrders = await query
                .Where(o => o.Order_Status == parsedStatus)
                .Select(o => new
                {
                    o.Order_ID,
                    Order_Status = o.Order_Status.ToString(),
                    o.Order_Date,
                    Arrived_Date = o.Order_Status == OrderStatus.Delivered ? o.Arrived_Date : null
                })
                .ToListAsync();

            return Ok(filteredOrders);
        }



    }



}