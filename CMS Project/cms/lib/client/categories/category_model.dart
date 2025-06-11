import 'dart:convert';

class Category {
  final int catId;
  final String catType;
  final int productCount;
  final String? firstProductImage;

  Category({
    required this.catId,
    required this.catType,
    required this.productCount,
    this.firstProductImage,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      catId: json['Cat_ID'] as int,
      catType: json['Cat_Type'] as String,
      productCount: json['ProductCount'] as int,
      firstProductImage: json['FirstProductImage'] as String?,
    );
  }

  static List<Category> fromJsonList(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Category.fromJson(json)).toList();
  }
}