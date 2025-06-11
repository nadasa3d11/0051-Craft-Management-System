using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CraftManagementAPI.Enums;

namespace CraftManagementAPI.Models
{
    public class Complaint
    {
        [Key]
        public int ComplaintId { get; set; }

        [Required]
        [ForeignKey("User")]
        public string SSN { get; set; } = null!;

        [Required]
        [MaxLength(100)]
        public string Problem { get; set; } = null!; // محتوى الشكوى

        [Required]
        [MaxLength(15)]
        public string PhoneNumber { get; set; } = null!;

        [MaxLength(500)]
        public string? Response { get; set; } // الرد على الشكوى (Admin)

        public DateTime ProblemDate { get; set; } = DateTime.UtcNow; // تاريخ إرسال الشكوى

        public DateTime? ResponseDate { get; set; } // تاريخ الرد على الشكوى

        [Required]
        public ComplaintStatus ProblemStatus { get; set; } = ComplaintStatus.New; // New, UnderReview, Resolved

        [Required]
        [MaxLength(100)]
        public string Complainer { get; set; } = null!; // اسم مقدم الشكوى

        // العلاقة مع جدول Users
        [InverseProperty("Complaints")]
        public User? User { get; set; }
    }
}
