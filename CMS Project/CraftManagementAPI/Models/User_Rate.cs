using CraftManagementAPI.Data;

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CraftManagementAPI.Models
{
    public class UserRate
    {
        public string SSN_Client { get; set; } = null!;
        public User? Client { get; set; }

        public string SSN_Artisan { get; set; } = null!;
        public User? Artisan { get; set; }

        [Required]
        [Range(1, 5)]
        public int Artisan_Rate { get; set; }

        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
