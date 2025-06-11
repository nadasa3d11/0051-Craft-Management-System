namespace CraftManagementAPI.Enums
{
    public enum OrderStatus
    {
        Pending,
        Processing,
        Shipped,
        Delivered,
        Complete,
        Cancelled
    }

    public enum PaymentMethod
    {
        PayPal,
        Paymob, // (Vodafone Cash, etc.)
        Cash
    }

    public enum PaymentStatus
    {
        Paid,
        NotPaid
    }

    public enum ShippingMethod
    {
        Free,
        HomeDelivery,
        FastDelivery
    }

    public enum ComplaintStatus
    {
        New,
        UnderReview,
        Resolved
    }

}
