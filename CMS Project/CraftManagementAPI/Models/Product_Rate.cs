using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CraftManagementAPI.Data;

namespace CraftManagementAPI.Models
{
    public class ProductRate
    {
        public string SSN_Client { get; set; } = null!;
        public User? Client { get; set; }

        public int Product_ID { get; set; }
        public Product? Product { get; set; }

        [Required]
        [Range(1, 5)]
        public int Product_Rate { get; set; }

        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
