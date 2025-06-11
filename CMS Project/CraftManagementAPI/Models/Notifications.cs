using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CraftManagementAPI.Models
{
    public class Notification
    {
        [Key]
        public int NotificationId { get; set; }

        [Required]
        [ForeignKey("User")]
        public string SSN { get; set; } = null!;

        [Required]
        [MaxLength(200)]
        public string Message { get; set; } = null!;

        [Required]
        [MaxLength(50)]
        public string NotificationType { get; set; } = null!;
        public bool IsRead { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public User? User { get; set; }
        public string? SenderSSN { get; set; } = null!; // 🆕 الحقل الجديد
        [ForeignKey("SenderSSN")]
        public User? SenderUser { get; set; }

    }
}
