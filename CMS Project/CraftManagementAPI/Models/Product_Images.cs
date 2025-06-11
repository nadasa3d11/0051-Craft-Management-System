using System.ComponentModel.DataAnnotations;
using CraftManagementAPI.Data;

namespace CraftManagementAPI.Models
{
    public class ProductImage
    {
       
        public int Product_ID { get; set; }
        public Product? Product { get; set; }

        [Required]
        public string Images { get; set; } = null!;
    }
}
