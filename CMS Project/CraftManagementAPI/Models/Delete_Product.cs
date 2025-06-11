using System.ComponentModel.DataAnnotations;
using CraftManagementAPI.Data;

namespace CraftManagementAPI.Models
{
    public class DeleteProduct
    {
        public string SSN { get; set; } = null!;
        public User? User { get; set; }

        public int Product_ID { get; set; }
        public Product? Product { get; set; }

        public DateTime Delete_Date { get; set; } = DateTime.Now;
    }
}
