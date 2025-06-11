using CraftManagementAPI.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CraftManagementAPI.Models
{
    public class Order
    {
        [Key]
        public int Order_ID { get; set; }

        public DateTime? Arrived_Date { get; set; } = DateTime.Now;
        public DateTime Order_Date { get; set; } = DateTime.Now;

        [Required]
        public OrderStatus Order_Status { get; set; } = OrderStatus.Pending;

        [Required]
        public PaymentMethod Payment_Method { get; set; }

        [Required]
        public PaymentStatus Payment_Status { get; set; } = PaymentStatus.NotPaid;

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Order_Price { get; set; } // السعر الإجمالي للطلب

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Total_Amount { get; set; } // المبلغ الكلي بعد إضافة الشحن والخصومات

        [Required]
        [MaxLength(255)]
        public string Receive_Address { get; set; } = null!;

        [Required]
        [MaxLength(50)]
        public string Zip_Code { get; set; } = null!; // الرمز البريدي

        [Required]
        [MaxLength(100)]
        public string Full_Name { get; set; } = null!; // الاسم الكامل للمستلم

        [Required]
        [MaxLength(15)]
        public string Phone_Number { get; set; } = null!; // رقم الهاتف

        [MaxLength(100)]
        public string? Payment_Reference { get; set; } // مرجع الدفع (Transaction ID من PayPal أو فودافون كاش)

        [Required]
        public ShippingMethod Shipping_Method { get; set; } = ShippingMethod.Free;

        [Required]
        public decimal Shipping_Cost { get; set; } = 0.00m;

        public string? User_SSN { get; set; }
        public User? User { get; set; }

        // ✅ علاقة One-to-One مع ConfirmationCode
        public ConfirmationCode? ConfirmationCode { get; set; }
        public ICollection<OrderItem>? OrderItems { get; set; }
    }

}
