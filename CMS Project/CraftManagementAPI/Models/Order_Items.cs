using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CraftManagementAPI.Models
{
    public class OrderItem
    {
        public int Product_ID { get; set; }
        public Product? Product { get; set; }

        public int Order_ID { get; set; }
        public Order? Order { get; set; }

        [Required]
        public int Quantity { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Total_Price { get; set; }

    }
}
