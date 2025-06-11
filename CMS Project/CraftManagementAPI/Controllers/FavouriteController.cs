using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using CraftManagementAPI.Data;
using CraftManagementAPI.Models;

namespace CraftManagementAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Client")]
    public class FavouriteController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public FavouriteController(ApplicationDbContext context)
        {
            _context = context;
        }

        // ✅ إضافة منتج إلى المفضلة
        [HttpPost("add")]
        public async Task<IActionResult> AddToFavourites([FromBody] AddToFavouriteRequest request)
        {
            var clientSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (clientSSN == null)
                return Unauthorized(new { Message = "Invalid user." });

            var client = await _context.Users.FirstOrDefaultAsync(u => u.SSN == clientSSN);
            if (client == null)
                return NotFound(new { Message = "Client not found." });

            var product = await _context.Products.FirstOrDefaultAsync(p => p.Product_ID == request.Product_ID);
            if (product == null)
                return NotFound(new { Message = "Product not found." });

            // التحقق إذا كان المنتج موجودًا في المفضلة بالفعل
            var existingFavourite = await _context.Favourites
                .FirstOrDefaultAsync(f => f.SSN == clientSSN && f.Product_ID == request.Product_ID);

            if (existingFavourite != null)
                return BadRequest(new { Message = "Product is already in your favourites." });

            var favourite = new Favourite
            {
                SSN = clientSSN,
                Product_ID = product.Product_ID
            };

            _context.Favourites.Add(favourite);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Product added to favourites successfully.",
                ProductName = product.Name,
                ClientName = client.Full_Name
            });
        }

        [HttpGet("my-favourites")]
        public async Task<IActionResult> GetMyFavourites()
        {
            var clientSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (clientSSN == null)
                return Unauthorized(new { Message = "Invalid user." });

            // الرابط الأساسي للصور
            var baseUrl = $"{Request.Scheme}://{Request.Host}/"; 

            var favourites = await _context.Favourites
                .Where(f => f.SSN == clientSSN)
                .Include(f => f.Product)
                .ThenInclude(p => p.ProductImages) // جلب الصور المرتبطة بالمنتج
                .Select(f => new
                {
                    f.FavouriteId,
                    ProductID = f.Product!.Product_ID,
                    ProductName = f.Product!.Name,
                    f.Product.Description,
                    f.Product.Price,
                    f.Product.Rating_Average,
                    ProductImage = f.Product.ProductImages!
                        .Select(i => $"{baseUrl}{i.Images.TrimStart('/')}")
                        .ToList(),
                    f.CreatedAt
                })
                .ToListAsync();

            return Ok(favourites);
        }

        // ✅ حذف منتج من المفضلة
        [HttpDelete("remove/{productId}")]
        public async Task<IActionResult> RemoveFromFavourites(int productId)
        {
            var clientSSN = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (clientSSN == null)
                return Unauthorized(new { Message = "Invalid user." });

            var favourite = await _context.Favourites
                .FirstOrDefaultAsync(f => f.SSN == clientSSN && f.Product_ID == productId);

            if (favourite == null)
                return NotFound(new { Message = "Product not found in your favourites." });

            _context.Favourites.Remove(favourite);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Product removed from favourites." });
        }
    }

    // ✅ نموذج إضافة منتج للمفضلة
    public class AddToFavouriteRequest
    {
        public int Product_ID { get; set; }
    }
}
