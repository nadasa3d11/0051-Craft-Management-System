part of 'product_model.dart';



ProductModelInFilter _$ProductModelInFilterFromJson(
  Map<String, dynamic> json,
) => ProductModelInFilter(
  productId: (json['Product_ID'] as num).toInt(),
  name: json['Name'] as String?,
  price: (json['Price'] as num?)?.toDouble(),
  quantity: (json['Quantity'] as num?)?.toInt(),
  status: json['Status'] as String?,
  category: json['Category'] as String?,
  ratingAverage: (json['Rating_Average'] as num?)?.toDouble(),
  productImage:
      (json['ProductImage'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
);

Map<String, dynamic> _$ProductModelInFilterToJson(
  ProductModelInFilter instance,
) => <String, dynamic>{
  'Product_ID': instance.productId,
  'Name': instance.name,
  'Price': instance.price,
  'Quantity': instance.quantity,
  'Status': instance.status,
  'Category': instance.category,
  'Rating_Average': instance.ratingAverage,
  'ProductImage': instance.productImage,
};
