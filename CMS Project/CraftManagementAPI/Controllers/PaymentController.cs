using CraftManagementAPI.Data;
using CraftManagementAPI.Models;
using CraftManagementAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CraftManagementAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PaymentController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly PayPalService _paypalService;

        public PaymentController(ApplicationDbContext context, PayPalService paypalService)
        {
            _context = context;
            _paypalService = paypalService;
        }

        [HttpPost("create")]
        [Authorize(Roles = "Client")]
        public async Task<IActionResult> CreatePayment([FromQuery] int orderId)
        {
            var order = await _context.Orders.FirstOrDefaultAsync(o => o.Order_ID == orderId);
            if (order == null)
                return NotFound(new { Message = "Order not found." });

            try
            {
                var (approvalUrl, paypalOrderId) = await _paypalService.CreatePaymentAsync(order, "paypal");

                // Save payment reference in the order
                order.Payment_Reference = paypalOrderId;
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    Message = "PayPal payment link created successfully.",
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
                    Message = "An error occurred while generating the PayPal link.",
                    Error = ex.Message
                });
            }
        }
    }

}
