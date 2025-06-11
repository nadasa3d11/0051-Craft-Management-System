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
using System.Runtime.Intrinsics.X86;


namespace CraftManagementAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OrderForArtisanController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly PayPalService _payPalService;
        private readonly PaymobService _paymobService;

        public OrderForArtisanController(ApplicationDbContext context, PayPalService payPalService, PaymobService paymobService, IHubContext<NotificationHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
            _payPalService = payPalService;
            _paymobService = paymobService;
        }
        [Authorize(Roles = "Client")]
        [HttpPost("checkout")]
        public async Task<IActionResult> Checkout([FromBody] CheckoutRequest request)
        {
            try
            {
                var clientSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(clientSSN))
                    return Unauthorized(new { Message = "Invalid client identity." });

                var cartItems = await _context.Carts
                    .Where(c => c.User_SSN == clientSSN)
                    .Include(c => c.Product)
                    .ThenInclude(p => p.User)
                    .ToListAsync();

                if (!cartItems.Any())
                    return BadRequest(new { Message = "Cart is empty." });

                if (!Enum.TryParse<PaymentMethod>(request.PaymentMethod, true, out var paymentMethod))
                    return BadRequest(new { Message = "Invalid payment method." });

                if (!Enum.TryParse<ShippingMethod>(request.ShippingMethod, true, out var shippingMethod))
                    return BadRequest(new { Message = "Invalid shipping method." });

                // تجميع المنتجات حسب الحرفي
                var groupedByArtisan = cartItems.GroupBy(item => item.Product.User_SSN);

                var allOrderIds = new List<int>();
                var notificationTasks = new List<Task>();

                foreach (var group in groupedByArtisan)
                {
                    var artisanSSN = group.Key!;
                    var items = group.ToList();

                    var orderPrice = items.Sum(i => i.Product.Price * i.Quantity);
                    var totalAmount = orderPrice + request.ShippingCost;

                    var newOrder = new Order
                    {
                        User_SSN = clientSSN,
                        Order_Date = DateTime.UtcNow,
                        Payment_Method = paymentMethod,
                        Receive_Address = request.Address,
                        Zip_Code = request.ZipCode,
                        Full_Name = request.FullName,
                        Phone_Number = request.PhoneNumber,
                        Order_Status = OrderStatus.Pending,
                        Payment_Status = PaymentStatus.NotPaid,
                        Order_Price = orderPrice,
                        Total_Amount = totalAmount,
                        Shipping_Method = shippingMethod,
                        Shipping_Cost = request.ShippingCost
                    };

                    _context.Orders.Add(newOrder);
                    await _context.SaveChangesAsync();

                    foreach (var item in items)
                    {
                        var orderItem = new OrderItem
                        {
                            Order_ID = newOrder.Order_ID,
                            Product_ID = item.Product.Product_ID,
                            Quantity = item.Quantity,
                            Total_Price = item.Product.Price * item.Quantity
                        };
                        _context.OrderItems.Add(orderItem);
                        _context.Carts.Remove(item); // حذف من السلة
                    }

                    // إشعار للحرفي
                    var notification = new Notification
                    {
                        SSN = artisanSSN,
                        SenderSSN = clientSSN,
                        NotificationType = "NewOrder",
                        Message = $"📦 New pending order (ID #{newOrder.Order_ID}) for your products.",
                        CreatedAt = DateTime.UtcNow,
                        IsRead = false
                    };

                    _context.Notifications.Add(notification);
                    var task = _hubContext.Clients.Group(artisanSSN).SendAsync("ReceiveNotification", new
                    {
                        Message = notification.Message,
                        NotificationType = notification.NotificationType,
                        Sender = clientSSN
                    });

                    notificationTasks.Add(task);
                    allOrderIds.Add(newOrder.Order_ID);
                }

                await _context.SaveChangesAsync();
                await Task.WhenAll(notificationTasks);

                return Ok(new
                {
                    Message = "Orders placed successfully for each artisan.",
                    OrderIDs = allOrderIds,
                    Count = allOrderIds.Count
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { Message = "An error occurred during checkout.", Error = ex.Message });
            }
        }

        //موافقه حرفي علي اوردر
        [Authorize(Roles = "Artisan")]
        [HttpPut("accept-order/{orderId}")]
        public async Task<IActionResult> AcceptOrder(int orderId)
        {
            var artisanSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(artisanSSN))
                return Unauthorized(new { Message = "Invalid artisan identity." });

            // جلب الطلب والتحقق من المنتجات المرتبطة بالحرفي
            var order = await _context.Orders
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
                .FirstOrDefaultAsync(o => o.Order_ID == orderId && o.OrderItems.Any(oi => oi.Product.User_SSN == artisanSSN));

            if (order == null)
                return NotFound(new { Message = "Order not found or you don't have permission to accept it." });

            if (order.Order_Status != OrderStatus.Pending)
                return BadRequest(new { Message = "Order is not in a pending state." });

            // ✅ تحديث حالة الطلب إلى Processing
            order.Order_Status = OrderStatus.Processing;

            // ✅ توليد روابط الدفع وحفظ المرجع في Payment_Reference
            string? paymentUrl = null;
            string? paymentReference = null;

            switch (order.Payment_Method)
            {
                case PaymentMethod.PayPal:
                    var (paypalUrl, paypalReference) = await _payPalService.CreatePaymentAsync(order, "PayPal");
                    paymentUrl = paypalUrl;
                    paymentReference = paypalReference;
                    break;

                case PaymentMethod.Paymob:
                    var (paymobUrl, paymobReference) = await _paymobService.GeneratePaymentUrl(order);
                    paymentUrl = paymobUrl;
                    paymentReference = paymobReference;
                    break;

                case PaymentMethod.Cash:
                    paymentUrl = null;
                    paymentReference = null;
                    break;

                default:
                    return BadRequest(new { Message = "Invalid payment method." });
            }

            // ✅ حفظ Payment Reference لو موجود
            if (!string.IsNullOrEmpty(paymentReference))
            {
                order.Payment_Reference = paymentReference;
            }

            await _context.SaveChangesAsync();

            // ✅ إشعار العميل
            var clientNotification = new Notification
            {
                SSN = order.User_SSN!,
                Message = order.Payment_Method == PaymentMethod.Cash
                    ? $"✅ Your order # {order.Order_ID} is accepted. Please pay cash on delivery."
                    : $"✅ Your order # {order.Order_ID} is accepted. Please complete the payment.",
                CreatedAt = DateTime.UtcNow,
                IsRead = false,
                SenderSSN = artisanSSN,
                NotificationType = "Payment"
            };

            _context.Notifications.Add(clientNotification);
            await _context.SaveChangesAsync();
            try
            {
                await _hubContext.Clients.Group(order.User_SSN!).SendAsync("ReceiveNotification", new
                {
                    Message = clientNotification.Message,
                    NotificationType = clientNotification.NotificationType,
                    OrderID = order.Order_ID
                });

                Console.WriteLine($"✅ Notification sent to Client {order.User_SSN}: {clientNotification.Message}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to send notification to Client {order.User_SSN}: {ex.Message}");
            }

            // ✅ الرد النهائي
            return Ok(new
            {
                Message = "Order accepted.",
                OrderID = order.Order_ID,
                PaymentUrl = paymentUrl,
                OrderStatus = order.Order_Status.ToString(),
                PaymentReference = order.Payment_Reference
            });
        }

        [Authorize(Roles = "Artisan")]
        [HttpPut("ship-order/{orderId}")]
        public async Task<IActionResult> ShipOrder(int orderId)
        {
            var artisanSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(artisanSSN))
                return Unauthorized(new { Message = "Invalid artisan identity." });

            var order = await _context.Orders
                .Include(o => o.ConfirmationCode)
                .FirstOrDefaultAsync(o => o.Order_ID == orderId);

            if (order == null || order.Order_Status != OrderStatus.Processing)
                return NotFound(new { Message = "Order not found or not ready for shipping." });

            // تغيير حالة الطلب إلى Shipped
            order.Order_Status = OrderStatus.Shipped;

            // ✅ توليد كود التأكيد لو مش موجود
            if (order.ConfirmationCode == null)
            {
                var random = new Random();
                var confirmationCode = new ConfirmationCode
                {
                    Order_ID = order.Order_ID,
                    Code = random.Next(100000, 999999).ToString(), // توليد كود عشوائي مكون من 6 أرقام
                    CreatedAt = DateTime.UtcNow
                };

                _context.ConfirmationCodes.Add(confirmationCode);
                order.ConfirmationCode = confirmationCode; // ربط الطلب بكود التأكيد
            }

            // ✅ إشعار العميل بالكود
            var clientNotification = new Notification
            {
                SSN = order.User_SSN!,
                Message = $"🚚 Your order # {order.Order_ID} has been shipped! Confirmation Code: {order.ConfirmationCode.Code}",
                CreatedAt = DateTime.UtcNow,
                IsRead = false,
                SenderSSN = artisanSSN,
                NotificationType = "OrderShipped" // ✅ نوع الإشعار
               
            };

            _context.Notifications.Add(clientNotification);
            await _context.SaveChangesAsync();
            // ✅ إرسال الإشعار عبر SignalR مع Order_ID مباشرة
            try
            {
                await _hubContext.Clients.Group(order.User_SSN!).SendAsync("ReceiveNotification", new
                {
                    Message = clientNotification.Message,
                    NotificationType = clientNotification.NotificationType,
                    OrderID = order.Order_ID // ✅ إرسال Order_ID بدون حفظه في جدول Notification
                });

                Console.WriteLine($"✅ Notification sent to Client {order.User_SSN}: {clientNotification.Message}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to send notification to Client {order.User_SSN}: {ex.Message}");
            }

            // ✅ الاستجابة
            return Ok(new
            {
                Message = "Order shipped successfully.",
                OrderID = order.Order_ID,
                Conform_Code = order.ConfirmationCode.Code
            });
        }
        [Authorize(Roles = "Artisan")]
        [HttpPut("confirm-delivery/{orderId}")]
        public async Task<IActionResult> ConfirmDelivery(int orderId, [FromBody] string enteredCode)
        {
            var artisanSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(artisanSSN))
                return Unauthorized(new { Message = "Invalid artisan identity." });

            var order = await _context.Orders
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
                .FirstOrDefaultAsync(o => o.Order_ID == orderId && o.OrderItems.Any(oi => oi.Product.User_SSN == artisanSSN));

            if (order == null)
                return NotFound(new { Message = "Order not found or you don't have permission to confirm delivery." });

            if (order.Order_Status != OrderStatus.Shipped)
                return BadRequest(new { Message = "Order must be shipped before confirming delivery." });

            var conformCode = await _context.ConfirmationCodes.FirstOrDefaultAsync(c => c.Order_ID == orderId);
            if (conformCode == null || conformCode.Code != enteredCode)
                return BadRequest(new { Message = "Invalid Confirm Code." });

            // تحديث الكميات
            foreach (var orderItem in order.OrderItems)
            {
                var product = orderItem.Product;

                // تحقق من أن الكمية المتوفرة كافية
                if (product.Quantity < orderItem.Quantity)
                {
                    return BadRequest(new { Message = $"Not enough stock for product {product.Name}." });
                }

                // خصم الكمية المطلوبة من المخزون
                product.Quantity -= orderItem.Quantity;
            }

            order.Order_Status = OrderStatus.Delivered;
            order.Arrived_Date = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            var clientNotification = new Notification
            {
                SSN = order.User_SSN!,
                Message = $"✅ Your order # {order.Order_ID} has been delivered. Thank you for shopping!",
                CreatedAt = DateTime.UtcNow,
                IsRead = false,
                SenderSSN = artisanSSN,
                NotificationType = "OrderDelivered"
            };

            _context.Notifications.Add(clientNotification);
            await _context.SaveChangesAsync();

            // إرسال الإشعار عبر SignalR مع `Order_ID`
            try
            {
                await _hubContext.Clients.Group(order.User_SSN!).SendAsync("ReceiveNotification", new
                {
                    Message = clientNotification.Message,
                    NotificationType = clientNotification.NotificationType,
                    OrderID = order.Order_ID
                });

                Console.WriteLine($"✅ Notification sent to Client {order.User_SSN}: {clientNotification.Message}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to send notification to Client {order.User_SSN}: {ex.Message}");
            }

            return Ok(new
            {
                Message = "Order marked as Delivered.",
                OrderID = order.Order_ID,
                OrderStatus = order.Order_Status.ToString(),
                ArrivedOrder = order.Arrived_Date
            });
        }

        [Authorize(Roles = "Admin")]
        [HttpPut("confirm-complete/{orderId}")]
        public async Task<IActionResult> ConfirmOrderCompletion(int orderId)
        {
            var order = await _context.Orders.FindAsync(orderId);
            if (order == null)
                return NotFound(new { Message = "Order not found." });

            if (order.Order_Status != OrderStatus.Delivered)
                return BadRequest(new { Message = "Order must be delivered before marking it as complete." });

            if (order.Payment_Status != PaymentStatus.Paid)
                return BadRequest(new { Message = "Payment must be confirmed before completing the order." });

            order.Order_Status = OrderStatus.Complete;

            await _context.SaveChangesAsync();

            var clientNotification = new Notification
            {
                SSN = order.User_SSN!,
                Message = $"✅ Your order is now complete. Thanks for your purchase!",
                CreatedAt = DateTime.UtcNow,
                IsRead = false,
                NotificationType = "OrderComplete"
            };

            _context.Notifications.Add(clientNotification);
            await _context.SaveChangesAsync();
            // ✅ إرسال الإشعار عبر SignalR مع `Order_ID`
            try
            {
                await _hubContext.Clients.Group(order.User_SSN!).SendAsync("ReceiveNotification", new
                {
                    Message = clientNotification.Message,
                    NotificationType = clientNotification.NotificationType,
                    OrderID = order.Order_ID // ✅ إرسال `Order_ID` بدون حفظه في جدول `Notification`
                });

                Console.WriteLine($"✅ Notification sent to Client {order.User_SSN}: {clientNotification.Message}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to send notification to Client {order.User_SSN}: {ex.Message}");
            }
            return Ok(new
            {
                Message = "Order marked as Complete.",
                OrderID = order.Order_ID,
                OrderStatus = order.Order_Status.ToString()
            });
        }
        [Authorize(Roles = "Client")]
        [HttpPut("cancel-order_Client/{orderId}")]
        public async Task<IActionResult> CancelOrderByClient(int orderId)
        {
            var clientSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (clientSSN == null)
                return Unauthorized(new { Message = "Invalid client identity." });

            var order = await _context.Orders.FirstOrDefaultAsync(o => o.Order_ID == orderId && o.User_SSN == clientSSN);

            if (order == null)
                return NotFound(new { Message = "Order not found or you don't have permission to cancel it." });

            if (order.Order_Status != OrderStatus.Pending)
                return BadRequest(new { Message = "You can only cancel pending orders." });

            order.Order_Status = OrderStatus.Cancelled;
            await _context.SaveChangesAsync();

            var artisanSSNs = await _context.OrderItems
                .Where(oi => oi.Order_ID == orderId)
                .Select(oi => oi.Product.User_SSN)
                .Distinct()
                .ToListAsync();

            foreach (var artisanSSN in artisanSSNs)
            {
                var notification = new Notification
                {
                    SSN = artisanSSN!,
                    Message = $"❌ An order # {order.Order_ID} has been cancelled by the client.",
                    CreatedAt = DateTime.UtcNow,
                    IsRead = false,
                    SenderSSN = clientSSN,
                    NotificationType = "OrderCancelled"
                };
                _context.Notifications.Add(notification);
               
            }

            await _context.SaveChangesAsync();
            // ✅ إرسال الإشعارات عبر `SignalR`
            foreach (var artisanSSN in artisanSSNs)
            {
                try
                {
                    await _hubContext.Clients.Group(artisanSSN!).SendAsync("ReceiveNotification", new
                    {
                        Message = $"❌ An order  # {order.Order_ID} has been cancelled by the client.",
                        NotificationType = "OrderCancelled",
                        OrderID = order.Order_ID // ✅ إرسال `Order_ID` بدون حفظه في `Notification`
                    });

                    Console.WriteLine($"✅ Notification sent to Artisan {artisanSSN}: Order {order.Order_ID} cancelled.");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"❌ Failed to send notification to Artisan {artisanSSN}: {ex.Message}");
                }
            }

            return Ok(new
            {
                Message = "Order has been cancelled.",
                OrderID = order.Order_ID,
                OrderStatus = order.Order_Status.ToString()
            });
        }
        [Authorize(Roles = "Artisan")]
        [HttpPut("cancel-order_Artisan/{orderId}")]
        public async Task<IActionResult> CancelOrderByArtisan(int orderId)
        {
            var artisanSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (artisanSSN == null)
                return Unauthorized(new { Message = "Invalid artisan identity." });

            var order = await _context.Orders
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
                .FirstOrDefaultAsync(o => o.Order_ID == orderId && o.OrderItems.Any(oi => oi.Product.User_SSN == artisanSSN));

            if (order == null)
                return NotFound(new { Message = "Order not found or you don't have permission to cancel it." });

            if (order.Order_Status != OrderStatus.Pending && order.Order_Status != OrderStatus.Processing)
                return BadRequest(new { Message = "You can only cancel pending or processing orders." });

            order.Order_Status = OrderStatus.Cancelled;
            await _context.SaveChangesAsync();

            var clientNotification = new Notification
            {
                SSN = order.User_SSN!,
                Message = $"❌ Your order # {order.Order_ID} has been cancelled by the artisan.",
                CreatedAt = DateTime.UtcNow,
                IsRead = false,
                SenderSSN = artisanSSN,
                NotificationType = "OrderCancelledByArtisan"
            };

            _context.Notifications.Add(clientNotification);
            await _context.SaveChangesAsync();

            try
            {
                // ✅ إرسال الإشعار للعميل عبر `SignalR`
                await _hubContext.Clients.Group(order.User_SSN!).SendAsync("ReceiveNotification", new
                {
                    Message = $"❌ Your order # {order.Order_ID} has been cancelled by the artisan.",
                    NotificationType = "OrderCancelledByArtisan",
                    OrderID = order.Order_ID // ✅ إرسال `Order_ID` بدون حفظه في `Notification`
                });

                Console.WriteLine($"✅ Notification sent to Client {order.User_SSN}: Order {order.Order_ID} cancelled by Artisan.");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to send notification to Client {order.User_SSN}: {ex.Message}");
            }

            return Ok(new
            {
                Message = "Order has been cancelled.",
                OrderID = order.Order_ID,
                OrderStatus = order.Order_Status.ToString()
            });
        }
        

        [HttpGet("confirm-payment")]
        public async Task<IActionResult> ConfirmPayment([FromQuery] string paymentReference)
        {
            // ✅ البحث عن الطلب باستخدام Payment_Reference
            var order = await _context.Orders.FirstOrDefaultAsync(o => o.Payment_Reference == paymentReference);
            if (order == null)
                return NotFound(new { Message = "Order not found." });

            // ✅ التحقق من حالة الدفع
            if (order.Payment_Status == PaymentStatus.Paid)
            {
                return BadRequest(new { Message = "Payment already confirmed." });
            }

            // ✅ تحديث حالة الطلب بعد الدفع
            order.Payment_Status = PaymentStatus.Paid;
            order.Order_Status = OrderStatus.Processing;
            order.Arrived_Date = DateTime.UtcNow;

            // ✅ إشعار للعميل بتأكيد الدفع
            var notification = new Notification
            {
                SSN = order.User_SSN!,
                Message = $"✅ Your payment for Order #{order.Order_ID} has been confirmed.",
                CreatedAt = DateTime.UtcNow,
                IsRead = false,
                NotificationType = "PaymentConfirmed"
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();
            try
            {
                // ✅ إرسال الإشعار للعميل عبر `SignalR`
                await _hubContext.Clients.Group(order.User_SSN!).SendAsync("ReceiveNotification", new
                {
                    Message = $"✅ Your payment for Order #{order.Order_ID} has been confirmed.",
                    NotificationType = "PaymentConfirmed",
                    OrderID = order.Order_ID // ✅ إرسال `Order_ID` بدون حفظه في `Notification`
                });

                Console.WriteLine($"✅ Payment confirmation notification sent to Client {order.User_SSN} for Order {order.Order_ID}.");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to send payment confirmation notification to Client {order.User_SSN}: {ex.Message}");
            }
            return Ok(new
            {
                Message = "Payment confirmed successfully!",
                OrderID = order.Order_ID,
                PaymentStatus = order.Payment_Status.ToString()
            });
        }
        [HttpGet("cancel-payment")]
        public async Task<IActionResult> CancelPayment([FromQuery] string paymentReference)
        {
            // ✅ البحث عن الطلب باستخدام Payment_Reference
            var order = await _context.Orders.FirstOrDefaultAsync(o => o.Payment_Reference == paymentReference);
            if (order == null)
                return NotFound(new { Message = "Order not found." });

            // ✅ التأكد إن الطلب مش مدفوع بالفعل
            if (order.Payment_Status == PaymentStatus.Paid)
            {
                return BadRequest(new { Message = "Payment has already been completed." });
            }

            // ✅ تحديث حالة الطلب إلى "Cancelled"
            order.Order_Status = OrderStatus.Cancelled;
            order.Payment_Reference = null; // إزالة مرجع الدفع
            await _context.SaveChangesAsync();

            // ✅ إشعار للعميل بإلغاء الطلب
            var clientNotification = new Notification
            {
                SSN = order.User_SSN!,
                Message = $"❌ Your payment for Order #{order.Order_ID} has been cancelled.",
                CreatedAt = DateTime.UtcNow,
                IsRead = false,
                NotificationType = "OrderCancelled"
            };

            _context.Notifications.Add(clientNotification);
            await _context.SaveChangesAsync();
            try
            {
                // ✅ إرسال الإشعار للعميل عبر `SignalR`
                await _hubContext.Clients.Group(order.User_SSN!).SendAsync("ReceiveNotification", new
                {
                    Message = $"❌ Your payment for Order #{order.Order_ID} has been cancelled.",
                    NotificationType = "OrderCancelled",
                    OrderID = order.Order_ID
                });

                Console.WriteLine($"✅ Order cancellation notification sent to Client {order.User_SSN} for Order {order.Order_ID}.");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to send order cancellation notification to Client {order.User_SSN}: {ex.Message}");
            }
            // ✅ جلب الـ SSNs لكل الحرفيين المرتبطين بالطلب
            var artisanSSNs = await _context.OrderItems
                .Where(oi => oi.Order_ID == order.Order_ID)
                .Include(oi => oi.Product)
                .Select(oi => oi.Product.User_SSN)
                .Distinct()
                .ToListAsync();

            // ✅ تجهيز الإشعارات لكل حرفي
            var artisanNotifications = artisanSSNs.Select(ssn => new Notification
            {
                SSN = ssn!,
                Message = $"⚠️ Order #{order.Order_ID} has been cancelled by the client.",
                CreatedAt = DateTime.UtcNow,
                IsRead = false,
                NotificationType = "OrderCancelled"
            }).ToList();

            // ✅ إضافة الإشعارات إلى قاعدة البيانات
            _context.Notifications.AddRange(artisanNotifications);
            await _context.SaveChangesAsync();
            // ✅ إرسال الإشعارات الفورية لكل حرفي
            foreach (var notification in artisanNotifications)
            {
                try
                {
                    await _hubContext.Clients.Group(notification.SSN).SendAsync("ReceiveNotification", new
                    {
                        Message = notification.Message,
                        NotificationType = "OrderCancelled",
                        OrderID = order.Order_ID
                    });

                    Console.WriteLine($"✅ Order cancellation notification sent to Artisan {notification.SSN} for Order {order.Order_ID}.");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"❌ Failed to send order cancellation notification to Artisan {notification.SSN}: {ex.Message}");
                }
            }

            // ✅ الرد
            return Ok(new
            {
                Message = "Payment was cancelled. The order status is now 'Cancelled'.",
                OrderID = order.Order_ID,
                OrderStatus = order.Order_Status.ToString()
            });

        }
        [Authorize(Roles = "Artisan, Admin")]
        [HttpPut("confirm-cash-payment/{orderId}")]
        public async Task<IActionResult> ConfirmCashPayment(int orderId)
        {
            var order = await _context.Orders.FindAsync(orderId);
            if (order == null)
                return NotFound(new { Message = "Order not found." });

            if (order.Payment_Method != PaymentMethod.Cash)
                return BadRequest(new { Message = "Payment method is not Cash." });

            if (order.Payment_Status == PaymentStatus.Paid)
                return BadRequest(new { Message = "Payment already confirmed." });

            order.Payment_Status = PaymentStatus.Paid;
            order.Order_Status = OrderStatus.Complete;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Cash payment confirmed.",
                OrderID = order.Order_ID,
                OrderStatus = order.Order_Status.ToString()
            });
        }
       /* [Authorize(Roles = "Client,Admin")]
        [HttpGet("generate-paypal-link/{orderId}")]
        public async Task<IActionResult> GeneratePayPalLink(int orderId)
        {
            var order = await _context.Orders
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
                .FirstOrDefaultAsync(o => o.Order_ID == orderId);

            if (order == null)
                return NotFound(new { Message = "Order not found." });

            if (order.Payment_Method != PaymentMethod.PayPal)
                return BadRequest(new { Message = "This order is not set for PayPal payment." });

            if (order.Total_Amount <= 0)
                return BadRequest(new { Message = "Invalid total amount for payment." });

            try
            {
                var (approvalUrl, paypalOrderId) = await _payPalService.CreatePaymentAsync(order, "PayPal", "USD");

                order.Payment_Reference = paypalOrderId;
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    Message = "PayPal payment link generated successfully.",
                    Order_ID = order.Order_ID,
                    Total_Amount = order.Total_Amount.ToString("F2"),
                    Payment_Reference = paypalOrderId,
                    PaymentUrl = approvalUrl
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    Message = "Failed to generate PayPal link.",
                    Error = ex.Message
                });
            }
        }*/

    


}



    // لتحديث حالة الطلب
    public class UpdateOrderStatusRequest
        {
            public OrderStatus NewStatus { get; set; }
        }


        // لإلغاء الطلب
        public class CancelOrderRequest
        {
            public string Reason { get; set; } = string.Empty; // السبب وراء الإلغاء
        }

        // لعرض تفاصيل الطلب
        public class OrderDetailsDto
        {
            public int OrderId { get; set; }
            public DateTime OrderDate { get; set; }
            public List<ProductDetailsDto> Products { get; set; } = new();
            public decimal ShippingCost { get; set; }
            public decimal TotalPrice { get; set; }
            public string DeliveryCode { get; set; } = string.Empty; // كود التأكيد
        }

        // لعرض تفاصيل المنتجات داخل الطلب
        public class ProductDetailsDto
        {
            public string ProductName { get; set; } = string.Empty;
            public int Quantity { get; set; }
            public decimal ProductPrice { get; set; }
        }
        public class CartItemDTO
        {
            public int Product_ID { get; set; } // معرّف المنتج

            public int Quantity { get; set; } // الكمية المطلوبة
        }

        // ✅ موديل الطلب
        public class CheckoutRequest
        {
            public List<CartItemDTO> Items { get; set; } = new();

            public string PaymentMethod { get; set; } = null!; // طريقة الدفع (مثل: Cash, PayPal)

            public string ShippingMethod { get; set; } = null!; // مثل: Free, Express

            public decimal ShippingCost { get; set; } // تكلفة الشحن

            public string Address { get; set; } = null!; // عنوان التسليم

            public string ZipCode { get; set; } = null!; // الرمز البريدي

            public string FullName { get; set; } = null!; // اسم المستلم

            public string PhoneNumber { get; set; } = null!; // رقم الهاتف

           
        }
    }
