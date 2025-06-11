class CartItem {
  final int cartId;
  final int productId;
  final double productPrice;
  final String productName;
  final String artisanName;
  final int quantity;
  final String addedDate;
  final double productAverage;
  final List<String> productImages;

  CartItem({
    required this.cartId,
    required this.productId,
    required this.productPrice,
    required this.productName,
    required this.artisanName,
    required this.quantity,
    required this.addedDate,
    required this.productAverage,
    required this.productImages,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartId: json['Cart_ID'] ?? 0,
      productId: json['Productid'] ?? 0,
      productPrice: (json['ProductPrice'] ?? 0).toDouble(),
      productName: json['ProductName'] ?? '',
      artisanName: json['ArtisanName'] ?? '',
      quantity: json['Quantity'] ?? 0,
      addedDate: json['Added_Date'] ?? '',
      productAverage: (json['Product_Avarge'] ?? 0).toDouble(),
      productImages: List<String>.from(json['ProductImages'] ?? []),
    );
  }
}