using CraftManagementAPI.Data;

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CraftManagementAPI.Models
{
    public class Product
    {
        [Key]
        public int Product_ID { get; set; }

        public DateTime Add_Date { get; set; } = DateTime.Now;

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }


        public double Rating_Average { get; set; } = 0;

        [Required]
        public int Quantity { get; set; }

        [Required]
        [MaxLength(20)]
        public string Status { get; set; } = null!;

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = null!;

        public string? Description { get; set; }

        // العلاقات
        public int? Cat_ID { get; set; }
        public Category? Category { get; set; }

        public string? User_SSN { get; set; }
        public User? User { get; set; }

        public ICollection<ProductImage>? ProductImages { get; set; }
        public ICollection<OrderItem>? OrderItems { get; set; }
        public ICollection<ProductRate>? ProductRates { get; set; }
        public ICollection<DeleteProduct>? DeletedProducts { get; set; }
        public ICollection<Cart>? Carts { get; set; } // علاقة One-to-Many مع Cart
        public ICollection<Favourite>? Favourites { get; set; }
       

    }
}
