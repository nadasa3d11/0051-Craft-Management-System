using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CraftManagementAPI.Models;

namespace CraftManagementAPI.Models
{
    public class Cart
    {
        [Key]
        public int Cart_ID { get; set; }

        [Required]
        public string User_SSN { get; set; } = null!;
        public User? User { get; set; }

        [Required]
        public int Product_ID { get; set; }
        public Product? Product { get; set; }

        [Required]
        public int Quantity { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }

        public DateTime Added_Date { get; set; } = DateTime.Now;
    }
}
