import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:herfa/client/my_card/cart_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Rating {
  final int ratingId;
  final double artisanRate;
  final String? comment;
  final String? userName;
  final String? clientImage;
  final DateTime? createdAt;

  Rating({
    required this.ratingId,
    required this.artisanRate,
    this.comment,
    this.userName,
    this.clientImage,
    this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      ratingId: json['RatingID'] ?? 0,
      artisanRate: (json['Product_Rate'] is int
              ? json['Product_Rate'].toDouble()
              : json['Product_Rate']) ??
          0.0,
      comment: json['Comment'],
      userName: json['UserName'] ?? json['ClientName'],
      clientImage: json['ClientImage'],
      createdAt:
          json['CreatedAt'] != null ? DateTime.parse(json['CreatedAt']) : null,
    );
  }
}

// Notification Model
class NotificationModel {
  final int notificationId;
  final String senderName;
  final String? profileImage;
  final String message;
  late final bool isRead;
  final DateTime createdAt;
  final String notificationType;

  NotificationModel({
    required this.notificationId,
    required this.senderName,
    this.profileImage,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.notificationType,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['NotificationId'] ?? 0,
      senderName: json['SenderName'] ?? 'System',
      profileImage: json['ProfileImage'],
      message: json['Message'] ?? '',
      isRead: json['IsRead'] ?? false,
      createdAt: json['CreatedAt'] != null
          ? DateTime.parse(json['CreatedAt'])
          : DateTime.now(),
      notificationType: json['NotificationType'] ?? '',
    );
  }
}

// Artisan Model
class Artisan {
  final String ssn;
  final String fullName;
  final String? profileImage;
  final double? ratingAverage;
  final List<Product>? products;

  Artisan({
    required this.ssn,
    required this.fullName,
    this.profileImage,
    this.ratingAverage,
    this.products,
  });

  factory Artisan.fromJson(Map<String, dynamic> json) {
  try {
    final ssn = json['SSN']?.toString() ?? json['ssn']?.toString() ?? '';
    final fullName = json['FullName']?.toString() ??
        json['fullName']?.toString() ??
        json['Full_Name']?.toString() ??
        '';
    final profileImage = json['ProfileImage']?.toString() ?? json['profileImage']?.toString() ?? '';
    print('Parsing Artisan JSON: SSN: "$ssn", FullName: "$fullName", ProfileImage: "$profileImage"');

    return Artisan(
      ssn: ssn,
      fullName: fullName,
      profileImage: profileImage,
      ratingAverage: json['RatingAverage'] is int
          ? json['RatingAverage'].toDouble()
          : json['RatingAverage'] as double?,
      products: json['Products'] != null
          ? (json['Products'] as List<dynamic>)
              .map((item) => Product.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  } catch (e) {
    print('Error parsing Artisan JSON: $e, JSON: $json');
    rethrow;
  }
}
}

// Category Model
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
}

// Product Model
class Product {
  final int productId;
  final String name;
  final String description;
  final double price;
  final List<String> images;
  final int? quantity;
  final String? category;
  final double? ratingAverage;
  final String? status;
  final Artisan? artisan;
  final int? favouriteId;
  final String? createdAt;

  Product({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    this.quantity,
    this.category,
    this.ratingAverage,
    this.status,
    this.artisan,
    this.favouriteId,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      return Product(
        productId: json['ProductID'] ?? json['Product_ID'] ?? 0,
        name: json['ProductName'] ?? json['Name'] ?? '',
        description: json['Description'] ?? '',
        price:
            (json['Price'] is int ? json['Price'].toDouble() : json['Price']) ??
                0.0,
        images: List<String>.from(json['Images'] ??
            json['ProductImages'] ??
            json['ProductImage'] ??
            []),
        quantity: json['Quantity'],
        category: json['Category'],
        ratingAverage: json['Rating_Average'] is int
            ? json['Rating_Average'].toDouble()
            : json['Rating_Average'],
        status: json['Status'] ?? json['status'],
        artisan:
            json['Artisan'] != null ? Artisan.fromJson(json['Artisan']) : null,
        favouriteId: json['FavouriteId'],
        createdAt: json['CreatedAt'],
      );
    } catch (e) {
      debugPrint('Error parsing Product JSON: $e, JSON: $json');
      rethrow;
    }
  }
}

// ProductModelInFilter Model
class ProductModelInFilter {
  final int productId;
  final String? name;
  final double? price;
  final int? quantity;
  final String? status;
  final String? category;
  final double? ratingAverage;
  final String? description;
  final List<String> productImage;

  ProductModelInFilter({
    required this.productId,
    this.name,
    this.price,
    this.quantity,
    this.status,
    this.category,
    this.ratingAverage,
    this.description,
    this.productImage = const [],
  });

  factory ProductModelInFilter.fromJson(Map<String, dynamic> json) {
    return ProductModelInFilter(
      productId: json['Product_ID'] ?? 0,
      name: json['Name'] as String?,
      price: (json['Price'] as num?)?.toDouble(),
      quantity: json['Quantity'] as int?,
      status: json['Status'] as String?,
      category: json['Category'] as String?,
      ratingAverage: (json['Rating_Average'] as num?)?.toDouble(),
      description: json['Description'] as String?,
      productImage: json['ProductImage'] != null
          ? List<String>.from(json['ProductImage'] as List)
          : (json['Images'] != null
              ? List<String>.from(json['Images'] as List)
              : []),
    );
  }
}

// OrderProduct Model
class OrderProduct {
  final int productId;
  final String productName;
  final String artisanName;
  final int quantity;
  final double totalPrice;

  OrderProduct({
    required this.productId,
    required this.productName,
    required this.artisanName,
    required this.quantity,
    required this.totalPrice,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      productId: json['Product_ID'] ?? 0,
      productName: json['Product_Name'] ?? '',
      artisanName: json['Artisan_Name'] ?? '',
      quantity: json['Quantity'] ?? 0,
      totalPrice: (json['Total_Price'] is int
              ? json['Total_Price'].toDouble()
              : json['Total_Price']) ??
          0.0,
    );
  }
}

// Order Model
class Order {
  final int orderId;
  final String orderStatus;
  final DateTime orderDate;
  final DateTime? arrivedDate;
  final String? shippingMethod;
  final double? orderPrice;
  final double? shippingCost;
  final double? totalAmount;
  final List<OrderProduct>? products;
  final String? conformCode;

  Order({
    required this.orderId,
    required this.orderStatus,
    required this.orderDate,
    this.arrivedDate,
    this.shippingMethod,
    this.orderPrice,
    this.shippingCost,
    this.totalAmount,
    this.products,
    this.conformCode,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['Order_ID'] ?? 0,
      orderStatus: json['Order_Status'] ?? '',
      orderDate: json['Order_Date'] != null
          ? DateTime.parse(json['Order_Date'])
          : DateTime.now(),
      arrivedDate: json['Arrived_Date'] != null
          ? DateTime.parse(json['Arrived_Date'])
          : null,
      shippingMethod: json['Shipping_Method'],
      orderPrice: (json['Order_Price'] is int
              ? json['Order_Price'].toDouble()
              : json['Order_Price']) ??
          0.0,
      shippingCost: (json['Shipping_Cost'] is int
              ? json['Shipping_Cost'].toDouble()
              : json['Shipping_Cost']) ??
          0.0,
      totalAmount: (json['Total_Amount'] is int
              ? json['Total_Amount'].toDouble()
              : json['Total_Amount']) ??
          0.0,
      products: json['Products'] != null
          ? (json['Products'] as List)
              .map((item) => OrderProduct.fromJson(item))
              .toList()
          : null,
      conformCode: json['Conform_Code'],
    );
  }
}

class AuthService {
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('AccessToken', accessToken);
    await prefs.setString('RefreshToken', refreshToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('AccessToken');
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('RefreshToken');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('AccessToken');
    await prefs.remove('RefreshToken');
  }

