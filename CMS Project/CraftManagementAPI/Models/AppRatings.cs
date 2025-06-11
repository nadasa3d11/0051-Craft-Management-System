using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CraftManagementAPI.Models
{
    public class AppRating
    {
        [Key]
        public int RatingId { get; set; }

        [Required]
        [ForeignKey("User")]
        public string SSN { get; set; } = null!;

        [Required]
        [Range(1, 5)]
        public int Rating { get; set; } // 1 to 5 stars

        [MaxLength(300)]
        public string? Comment { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public User? User { get; set; }
    }
}
