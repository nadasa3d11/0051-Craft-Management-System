using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CraftManagementAPI.Data;
using CraftManagementAPI.Models;
using System.Security.Claims;
using CraftManagementAPI.Enums;
using System.Collections.Generic;

namespace CraftManagementAPI.Controllers
{
    [Route("api/cart")]
    [ApiController]
    [Authorize(Roles = "Client")]
    public class CartController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public CartController(ApplicationDbContext context)
        {
            _context = context;
        }

        [Authorize(Roles = "Client")]
        [HttpPost("add")]
        public async Task<IActionResult> AddToCart([FromBody] AddToCartRequest request)
        {
            var clientSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(clientSSN))
                return Unauthorized(new { Message = "Invalid client identity or token." });

            if (request.Product_ID <= 0)
                return BadRequest(new { Message = "Invalid Product ID." });

            var product = await _context.Products
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.Product_ID == request.Product_ID);

            if (product == null)
                return NotFound(new { Message = "Product not found." });

            if (product.Quantity <= 0)
                return BadRequest(new { Message = "Product is out of stock." });

            var existingCartItem = await _context.Carts
                .FirstOrDefaultAsync(c => c.Product_ID == request.Product_ID && c.User_SSN == clientSSN);

            if (existingCartItem != null)
                return BadRequest(new { Message = "Product already in your cart." });

            var artisanSSN = product.User_SSN;

            var cartItems = await _context.Carts
                .Include(c => c.Product)
                .ThenInclude(p => p.User)
                .Where(c => c.User_SSN == clientSSN)
                .ToListAsync();

            

            var newCartItem = new Cart
            {
                Product_ID = request.Product_ID,
                User_SSN = clientSSN,
                Quantity = 1,
                Added_Date = DateTime.UtcNow
            };

            _context.Carts.Add(newCartItem);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Product added to cart successfully." });
        }


        // ✅ عرض المنتجات في السلة مع أسماء المنتجات وصورها
        [HttpGet("items")]
        public async Task<IActionResult> GetCartItems()
        {
            var clientSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (clientSSN == null)
                return Unauthorized(new { Message = "Invalid client identity." });

            var cartItems = await _context.Carts
                .Where(c => c.User_SSN == clientSSN)
                .Include(c => c.Product)
                .ThenInclude(p => p.User) // جلب بيانات الحرفي
                .Include(c => c.Product.ProductImages) // جلب صور المنتج
                .Select(c => new
                {
                    c.Cart_ID,
                    Productid = c.Product_ID,
                    ProductPrice = c.Product.Price,
                    ProductName = c.Product.Name,
                  
                    ArtisanName = c.Product.User.Full_Name,
                    c.Quantity,
                    c.Added_Date,
                    Product_Avarge = c.Product.Rating_Average,
                    ProductImages = c.Product.ProductImages
                        .Select(img => $"{Request.Scheme}://{Request.Host}/{(img.Images)}")
                        .ToList() // توليد الروابط الكاملة للصور
                })
                .ToListAsync();

            return Ok(cartItems);
        }

        [Authorize(Roles = "Client")]
        [HttpPut("Updated_Quantity/{cartId}")]
        public async Task<IActionResult> UpdateCartItem(int cartId, [FromBody] UpdateCartQuantityRequest request)
        {
            var cartItem = await _context.Carts
                .Include(c => c.Product)
                .FirstOrDefaultAsync(c => c.Cart_ID == cartId);

            if (cartItem == null)
                return NotFound(new { Message = "Cart item not found." });

            if (request.Quantity < 0)
                return BadRequest(new { Message = "Quantity must be 0 or greater." });

            if (request.Quantity == 0)
            {
                _context.Carts.Remove(cartItem); // ✅ حذف المنتج إذا الكمية = 0
                await _context.SaveChangesAsync();
                return Ok(new { Message = "Product removed from cart because quantity is 0." });
            }

            if (request.Quantity > cartItem.Product.Quantity)
                return BadRequest(new { Message = "Not enough stock available." });

            cartItem.Quantity = request.Quantity;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Cart item quantity updated successfully.",
                Cart_ID = cartItem.Cart_ID,
                Product_ID = cartItem.Product_ID,
                Updated_Quantity = cartItem.Quantity
            });
        }
        //حذف منتج من سله
        [Authorize(Roles = "Client")]
        [HttpDelete("remove/{cartId}")]
        public async Task<IActionResult> RemoveFromCart(int cartId)
        {
            var cartItem = await _context.Carts.FindAsync(cartId);
            if (cartItem == null)
                return NotFound(new { Message = "Cart item not found." });

            _context.Carts.Remove(cartItem);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Product removed from cart successfully." });
        }

        public class AddToCartRequest
        {
            public int Product_ID { get; set; }
        }
        public class UpdateCartQuantityRequest
        {
            public int Quantity { get; set; } // الكمية المطلوبة (زيادة أو تقليل)
        }


    }
}