  Future<void> saveUserData({
    required String fullName,
    required String role,
    required String imageUrl,
    String? phone,
    String? address,
    String? gender,
    String? birthDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('full_name', fullName);
    await prefs.setString('role', role);
    await prefs.setString('image_url', imageUrl);
    if (phone != null) await prefs.setString('phone', phone);
    if (address != null) await prefs.setString('address', address);
    if (gender != null) await prefs.setString('gender', gender);
    if (birthDate != null) await prefs.setString('birth_date', birthDate);
    debugPrint(
        'User data saved: full_name=$fullName, role=$role, image_url=$imageUrl, phone=$phone, address=$address, gender=$gender, birth_date=$birthDate');
  }

  Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'full_name': prefs.getString('full_name') ?? '',
      'role': prefs.getString('role') ?? '',
      'image_url': prefs.getString('image_url') ?? '',
      'phone': prefs.getString('phone') ?? '',
      'address': prefs.getString('address') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'birth_date': prefs.getString('birth_date') ?? '',
    };
    debugPrint('User data retrieved: $userData');
    return userData;
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('full_name');
    await prefs.remove('role');
    await prefs.remove('image_url');
    await prefs.remove('phone');
    await prefs.remove('address');
    await prefs.remove('gender');
    await prefs.remove('birth_date');
    debugPrint('Tokens and user data cleared');
  }
}

class ApiService {
  final String BaseUrl = "https://herfa-system-handmade.runasp.net";
  static const String baseUrl = "https://herfa-system-handmade.runasp.net/api";
  final String authUrl = "$baseUrl/Auth";
  final String userUrl = "$baseUrl/User";
  final String homeUrl = "$baseUrl/Home";
  final String cartUrl = "$baseUrl/cart";
  final String orderUrl = "$baseUrl/OrderForArtisan";
  final String ordersUrl = "$baseUrl/Order";
  final String ratingUrl = "$baseUrl/Rating/artisan_ratings";
  final String categoryUrl = "$baseUrl/Category";
  final String favouriteUrl = "$baseUrl/Favourite";
  final String artisanUrl = "$baseUrl/Artisan";
  final String productRatingUrl = "$baseUrl/ProductRating";

  static const List<String> validCategories = [
    'Accessories',
    'Bags',
    'Clothes',
    'Wood',
    'Flowers',
    'Mobile Cover',
    'Decor',
    'Pottery',
    'Blacksmith',
    'Textiles',
  ];

  Future<Map<String, dynamic>> loginUser(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$BaseUrl/api/Auth/login"),
        body: jsonEncode({"phone": phone, "password": password}),
        headers: {"Content-Type": "application/json"},
      );

