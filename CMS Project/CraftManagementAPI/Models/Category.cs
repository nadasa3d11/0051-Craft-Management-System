using CraftManagementAPI.Data;

using System.ComponentModel.DataAnnotations;

namespace CraftManagementAPI.Models
{
    public class Category
    {
        [Key]
        public int Cat_ID { get; set; }

        [Required]
        [MaxLength(30)]
        public string Cat_Type { get; set; } = null!;

        // العلاقة مع المنتجات
        public ICollection<Product>? Products { get; set; }
    }
}
