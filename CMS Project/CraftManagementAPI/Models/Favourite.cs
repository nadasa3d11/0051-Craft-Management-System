using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CraftManagementAPI.Models
{
    public class Favourite
    {
        [Key]
        public int FavouriteId { get; set; }

        [Required]
        [ForeignKey("User")]
        public string SSN { get; set; } = null!;

        [Required]
        [ForeignKey("Product")]
        public int Product_ID { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public User? User { get; set; }
        public Product? Product { get; set; }
    }
}