      print("🔍 Status Code: ${response.statusCode}");
      print("🔍 Raw API Response: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await AuthService()
            .saveTokens(data["AccessToken"], data["RefreshToken"]);
        return data;
      } else {
        String errorMessage =
            data["Message"] ?? data["error"] ?? "Login failed";
        return {"Message": errorMessage};
      }
    } catch (e) {
      print("❌ API Error: $e");
      return {"error": "Login failed due to network or server error"};
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String phone,
    required String birthDate,
    required String ssn,
    required String gender,
    required String password,
    required String address,
    required File idCardImage,
    required String role,
  }) async {
    final url = Uri.parse("$BaseUrl/api/Auth/register-with-image");

    try {
      var request = http.MultipartRequest("POST", url);
      request.fields["Full_Name"] = fullName;
      request.fields["Phone"] = phone;
      request.fields["Birth_Date"] = birthDate;
      request.fields["SSN"] = ssn;
      request.fields["Role"] = role;
      request.fields["Gender"] = gender;
      request.fields["Password"] = password;
      request.fields["Address"] = address;

      request.files
          .add(await http.MultipartFile.fromPath("file", idCardImage.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Error: $e"};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String phone) async {
    try {
      final url = Uri.parse("$BaseUrl/api/Auth/forgot-password");
      final body = jsonEncode({
        "Phone": phone,
      });

      print("ForgotPassword Request: Sending to $url with body: $body");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print("ForgotPassword Response status: ${response.statusCode}");
      print("ForgotPassword Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final responseData = jsonDecode(response.body);
        return {
          "error": responseData["message"] ??
              "Failed to send verification code: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("ForgotPassword Error: $e");
      return {"error": "Failed to send verification code: $e"};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String phone, String ssn, String newPassword) async {
    try {
      final url = Uri.parse("$BaseUrl/api/Auth/reset-password");
      final body = jsonEncode({
        "Phone": phone,
        "SSN": ssn,
        "NewPassword": newPassword,
      });

      print("ResetPassword Request: Sending to $url with body: $body");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print("ResetPassword Response status: ${response.statusCode}");
      print("ResetPassword Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {"message": "Password reset successfully"};
      } else {
        final responseData = jsonDecode(response.body);
        return {
          "error": responseData["message"] ??
              "Failed to reset password: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("ResetPassword Error: $e");
      return {"error": "Failed to reset password: $e"};
    }
  }

  Future<Map<String, dynamic>> changePassword(
      String oldPassword, String newPassword) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        print('Change Password Error: No auth token found');
        return {'error': 'Authentication required. Please log in again.'};
      }

      final url = Uri.parse('$BaseUrl/api/Auth/change-password');
      final body = jsonEncode({
        'OldPassword': oldPassword,
        'NewPassword': newPassword,
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print('Change Password Request: URL: $url, Body: $body');
      print(
          'Change Password Response: Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          'message': responseBody['Message'] ?? 'Password changed successfully',
        };
      } else {
        final responseBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        String errorMessage;
        switch (response.statusCode) {
          case 401:
            errorMessage = responseBody['Message'] ??
                'Unauthorized: Invalid old password or authentication token';
            break;
          case 400:
            errorMessage =
                responseBody['Message'] ?? 'Bad request: Check your input';
            break;
          default:
            errorMessage = responseBody['Message'] ??
                'Failed to change password: ${response.statusCode}';
        }
        print('Change Password Error: $errorMessage');
        return {'error': errorMessage};
      }
    } catch (e) {
      print('Change Password Exception: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getProducts() async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Artisan/my-products");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache',
        },
      );

      print("GetProducts Response status: ${response.statusCode}");
      print("GetProducts Response body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Failed to load products: ${response.statusCode}"};
      }
    } catch (e) {
      print("GetProducts Error: $e");
      return {"error": "Failed to load products: $e"};
    }
  }

  Future<Map<String, dynamic>> getMyInformation() async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/User/my-profile");
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      print("GetMyInformation Response status: ${response.statusCode}");
      print("GetMyInformation Response body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "error": "Failed to load user information: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("GetMyInformation Error: $e");
      return {"error": "Failed to load user information: $e"};
    }
  }

  Future<Map<String, dynamic>> updateMyInformation({
    required String fullName,
    required String phone,
    required String birthDate,
    required String gender,
    required String address,
    File? image,
  }) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/User/update-profile");
      var request = http.MultipartRequest("PUT", url);

      request.fields["Full_Name"] = fullName;
      request.fields["Phone"] = phone;
      request.fields["Birth_Date"] = birthDate;
      request.fields["Gender"] = gender;
      request.fields["Address"] = address;

      if (image != null) {
        print("Uploading image: ${image.path}");
        request.files.add(
          await http.MultipartFile.fromPath(
            "Image",
            image.path,
            filename: "profile_image.jpg",
          ),
        );
      } else {
        print("No image provided for upload");
      }

      request.headers['Authorization'] = 'Bearer $token';

      print(
          "UpdateMyInformation Request: Sending to $url with ${image != null ? 1 : 0} image");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("UpdateMyInformation Response status: ${response.statusCode}");
      print("UpdateMyInformation Response body: ${response.body}");

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        print(
            "ImageUrl in response: ${responseData['User']?['ImageUrl'] ?? 'null'}");
        return responseData.isEmpty
            ? {"message": "Profile updated successfully"}
            : responseData;
      } else {
        return {
          "error": responseData["message"] ??
              "Failed to update profile: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("UpdateMyInformation Error: $e");
      return {"error": "Failed to update profile: $e"};
    }
  }

  Future<Map<String, dynamic>> addProduct({
    required String name,
    required double price,
    required int quantity,
    required String description,
    required List<File> images,
    required String catType,
  }) async {
    if (!validCategories.contains(catType)) {
      return {
        "error":
            "Invalid category type. Must be one of: ${validCategories.join(', ')}"
      };
    }

    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Product/add");
      var request = http.MultipartRequest("POST", url);

      request.fields["Name"] = name;
      request.fields["Price"] = price.toString();
      request.fields["Quantity"] = quantity.toString();
      request.fields["Description"] = description;
      request.fields["Cat_Type"] = catType;

      for (int i = 0; i < images.length; i++) {
        print("Uploading image: ${images[i].path}");
        request.files.add(
          await http.MultipartFile.fromPath(
            "Images",
            images[i].path,
            filename: "product_image_$i.jpg",
          ),
        );
      }

      request.headers['Authorization'] = 'Bearer $token';

      print("AddProduct Request: Sending to $url with ${images.length} images");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("AddProduct Response status: ${response.statusCode}");
      print("AddProduct Response body: ${response.body}");

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        return {
          "error": responseData["message"] ??
              "Failed to add product: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("AddProduct Error: $e");
      return {"error": "Failed to add product: $e"};
    }
  }

  Future<Map<String, dynamic>> editProduct({
  required String productId,
  required String name,
  required double price,
  required int quantity,
  required String description,
  required List<File> images,
  required List<String> existingImages,
  required String catType,
  required String status,
  required List<int> imagesToDelete, 
}) async {
  if (!validCategories.contains(catType)) {
    return {
      "error":
          "Invalid category type. Must be one of: ${validCategories.join(', ')}"
    };
  }

  if (!['Available', 'Not Available'].contains(status)) {
    return {
      "error": "Invalid status. Must be 'Available' or 'Not Available'"
    };
  }

  try {
    final String? token = await AuthService().getAccessToken();
    if (token == null) {
      return {"error": "User not logged in"};
    }

    final url = Uri.parse("$BaseUrl/api/Artisan/edit-product/$productId");
    var request = http.MultipartRequest("PUT", url);

    request.fields["ProductId"] = productId;
    request.fields["Name"] = name;
    request.fields["Price"] = price.toString();
    request.fields["Quantity"] = quantity.toString();
    request.fields["Description"] = description;
    request.fields["Cat_Type"] = catType;
    request.fields["Status"] = status;

    if (existingImages.isNotEmpty) {
      request.fields["ExistingImages"] = jsonEncode(existingImages);
    } else {
      print("No existing images to send");
    }

    if (imagesToDelete.isNotEmpty) {
      request.fields["ImagesToDelete"] = jsonEncode(imagesToDelete.map((i) => i.toString()).toList()); 
      print("Images to delete: ${imagesToDelete.map((i) => i.toString()).toList()}");
    } else {
      print("No images to delete");
    }

    for (int i = 0; i < images.length; i++) {
      print("Uploading new image: ${images[i].path}");
      request.files.add(
        await http.MultipartFile.fromPath(
          "productImages",
          images[i].path,
          filename: "product_image_$i.jpg",
        ),
      );
    }

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    print(
        "EditProduct Request: Sending to $url with ${images.length} new images, ${existingImages.length} existing images, and ${imagesToDelete.length} images to delete");
    print("Request fields: ${request.fields}");
    print(
        "Request files: ${request.files.map((file) => file.filename).toList()}");

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print("EditProduct Response status: ${response.statusCode}");
    print("EditProduct Response body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 204) {
      return response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {"message": "Product updated successfully"};
    } else {
      final responseData =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return {
        "error": responseData["message"] ??
            "Failed to edit product: ${response.statusCode}"
      };
    }
  } catch (e) {
    print("EditProduct Error: $e");
    return {"error": "Failed to edit product: $e"};
  }
}

  Future<Map<String, dynamic>> rateApp({
    required int rating,
    required String comment,
  }) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/AppRating/rate-app");
      final body = jsonEncode({
        "Rating": rating,
        "Comment": comment,
      });

      print("RateApp Request: Sending to $url with body: $body");

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print("RateApp Response status: ${response.statusCode}");
      print("RateApp Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Failed to submit rating: ${response.statusCode}"};
      }
    } catch (e) {
      print("RateApp Error: $e");
      return {"error": "Failed to submit rating: $e"};
    }
  }

  Future<Map<String, dynamic>> createComplaint({
    required String problem,
    required String phoneNumber,
    required String complainer,
  }) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Complaint/create-complaint");
      final body = jsonEncode({
        "Problem": problem,
        "PhoneNumber": phoneNumber,
        "Complainer": complainer,
      });

      print("CreateComplaint Request: Sending to $url with body: $body");

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print("CreateComplaint Response status: ${response.statusCode}");
      print("CreateComplaint Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final responseData = jsonDecode(response.body);
        return {
          "error": responseData["message"] ??
              "Failed to create complaint: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("CreateComplaint Error: $e");
      return {"error": "Failed to create complaint: $e"};
    }
  }

  Future<Map<String, dynamic>> getProductRatings(String productId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url =
          Uri.parse("$BaseUrl/api/ProductRating/Rating_product/$productId");
      print("GetProductRatings Request: Sending to $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("GetProductRatings Response status: ${response.statusCode}");
      print("GetProductRatings Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reviews = List<Map<String, dynamic>>.from(data["Reviews"] ?? []);

        double averageRating = 0.0;
        if (reviews.isNotEmpty) {
          double totalRating = reviews.fold(
              0.0,
              (sum, review) =>
                  sum + (review["Product_Rate"]?.toDouble() ?? 0.0));
          averageRating = totalRating / reviews.length;
        }

        return {
          "productId": productId,
          "productName": data["ProductName"] ?? "Unknown",
          "averageRating": averageRating,
          "ratingCount": reviews.length,
          "reviews": reviews,
        };
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["message"] ??
              "Failed to load product ratings: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("GetProductRatings Error: $e");
      return {"error": "Failed to load product ratings: $e"};
    }
  }

  Future<Map<String, dynamic>> getArtisanRatings(String artisanSSN) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Rating/artisan_ratings/$artisanSSN");
      print("GetArtisanRatings Request: Sending to $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("GetArtisanRatings Response status: ${response.statusCode}");
      print("GetArtisanRatings Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "artisanSSN": data["Artisan_SSN"]?.toString() ?? "Unknown",
          "artisanName": data["Artisan_Name"]?.toString() ?? "Unknown",
          "averageRating": (data["AverageRating"] as num?)?.toDouble() ?? 0.0,
          "totalRatings": data["TotalRatings"] as int? ?? 0,
          "ratings": List<Map<String, dynamic>>.from(data["Ratings"] ?? []),
        };
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["message"] ??
              "Failed to load artisan ratings: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("GetArtisanRatings Error: $e");
      return {"error": "Failed to load artisan ratings: $e"};
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return [
          {"error": "User not logged in"}
        ];
      }

      final url = Uri.parse("$BaseUrl/api/Category/all-with-products");
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      print("GetCategories Response status: ${response.statusCode}");
      print("GetCategories Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        return [
          {"error": "Failed to load categories: ${response.statusCode}"}
        ];
      }
    } catch (e) {
      print("GetCategories Error: $e");
      return [
        {"error": "Failed to load categories: $e"}
      ];
    }
  }

  Future<Map<String, dynamic>> addCategory({
    required String catType,
  }) async {
    try {
      if (validCategories.contains(catType)) {
        return {"error": "Category already exists: $catType"};
      }

      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Category/add");
      final body = jsonEncode({
        "Cat_Type": catType,
      });

      print("AddCategory Request: Sending to $url with body: $body");

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print("AddCategory Response status: ${response.statusCode}");
      print("AddCategory Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final responseData = jsonDecode(response.body);
        return {
          "error": responseData["message"] ??
              "Failed to add category: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("AddCategory Error: $e");
      return {"error": "Failed to add category: $e"};
    }
  }

  Future<Map<String, dynamic>> updateCategory({
    required String catType,
    required String newCatType,
  }) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Category/update/$catType");
      final body = jsonEncode({
        "Cat_Type": newCatType,
      });

      print("UpdateCategory Request: Sending to $url with body: $body");

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print("UpdateCategory Response status: ${response.statusCode}");
      print("UpdateCategory Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {"message": "Category updated successfully"};
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["message"] ??
              "Failed to update category: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("UpdateCategory Error: $e");
      return {"error": "Failed to update category: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteCategory({
    required String catType,
  }) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url =
          Uri.parse("$BaseUrl/api/Category/delete/$catType?catType=$catType");

      print("DeleteCategory Request: Sending to $url");

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("DeleteCategory Response status: ${response.statusCode}");
      print("DeleteCategory Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {"message": "Category deleted successfully"};
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["message"] ??
              "Failed to delete category: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("DeleteCategory Error: $e");
      return {"error": "Failed to delete category: $e"};
    }
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Admin/dashboard");
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      print("GetDashboardData Response status: ${response.statusCode}");
      print("GetDashboardData Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        return {
          "error": "Failed to load dashboard data: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("GetDashboardData Error: $e");
      return {"error": "Failed to load dashboard data: $e"};
    }
  }

  Future<List<Map<String, dynamic>>> getOrdersByStatus(String status) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return [
          {"error": "User not logged in"}
        ];
      }

      final url =
          Uri.parse("$BaseUrl/api/Order/Myorders-status?status=$status");
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      print("GetOrdersByStatus Response status: ${response.statusCode}");
      print("GetOrdersByStatus Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        return [
          {"error": "Failed to load orders: ${response.statusCode}"}
        ];
      }
    } catch (e) {
      print("GetOrdersByStatus Error: $e");
      return [
        {"error": "Failed to load orders: $e"}
      ];
    }
  }

  Future<Map<String, dynamic>> getConfirmCode(int orderId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url =
          Uri.parse("$BaseUrl/api/OrderForArtisan/get-confirm-code/$orderId");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("GetConfirmCode Response status: ${response.statusCode}");
      print("GetConfirmCode Response body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["Message"] ??
              "Failed to get confirm code: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("GetConfirmCode Error: $e");
      return {"error": "Failed to get confirm code: $e"};
    }
  }

  Future<Map<String, dynamic>> acceptOrder(int orderId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url =
          Uri.parse("$BaseUrl/api/OrderForArtisan/accept-order/$orderId");
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("AcceptOrder Response status: ${response.statusCode}");
      print("AcceptOrder Response body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["Message"] ??
              "Failed to accept order: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("AcceptOrder Error: $e");
      return {"error": "Failed to accept order: $e"};
    }
  }

  Future<Map<String, dynamic>> shipOrder(int orderId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/OrderForArtisan/ship-order/$orderId");
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("ShipOrder Response status: ${response.statusCode}");
      print("ShipOrder Response body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["Message"] ??
              "Failed to ship order: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("ShipOrder Error: $e");
      return {"error": "Failed to ship order: $e"};
    }
  }

  Future<Map<String, dynamic>> confirmDelivery(
      int orderId, String confirmCode) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url =
          Uri.parse("$BaseUrl/api/OrderForArtisan/confirm-delivery/$orderId");
      final body = jsonEncode(confirmCode);

      print("ConfirmDelivery Request: Sending to $url with body: $body");

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print("ConfirmDelivery Response status: ${response.statusCode}");
      print("ConfirmDelivery Response body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["Message"] ??
              "Failed to confirm delivery: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("ConfirmDelivery Error: $e");
      return {"error": "Failed to confirm delivery: $e"};
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url =
          Uri.parse("$BaseUrl/api/Order/order-details-Artisan/$orderId");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("GetOrderDetails Response status: ${response.statusCode}");
      print("GetOrderDetails Response body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["Message"] ??
              "Failed to load order details: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("GetOrderDetails Error: $e");
      return {"error": "Failed to load order details: $e"};
    }
  }

  Future<List<Map<String, dynamic>>> getAllArtisans() async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return [
          {"error": "User not logged in"}
        ];
      }

      final url = Uri.parse("$BaseUrl/api/Admin/get-all-artisans");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("GetAllArtisans Response status: ${response.statusCode}");
      print("GetAllArtisans Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return [
          {
            "error": responseData["message"] ??
                "Failed to load artisans: ${response.statusCode}"
          }
        ];
      }
    } catch (e) {
      print("GetAllArtisans Error: $e");
      return [
        {"error": "Failed to load artisans: $e"}
      ];
    }
  }

  Future<Map<String, dynamic>> updateArtisan({
    required String ssn,
    required String fullName,
    required String phone,
    required String address,
    required String birthDate, 
    required String gender,
  }) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Admin/update-artisan/$ssn");
      final body = jsonEncode({
        "Full_Name": fullName,
        "Phone": phone,
        "Address": address,
        "Birth_Date": birthDate, 
        "Gender": gender,
      });

      print("UpdateArtisan Request: Sending to $url with body: $body");

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print("UpdateArtisan Response status: ${response.statusCode}");
      print("UpdateArtisan Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {"message": "Artisan updated successfully"};
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["message"] ??
              "Failed to update artisan: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("UpdateArtisan Error: $e");
      return {"error": "Failed to update artisan: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteArtisan({
    required String ssn,
  }) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Admin/delete-artisan/$ssn");

      print("DeleteArtisan Request: Sending to $url");

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("DeleteArtisan Response status: ${response.statusCode}");
      print("DeleteArtisan Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {"message": "Artisan deleted successfully"};
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["message"] ??
              "Failed to delete artisan: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("DeleteArtisan Error: $e");
      return {"error": "Failed to delete artisan: $e"};
    }
  }

  Future<Map<String, dynamic>> toggleArtisan({
    required String ssn,
  }) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Admin/toggle-artisan-status/$ssn");

      print("ToggleArtisan Request: Sending to $url");

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("ToggleArtisan Response status: ${response.statusCode}");
      print("ToggleArtisan Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {"message": "Artisan status toggled successfully"};
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["message"] ??
              "Failed to toggle artisan status: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("ToggleArtisan Error: $e");
      return {"error": "Failed to toggle artisan status: $e"};
    }
  }

  Future<List<Map<String, dynamic>>> getAllClients() async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return [
          {"error": "User not logged in"}
        ];
      }

      final url = Uri.parse("$BaseUrl/api/Admin/get-all-clients");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("GetAllClients Response status: ${response.statusCode}");
      print("GetAllClients Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return [
          {
            "error": responseData["message"] ??
                "Failed to load clients: ${response.statusCode}"
          }
        ];
      }
    } catch (e) {
      print("GetAllClients Error: $e");
      return [
        {"error": "Failed to load clients: $e"}
      ];
    }
  }

  Future<Map<String, dynamic>> updateClient({
    required String ssn,
    required String fullName,
    required String phone,
    required String address,
    required DateTime birthDate,
    required String gender,
  }) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Admin/update-client/$ssn");
      final body = jsonEncode({
        "Full_Name": fullName,
        "Phone": phone,
        "Address": address,
        "Birth_Date": birthDate.toIso8601String(),
        "Gender": gender,
      });

      print("UpdateClient Request: Sending to $url with body: $body");

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print("UpdateClient Response status: ${response.statusCode}");
      print("UpdateClient Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {"message": "Client updated successfully"};
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["message"] ??
              "Failed to update client: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("UpdateClient Error: $e");
      return {"error": "Failed to update client: $e"};
    }
  }

  Future<Map<String, dynamic>> toggleClient(String ssn) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Admin/toggle-client-status/$ssn");

      print("ToggleClient Request: Sending to $url");

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("ToggleClient Response status: ${response.statusCode}");
      print("ToggleClient Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {"message": "Client status toggled successfully"};
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["message"] ??
              "Failed to toggle client status: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("ToggleClient Error: $e");
      return {"error": "Failed to toggle client status: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteClient({required String ssn}) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Admin/delete-client/$ssn");

      print("DeleteClient Request: Sending to $url");

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("DeleteClient Response status: ${response.statusCode}");
      print("DeleteClient Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {"message": "Client deleted successfully"};
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["message"] ??
              "Failed to delete client: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("DeleteClient Error: $e");
      return {"error": "Failed to delete client: $e"};
    }
  }

  Future<List<Map<String, dynamic>>> fetchComplaintsByStatus(
      String status) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return [
          {"error": "User not logged in"}
        ];
      }

      final url = Uri.parse("$BaseUrl/api/Complaint/filter?status=$status");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("FetchComplaintsByStatus Response status: ${response.statusCode}");
      print("FetchComplaintsByStatus Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        String errorMsg =
            'Failed to load $status complaints: ${response.statusCode}';
        if (response.body.contains("Invalid status filter")) {
          errorMsg = "Invalid status filter: '$status' is not a valid status.";
        } else {
          errorMsg += ", ${response.body}";
        }
        return [
          {"error": errorMsg}
        ];
      }
    } catch (e) {
      print("FetchComplaintsByStatus Error: $e");
      return [
        {"error": "Failed to load complaints: $e"}
      ];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllComplaints() async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return [
          {"error": "User not logged in"}
        ];
      }

      final url = Uri.parse("$BaseUrl/api/Complaint/all-complaints");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("FetchAllComplaints Response status: ${response.statusCode}");
      print("FetchAllComplaints Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        return [
          {
            "error":
                "Failed to load all complaints: ${response.statusCode}, ${response.body}"
          }
        ];
      }
    } catch (e) {
      print("FetchAllComplaints Error: $e");
      return [
        {"error": "Failed to load all complaints: $e"}
      ];
    }
  }

  Future<Map<String, dynamic>> fetchComplaintDetails(int complaintId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Complaint/details/$complaintId");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("FetchComplaintDetails Response status: ${response.statusCode}");
      print("FetchComplaintDetails Response body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "error":
              "Failed to load complaint details: ${response.statusCode}, ${response.body}"
        };
      }
    } catch (e) {
      print("FetchComplaintDetails Error: $e");
      return {"error": "Failed to load complaint details: $e"};
    }
  }

  Future<Map<String, dynamic>> sendSolution(
      int complaintId, String solution) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Complaint/respond/$complaintId");
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Response': solution,
        }),
      );

      print("SendSolution Response status: ${response.statusCode}");
      print("SendSolution Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {"message": "Solution sent successfully"};
      } else {
        return {
          "error":
              "Failed to send solution: ${response.statusCode}, ${response.body}"
        };
      }
    } catch (e) {
      print("SendSolution Error: $e");
      return {"error": "Failed to send solution: $e"};
    }
  }

  Future<Map<String, dynamic>> getArtisanProfile(String ssn) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse("$BaseUrl/api/Artisan/artisan/$ssn");
      print("GetArtisanProfile Request: Sending to $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("GetArtisanProfile Response status: ${response.statusCode}");
      print("GetArtisanProfile Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "fullName": data["FullName"]?.toString() ?? "Unknown",
          "profileImage": data["ProfileImage"]?.toString() ?? "",
          "ratingAverage": (data["RatingAverage"] as num?)?.toDouble() ?? 0.0,
          "products": List<Map<String, dynamic>>.from(data["Products"] ?? []),
        };
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["message"] ??
              "Failed to load artisan profile: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("GetArtisanProfile Error: $e");
      return {"error": "Failed to load artisan profile: $e"};
    }
  }

  Future<Map<String, dynamic>> getProductDetails(int productId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      final url = Uri.parse(
          "$BaseUrl/api/Home/product/$productId?productId=$productId");
      print("GetProductDetails Request: Sending to $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("GetProductDetails Response status: ${response.statusCode}");
      print("GetProductDetails Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "productId": data["Product_ID"] as int? ?? 0,
          "name": data["Name"]?.toString() ?? "Unknown",
          "price": (data["Price"] as num?)?.toDouble() ?? 0.0,
          "quantity": data["Quantity"] as int? ?? 0,
          "description": data["Description"]?.toString() ?? "",
          "ratingAverage": (data["Rating_Average"] as num?)?.toDouble() ?? 0.0,
          "status": data["Status"]?.toString() ?? "Unknown",
          "artisan": {
            "ssn": data["Artisan"]?["SSN"]?.toString() ?? "Unknown",
            "fullName": data["Artisan"]?["Full_Name"]?.toString() ?? "Unknown",
            "profileImage": data["Artisan"]?["ProfileImage"]?.toString() ?? "",
          },
          "category": data["Category"]?.toString() ?? "Unknown",
          "images": List<String>.from(data["Images"] ?? []),
        };
      } else {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          "error": responseData["message"] ??
              "Failed to load product details: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("GetProductDetails Error: $e");
      return {"error": "Failed to load product details: $e"};
    }
  }

  Future<List<ProductModelInFilter>> fetchProducts({
    required String query,
    required List<String> categories,
    required double minPrice,
    required double maxPrice,
    double? minRating,
  }) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for fetching products');
        throw Exception('User not logged in');
      }

      final Map<String, String> queryParams = {};

      if (categories.isNotEmpty && categories.first.isNotEmpty) {
        queryParams['category'] = categories.first;
      }

      if (query.trim().isNotEmpty) {
        queryParams['query'] = query.trim().toLowerCase();
      }

      if (minPrice < 0 || maxPrice < minPrice) {
        throw Exception('Invalid price range');
      }
      queryParams['minPrice'] = minPrice.toInt().toString();
      queryParams['maxPrice'] = maxPrice.toInt().toString();

      if (minRating != null) {
        if (minRating < 0 || minRating > 5) {
          throw Exception('Invalid rating value');
        }
        queryParams['minRating'] = minRating.toInt().toString();
      }

      debugPrint('Query Parameters for fetchProducts: $queryParams');

      final Uri url = Uri.https(
        'herfa-system-handmade.runasp.net',
        '/api/Home/search_product',
        queryParams,
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
          'Fetch products response: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final products =
            data.map((json) => ProductModelInFilter.fromJson(json)).toList();
        debugPrint('Parsed ${products.length} filtered products');
        return products;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        String errorMessage = 'Failed to load products: ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody['errors'] != null) {
            final errors = errorBody['errors'] as Map<String, dynamic>;
            errorMessage += ', Errors: {';
            errors.forEach((key, value) {
              errorMessage += '$key: ${value.join(", ")}; ';
            });
            errorMessage += '}';
          } else {
            errorMessage +=
                ', ${errorBody["message"] ?? errorBody["Message"] ?? "Unknown error"}';
          }
        } catch (e) {
          errorMessage += ', Response body: ${response.body}';
        }
        debugPrint(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Fetch products error: $e');
      throw Exception('Error fetching products: $e');
    }
  }

  Future<Artisan> fetchArtisanData(String artisanId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for fetching artisan data');
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$artisanUrl/artisan/$artisanId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint(
          'Fetch artisan response: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return Artisan.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => fetchArtisanData(artisanId));
      } else {
        debugPrint(
            'Failed to load artisan data: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load artisan data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch artisan data error: $e');
      throw Exception('Error fetching artisan data: $e');
    }
  }

  Future<List<Rating>> fetchArtisanRatings(String artisanSSN) async {
    if (artisanSSN.isEmpty) {
      debugPrint('Invalid artisanSSN: Empty SSN provided');
      throw Exception('Invalid artisan SSN');
    }

    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for fetching artisan ratings');
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$ratingUrl/$artisanSSN'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
          'Fetch artisan ratings response: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final ratings = (jsonResponse['Ratings'] as List?) ?? [];
        return ratings.map((item) => Rating.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => fetchArtisanRatings(artisanSSN));
      } else {
        debugPrint(
            'Failed to load artisan ratings: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to load artisan ratings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch artisan ratings error: $e');
      throw Exception('Error fetching artisan ratings: $e');
    }
  }

  Future<List<Rating>> fetchProductRatings(int productId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for fetching product ratings');
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$productRatingUrl/Rating_product/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
          'Fetch product ratings response: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final ratings = (jsonResponse['Reviews'] as List?) ?? [];
        return ratings.map((item) => Rating.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => fetchProductRatings(productId));
      } else {
        debugPrint(
            'Failed to load product ratings: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to load product ratings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch product ratings error: $e');
      throw Exception('Error fetching product ratings: $e');
    }
  }

  Future<void> submitArtisanRating(
    String artisanSSN, double rating, String? comment) async {
  if (artisanSSN.isEmpty) {
    debugPrint('Invalid artisanSSN: Empty SSN provided');
    throw Exception('Invalid artisan SSN');
  }

  try {
    final String? token = await AuthService().getAccessToken();
    if (token == null) {
      debugPrint('No access token found for submitting artisan rating');
      throw Exception('User not logged in');
    }

    final body = {
      "Artisan_Rate": rating.toInt(),
      "Comment": comment ?? "",
    };

    debugPrint(
        'Submitting rating for artisan $artisanSSN with body: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse('$baseUrl/Rating/add_Rating/$artisanSSN'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      debugPrint('Request timed out for artisan $artisanSSN');
      throw Exception('Request timed out');
    });

    debugPrint(
        'Submit artisan rating response: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint(
          'Artisan rating submitted successfully for artisan $artisanSSN');
    } else if (response.statusCode == 401) {
      debugPrint('Unauthorized error, attempting to handle...');
      await _handleUnauthorized(
          () => submitArtisanRating(artisanSSN, rating, comment));
    } else if (response.statusCode == 400 || response.statusCode == 409) {
      String errorMessage = 'Failed to submit rating';
      if (response.body.isNotEmpty) {
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage = errorBody['message'] ?? 'Unknown error';
        } catch (e) {
          errorMessage = 'Invalid response: ${response.body}';
        }
      }
      debugPrint('Rating error: $errorMessage');
      throw Exception(errorMessage);
    } else {
      String errorMessage =
          'Server error: ${response.statusCode}, Body: ${response.body}';
      debugPrint(errorMessage);
      throw Exception(errorMessage);
    }
  } catch (e) {
    debugPrint('Submit artisan rating error: $e');
    rethrow;
  }
}

  Future<List<Product>> fetchFavorites() async {
    final url = Uri.parse("$baseUrl/Favourite/my-favourites");
    try {
      final token = await AuthService().getAccessToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        debugPrint('Fetched favorites raw data: $jsonData');
        return jsonData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
      throw Exception('Error fetching favorites: $e');
    }
  }

