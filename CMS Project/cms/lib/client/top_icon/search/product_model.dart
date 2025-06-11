import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModelInFilter {
  @JsonKey(name: 'Product_ID')
  final int productId;

  @JsonKey(name: 'Name')
  final String? name;

  @JsonKey(name: 'Price')
  final double? price;

  @JsonKey(name: 'Quantity')
  final int? quantity;

  @JsonKey(name: 'Status')
  final String? status;

  @JsonKey(name: 'Category')
  final String? category;

  @JsonKey(name: 'Rating_Average')
  final double? ratingAverage;

  @JsonKey(name: 'ProductImage')
  final List<String>? productImage;

  ProductModelInFilter({
    required this.productId,
    this.name,
    this.price,
    this.quantity,
    this.status,
    this.category,
    this.ratingAverage,
    this.productImage,
  });

  factory ProductModelInFilter.fromJson(Map<String, dynamic> json) =>
      _$ProductModelInFilterFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelInFilterToJson(this);
}