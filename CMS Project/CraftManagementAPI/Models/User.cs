
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CraftManagementAPI.Data;

namespace CraftManagementAPI.Models
{
    public class User
    {
        [Key]
        public string SSN { get; set; } = null!;

        [Required]
        [MaxLength(20)]
        public string Role { get; set; } = null!;

        [Required]
        [MaxLength(15)]
        public string Phone { get; set; } = null!;

        public string? SSN_Image { get; set; }

        [Required]
        [MaxLength(100)]
        public string Full_Name { get; set; } = null!;

        public DateTime? Birth_Date { get; set; }

        [MaxLength(10)]
        public string? Gender { get; set; }

        [Required]
        [MaxLength(100)]
        public string Password { get; set; } = null!;

        [MaxLength(255)]
        public string? Address { get; set; }

        public string? Image { get; set; }

        public bool Active { get; set; } = true;

        public double Rating_Average { get; set; } = 0;

        // العلاقات
        public ICollection<Product>? Products { get; set; }
        public ICollection<Order>? Orders { get; set; }
        public ICollection<UserRate>? ArtisanRates { get; set; } // التقييمات من الحرفيين
        public ICollection<UserRate>? ClientRates { get; set; }   // التقييمات من العملاء
        public ICollection<ProductRate>? ProductRates { get; set; }
        public ICollection<DeleteProduct>? DeletedProducts { get; set; }
        public ICollection<Cart>? Carts { get; set; } // علاقة One-to-Many مع Cart
        public ICollection<Favourite>? Favourites { get; set; }
        // العلاقة مع الشكاوى
        public ICollection<Complaint> Complaints { get; set; } = new List<Complaint>();
        public ICollection<Notification>? Notifications { get; set; }
        public ICollection<AppRating>? AppRatings { get; set; }

    }
}
