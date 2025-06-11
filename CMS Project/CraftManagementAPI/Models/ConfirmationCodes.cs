using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CraftManagementAPI.Models
{
    public class ConfirmationCode
    {
        [Key]
        public int Code_ID { get; set; }

        [Required]
        [ForeignKey("Order")]
        public int Order_ID { get; set; }

        [Required]
        [MaxLength(10)]
        public string Code { get; set; } = null!;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public Order? Order { get; set; }
    }
}