Future<List<Category>> fetchCategories() async {
  try {
    final String? token = await AuthService().getAccessToken();
    print('Access token: $token');
    if (token == null) {
      debugPrint('No access token found for fetching categories');
      throw Exception('User not logged in');
    }

    print('Fetching categories from: $categoryUrl/all-with-products');
    final response = await http.get(
      Uri.parse('$categoryUrl/all-with-products'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('Categories response status: ${response.statusCode}');
    print('Categories response body: ${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      print('Categories JSON: $jsonList');
      return jsonList.map((json) => Category.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      print('Unauthorized, retrying...');
      return await _handleUnauthorized(() => fetchCategories());
    } else {
      debugPrint(
          'Failed to load categories: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Fetch categories error: $e');
    throw Exception('Error fetching categories: $e');
  }
}

  Future<List<Product>> fetchProductsByCategory(String category) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for products by category');
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$categoryUrl/products/$category'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> productsJson = jsonResponse['Products'] ?? [];
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(
            () => fetchProductsByCategory(category));
      } else {
        debugPrint(
            'Failed to load products for category $category: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to load products for category: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch products by category error: $e');
      throw Exception('Error fetching products for category: $e');
    }
  }

  Future<Map<String, dynamic>> addToFavourite(int productId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for adding to favourite');
        throw Exception('User not logged in');
      }

      final body = {
        "Product_ID": productId,
      };

      debugPrint('Add to favourite request body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$favouriteUrl/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Add to favourite successful: ${response.body}');
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => addToFavourite(productId));
      } else {
        debugPrint(
            'Failed to add to favourite: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to add to favourite: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('Add to favourite error: $e');
      throw Exception('Error adding to favourite: $e');
    }
  }

  Future<Map<String, dynamic>> removeFromFavourite(int productId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for removing from favourite');
        throw Exception('User not logged in');
      }

      final response = await http.delete(
        Uri.parse('$favouriteUrl/remove/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('Remove from favourite successful: ${response.body}');
        return response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {"message": "Removed successfully"};
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => removeFromFavourite(productId));
      } else {
        debugPrint(
            'Failed to remove from favourite: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to remove from favourite: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('Remove from favourite error: $e');
      throw Exception('Error removing from favourite: $e');
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$authUrl/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await AuthService()
            .saveTokens(data['AccessToken'], data['RefreshToken']);
        debugPrint('Token refreshed successfully: ${data["AccessToken"]}');
        return data;
      } else {
        debugPrint('Refresh token failed: ${response.body}');
        throw Exception('Failed to refresh token: ${response.body}');
      }
    } catch (e) {
      debugPrint('Refresh token error: $e');
      throw Exception('Error refreshing token: $e');
    }
  }

  Future<Map<String, dynamic>> fetchUserData() async {
    final String? token = await AuthService().getAccessToken();
    if (token == null) {
      debugPrint('No access token for fetchUserData');
      return {"error": "User not logged in"};
    }

    try {
      final response = await http.get(
        Uri.parse("$userUrl/my-profile"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => fetchUserData());
      } else {
        debugPrint(
            'Fetch user data failed: ${response.statusCode}, Body: ${response.body}');
        return {"error": "Failed to fetch user data: ${response.statusCode}"};
      }
    } catch (e) {
      debugPrint('Fetch user data error: $e');
      return {"error": "Error: $e"};
    }
  }

  Future<List<Product>> fetchAllProductsFull2() async {
    List<Product> allProducts = [];
    int pageNumber = 1;
    const int pageSize = 50;

    while (true) {
      final products =
          await fetchAllProducts(pageSize: pageSize, pageNumber: pageNumber);
      if (products.isEmpty) break;

      final fullProducts = await Future.wait(
        products.map((product) async {
          final productId = product.productId;
          return await fetchProductById(productId);
          // ignore: dead_code
          return null;
        }),
      );

      allProducts.addAll(
          fullProducts.where((product) => product != null).cast<Product>());

      pageNumber++;
    }

    debugPrint(
        'Fetched Products: ${allProducts.map((product) => product.productId).toList()}');
    return allProducts;
  }

  Future<List<Product>> fetchAllProducts(
      {int pageNumber = 1, int pageSize = 10}) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for products');
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse(
            '$BaseUrl/api/Home/products?pageNumber=$pageNumber&pageSize=$pageSize'),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint(
          'Fetch all products response: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('Products')) {
          List productsJson = jsonResponse['Products'];
          debugPrint('All products JSON: $productsJson');
          return productsJson.map((data) => Product.fromJson(data)).toList();
        } else {
          debugPrint('Invalid response format: $jsonResponse');
          throw Exception('Invalid response format: Missing Products field');
        }
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(
            () => fetchAllProducts(pageNumber: pageNumber, pageSize: pageSize));
      } else {
        debugPrint(
            'Failed to load products: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch all products error: $e');
      rethrow;
    }
  }

  Future<List<ProductModelInFilter>> fetchAllProducts2() async {
    try {
      final String? token = await AuthService().getAccessToken();
      List<ProductModelInFilter> allProducts = [];
      int pageNumber = 1;
      const int pageSize = 50; 

      while (true) {
        final Map<String, String> queryParameters = {
          'pageNumber': pageNumber.toString(),
          'pageSize': pageSize.toString(),
        };

        final Uri url = Uri.https(
          'herfa-system-handmade.runasp.net',
          '/api/Home/products',
          queryParameters,
        );

        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        debugPrint(
            'Fetch all products response for page $pageNumber: ${response.statusCode}, Body: ${response.body}');

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final List<dynamic> productsJson =
              data['Products'] as List<dynamic>? ?? [];
          if (productsJson.isEmpty) break; 

          final products = productsJson
              .map((json) => ProductModelInFilter.fromJson(json))
              .toList();
          allProducts.addAll(products);

          debugPrint('Parsed ${products.length} products for page $pageNumber');
          pageNumber++;
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized: Please login again');
        } else {
          String errorMessage =
              'Failed to load products: ${response.statusCode}';
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage +=
                ', ${errorBody["message"] ?? errorBody["Message"] ?? "Unknown error"}';
          } catch (e) {
            errorMessage += ', Response body: ${response.body}';
          }
          debugPrint(errorMessage);
          throw Exception(errorMessage);
        }
      }

      debugPrint('Total fetched products: ${allProducts.length}');
      return allProducts;
    } catch (e) {
      debugPrint('Fetch all products error: $e');
      throw Exception('Error fetching products: $e');
    }
  }

  Future<List<Product>> fetchAllProductsFull() async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for products');
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$homeUrl/products'),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint('Fetch all products response: ${response.statusCode}');
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        debugPrint('All products JSON: $jsonResponse');
        return jsonResponse.map((data) => Product.fromJson(data)).toList();
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => fetchAllProducts());
      } else {
        debugPrint(
            'Failed to load products: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch all products error: $e');
      rethrow;
    }
  }

  Future<List<Product>> fetchNewProducts() async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for latest-products');
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$BaseUrl/api/Home/latest-products?take=10'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      debugPrint('Fetch new products response: ${response.statusCode}');
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        debugPrint('New products JSON: $jsonResponse');
        return jsonResponse.map((data) => Product.fromJson(data)).toList();
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => fetchNewProducts());
      } else {
        debugPrint(
            'Failed to load new products: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load new products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch new products error: $e');
      rethrow;
    }
  }

  Future<List<Product>> fetchLatestProducts() async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for latest-products');
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$BaseUrl/api/Home/latest-products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      debugPrint('Fetch latest products response: ${response.statusCode}');
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        debugPrint('Latest products JSON: $jsonResponse');
        List<Product> products =
            jsonResponse.map((data) => Product.fromJson(data)).toList();

        
        final fullProducts = await Future.wait(
          products.map((product) async {
            try {
              return await fetchProductById(product.productId!);
            } catch (e) {
              debugPrint('Error fetching product ${product.productId}: $e');
              return product; 
            }
          }),
        );
        return fullProducts;
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => fetchLatestProducts());
      } else {
        debugPrint(
            'Failed to load latest products: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to load latest products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch latest products error: $e');
      return []; 
    }
  }

  Future<List<Product>> fetchNewProductsFull() => fetchLatestProducts();

  Future<List<Product>> fetchNewProductsFull2() async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for latest-products');
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$homeUrl/latest-products'),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint('Fetch new products response: ${response.statusCode}');
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        debugPrint('New products JSON: $jsonResponse');
        return jsonResponse.map((data) => Product.fromJson(data)).toList();
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => fetchNewProducts());
      } else {
        debugPrint(
            'Failed to load new products: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load new products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch new products error: $e');
      rethrow;
    }
  }

  Future<Product> fetchProductById(int productId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for product/$productId');
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$homeUrl/product/$productId?productId=$productId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint('Fetch product $productId response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        debugPrint('Product $productId JSON: $jsonResponse');
        return Product.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => fetchProductById(productId));
      } else {
        debugPrint(
            'Failed to load product $productId: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch product $productId error: $e');
      rethrow;
    }
  }

  Future<List<Order>> fetchOrders(String status) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for fetching orders');
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$ordersUrl/Myorders-status?status=$status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => Order.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => fetchOrders(status));
      } else {
        debugPrint(
            'Failed to load orders for status $status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load orders for status: $status');
      }
    } catch (e) {
      debugPrint('Fetch orders error: $e');
      throw Exception('Error fetching orders: $e');
    }
  }

  Future<Order> fetchOrderDetails(int orderId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for fetching order details');
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$ordersUrl/order-details-Client/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Order.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => fetchOrderDetails(orderId));
      } else {
        debugPrint(
            'Failed to load order details for order $orderId: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load order details for order: $orderId');
      }
    } catch (e) {
      debugPrint('Fetch order details error: $e');
      throw Exception('Error fetching order details: $e');
    }
  }

  Future<void> cancelOrder(int orderId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for canceling order');
        throw Exception('User not logged in');
      }

      final response = await http.put(
        Uri.parse('$orderUrl/cancel-order_Client/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': 'Cancelled'}),
      );

      if (response.statusCode == 200) {
        debugPrint('Order $orderId canceled successfully');
      } else if (response.statusCode == 401) {
        await _handleUnauthorized(() => cancelOrder(orderId));
      } else {
        debugPrint(
            'Failed to cancel order $orderId: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to cancel order: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Cancel order error: $e');
      throw Exception('Error canceling order: $e');
    }
  }

  Future<void> submitProductRating(
      int productId, double rating, String? comment) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for submitting product rating');
        throw Exception('User not logged in');
      }

      final body = {
        "Product_Rate": rating.toInt(),
        "Comment": comment ?? "",
      };

      debugPrint(
          'Submitting rating for product $productId with body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$productRatingUrl/rate/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint(
          'API Response: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
            'Product rating submitted successfully for product $productId');
      } else if (response.statusCode == 401) {
        await _handleUnauthorized(
            () => submitProductRating(productId, rating, comment));
      } else {
        
        if (response.body.isEmpty) {
          debugPrint(
              'Empty response body for status code: ${response.statusCode}');
          throw Exception(
            'Failed to submit product rating: ${response.statusCode}, No response data',
          );
        }

        
        final errorBody = jsonDecode(response.body);
        debugPrint(
            'Failed to submit product rating: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Failed to submit product rating: ${response.statusCode}, ${errorBody["message"] ?? "Unknown error"}',
        );
      }
    } catch (e) {
      debugPrint('Submit product rating error: $e');
      throw Exception('Error submitting product rating: $e');
    }
  }

  Future<T> _handleUnauthorized<T>(Future<T> Function() retry) async {
    try {
      final refreshToken = await AuthService().getRefreshToken();
      if (refreshToken == null) {
        debugPrint('No refresh token available');
        throw Exception('User not logged in');
      }

      final response = await this.refreshToken(refreshToken);
      if (response.containsKey('AccessToken') &&
          response.containsKey('RefreshToken')) {
        return await retry();
      } else {
        throw Exception('Failed to refresh token');
      }
    } catch (e) {
      debugPrint('Unauthorized handling error: $e');
      throw Exception('Unauthorized: Please login again');
    }
  }

  Future<List<CartItem>> getCartItems() async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for cart items');
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$cartUrl/items'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => CartItem.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => getCartItems());
      } else {
        debugPrint(
            'Failed to load cart items: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load cart items: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch cart items error: $e');
      throw Exception('Error fetching cart items: $e');
    }
  }

  Future<void> updateCartItemQuantity(int cartId, int quantity) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for updating cart item quantity');
        throw Exception('User not logged in');
      }

      final response = await http.put(
        Uri.parse('$cartUrl/Updated_Quantity/$cartId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'quantity': quantity}),
      );

      if (response.statusCode == 200) {
        debugPrint('Cart item quantity updated successfully');
      } else if (response.statusCode == 401) {
        await _handleUnauthorized(
            () => updateCartItemQuantity(cartId, quantity));
      } else {
        debugPrint(
            'Failed to update cart item quantity: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to update cart item quantity: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Update cart item quantity error: $e');
      throw Exception('Error updating cart item quantity: $e');
    }
  }

  Future<void> deleteCartItem(int cartId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for deleting cart item');
        throw Exception('User not logged in');
      }

      final response = await http.delete(
        Uri.parse('$cartUrl/remove/$cartId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        debugPrint('Cart item deleted successfully');
      } else if (response.statusCode == 401) {
        await _handleUnauthorized(() => deleteCartItem(cartId));
      } else {
        debugPrint(
            'Failed to delete cart item: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to delete cart item: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Delete cart item error: $e');
      throw Exception('Error deleting cart item: $e');
    }
  }

  Future<Map<String, dynamic>> checkout({
    required List<CartItem> cartItems,
    required String paymentMethod,
    required String shippingMethod,
    required double shippingCost,
    required String address,
    required String zipCode,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for checkout');
        throw Exception('User not logged in');
      }

      final body = {
        "Items": cartItems
            .map((item) => {
                  "Product_ID": item.productId,
                  "Quantity": item.quantity,
                })
            .toList(),
        "PaymentMethod": paymentMethod,
        "ShippingMethod": shippingMethod,
        "ShippingCost": shippingCost,
        "Address": address,
        "ZipCode": zipCode,
        "FullName": fullName,
        "PhoneNumber": phoneNumber,
      };

      debugPrint('Checkout request body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$orderUrl/checkout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        debugPrint('Checkout successful: ${response.body}');
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => checkout(
              cartItems: cartItems,
              paymentMethod: paymentMethod,
              shippingMethod: shippingMethod,
              shippingCost: shippingCost,
              address: address,
              zipCode: zipCode,
              fullName: fullName,
              phoneNumber: phoneNumber,
            ));
      } else {
        debugPrint(
            'Checkout failed: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Checkout failed: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('Checkout error: $e');
      throw Exception('Error during checkout: $e');
    }
  }

  Future<Map<String, dynamic>> addToCart(int productId) async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('No access token found for adding to cart');
        throw Exception('User not logged in');
      }

      final body = {
        "Product_ID": productId,
      };

      debugPrint('Add to cart request body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$cartUrl/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        debugPrint('Add to cart successful: ${response.body}');
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => addToCart(productId));
      } else {
        debugPrint(
            'Failed to add to cart: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to add to cart: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('Add to cart error: $e');
      throw Exception('Error adding to cart: $e');
    }
  }

  Future<String?> getAccessToken() async {
    return await AuthService().getAccessToken();
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String birthDate,
    required String phone,
    required String gender,
    required String address,
    required String? password,
    File? imageFile,
  }) async {
    final url = Uri.parse('$baseUrl/User/update-profile');

    final token = await AuthService().getAccessToken();
    if (token == null) {
      debugPrint('No access token found for updating profile');
      throw Exception('User not logged in');
    }

    try {
      var request = http.MultipartRequest("PUT", url);

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['Full_Name'] = fullName;
      request.fields['Birth_Date'] = birthDate;
      request.fields['Phone'] = phone;
      request.fields['Gender'] = gender;
      request.fields['Address'] = address;

      if (password != null && password.isNotEmpty) {
        request.fields['Password'] = password;
      }

      if (imageFile != null) {
        debugPrint('Uploading image: ${imageFile.path}');
        request.files
            .add(await http.MultipartFile.fromPath('Image', imageFile.path));
      } else {
        debugPrint('No image file selected for upload');
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Profile updated successfully: ${response.body}');
        final responseData = jsonDecode(response.body);
        if (responseData['Message'] == 'Profile updated successfully.') {
          return responseData;
        } else {
          throw Exception(responseData['Message'] ?? 'Unknown error occurred');
        }
      } else if (response.statusCode == 401) {
        return await _handleUnauthorized(() => updateProfile(
              fullName: fullName,
              birthDate: birthDate,
              phone: phone,
              gender: gender,
              address: address,
              password: password,
              imageFile: imageFile,
            ));
      } else {
        debugPrint(
            'Failed to update profile: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to update profile: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      throw Exception('Error updating profile: $e');
    }
  }

  Future<List<NotificationModel>> getMyNotifications() async {
    try {
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return [];
      }

      final url = Uri.parse("$BaseUrl/api/Notification/my-notifications");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache',
        },
      );

      print("GetMyNotifications Response status: ${response.statusCode}");
      print("GetMyNotifications Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("GetMyNotifications Error: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> markNotificationAsRead(
      int notificationId) async {
    try {
      
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      
      final url =
          Uri.parse("$BaseUrl/api/Notification/mark-as-read/$notificationId");

      
      print("MarkAsRead Request: Sending to $url");

      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      
      print("MarkAsRead Response status: ${response.statusCode}");
      print("MarkAsRead Response body: ${response.body}");

     
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          "success": true,
          "message": "Notification marked as read successfully"
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          "error": responseData["message"] ??
              "Failed to mark notification as read: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("MarkAsRead Error: $e");
      return {"error": "Failed to mark notification as read: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    try {
      
      final String? token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "User not logged in"};
      }

      
      final url = Uri.parse("$BaseUrl/api/Notification/delete/$notificationId");

      
      print("DeleteNotification Request: Sending to $url");

      
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      
      print("DeleteNotification Response status: ${response.statusCode}");
      print("DeleteNotification Response body: ${response.body}");

      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          "success": true,
          "message": "Notification deleted successfully"
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          "error": responseData["message"] ??
              "Failed to delete notification: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("DeleteNotification Error: $e");
      return {"error": "Failed to delete notification: $e"};
    }
  }

  Future<Map<String, dynamic>> getAppRatings() async {
    try {
      
      final token = await AuthService().getAccessToken();
      if (token == null) {
        return {"error": "No access token found. Please login first."};
      }

      final response = await http.get(
        Uri.parse("$baseUrl/AppRating/app-ratings"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("🔍 Status Code: ${response.statusCode}");
      print("🔍 Raw API Response: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "averageRating": data["AverageRating"] ?? 0.0,
          "totalRatings": data["TotalRatings"] ?? 0,
          "ratings": List<dynamic>.from(data["Ratings"] ?? []),
        };
      } else if (response.statusCode == 401) {
        return {
          "error": "Unauthorized: Please check your token or login again"
        };
      } else {
        String errorMessage =
            data["Message"] ?? data["error"] ?? "Failed to fetch ratings";
        return {"error": errorMessage};
      }
    } catch (e) {
      print("❌ API Error: $e");
      return {
        "error": "Failed to fetch ratings due to network or server error"
      };
    }
  }

  Future<List<Map<String, dynamic>>> getMyComplaints() async {
    try {
      final token = await AuthService().getAccessToken();
      if (token == null) {
        return [
          {"error": "No access token found. Please login first."}
        ];
      }

      final response = await http.get(
        Uri.parse("$BaseUrl/api/Complaint/my-complaints"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("Fetch Status Code: ${response.statusCode}");
      print("Fetch Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => {
                  "ComplaintId": item["ComplaintId"] as int,
                  "Problem": item["Problem"] as String,
                  "ProblemDate": item["ProblemDate"] as String,
                  "Status": item["Status"] as String,
                  "Response": item["Response"] as String,
                  "ResponseDate": item["ResponseDate"] as String?,
                })
            .toList();
      } else if (response.statusCode == 401) {
        return [
          {
            "error":
                "Unauthorized: Token may be invalid or expired. Please login again."
          }
        ];
      } else {
        return [
          {
            "error":
                "Failed to fetch complaints: ${response.statusCode} - ${response.body}"
          }
        ];
      }
    } catch (e) {
      print("❌ API Error: $e");
      return [
        {
          "error":
              "Failed to fetch complaints due to network or server error: $e"
        }
      ];
    }
  }

    Future<String> deleteProductAdmin(int productId) async {
    try {
      final token = await AuthService().getAccessToken();
      if (token == null) {
        return "No access token found. Please login first.";
      }

      final response = await http.delete(
        Uri.parse("$BaseUrl/api/Product/delete-product-admin/$productId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("Delete Product Status Code: ${response.statusCode}");
      print("Delete Product Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey("Message")) {
          return data["Message"] as String? ?? "Product deleted successfully.";
        }
        return "Product deleted successfully."; 
      } else {
        final errorData = jsonDecode(response.body);
        return errorData["Message"] ?? "Failed to delete product: ${response.statusCode}";
      }
    } catch (e) {
      print("❌ API Error: $e");
      if (e.toString().contains("SocketException")) {
        return "No internet connection. Please try again.";
      }
      return "Failed to delete product due to an error: $e";
    }
  }
}