import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/artisan/editProdect.dart';
import 'package:herfa/artisan/myDetails.dart';
import 'package:herfa/artisan/profile.dart';
import '../Shared Files/databaseHelper.dart';

class MainProfilePage extends StatefulWidget {
  const MainProfilePage({super.key});

  @override
  _MainProfilePageState createState() => _MainProfilePageState();
}

class _MainProfilePageState extends State<MainProfilePage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _productsFuture;
  late Future<Map<String, dynamic>> _userInfoFuture;
  late Future<Map<String, dynamic>> _ratingsFuture;
  Map<int, double> ratingDistribution = {
    5: 0.0,
    4: 0.0,
    3: 0.0,
    2: 0.0,
    1: 0.0
  };

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _refreshData() {
    setState(() {
      _productsFuture = Future(() async {
        bool isConnected = await _checkInternetConnection();
        if (!isConnected) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Connection Error"),
              content: Text("No internet connection. Please check your network and try again."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                ),
              ],
            ),
          );
          return {"error": "No internet connection"};
        }
        return await _apiService.getProducts();
      });

      _userInfoFuture = Future(() async {
        bool isConnected = await _checkInternetConnection();
        if (!isConnected) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Connection Error"),
              content: Text("No internet connection. Please check your network and try again."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                ),
              ],
            ),
          );
          return {"error": "No internet connection"};
        }
        return await _apiService.getMyInformation();
      });

      _ratingsFuture = Future(() async {
        bool isConnected = await _checkInternetConnection();
        if (!isConnected) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Connection Error"),
              content: Text("No internet connection. Please check your network and try again."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                ),
              ],
            ),
          );
          return {"error": "No internet connection"};
        }
        final userInfo = await _apiService.getMyInformation();
        if (userInfo.containsKey("error")) {
          throw Exception(userInfo["error"]);
        }
        final String artisanSSN = userInfo["SSN"]?.toString() ?? "";
        final ratings = await _apiService.getArtisanRatings(artisanSSN);
        if (ratings.containsKey("error")) {
          throw Exception(ratings["error"]);
        }

        List<dynamic> ratingsList = ratings["ratings"] ?? [];
        if (ratingsList.isNotEmpty) {
          Map<int, int> ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
          for (var rating in ratingsList) {
            int ratingValue = (rating["Artisan_Rate"] as num).toInt();
            ratingCounts[ratingValue] = (ratingCounts[ratingValue] ?? 0) + 1;
          }
          ratingDistribution = ratingCounts.map((rating, count) => MapEntry(
                rating,
                ratingsList.isNotEmpty ? (count / ratingsList.length) * 100 : 0.0,
              ));
        }
        return ratings;
      });
    });
  }

  Future<void> _onRefresh() async {
    _refreshData();
  }

  String formatRelativeTime(String createdAt) {
    try {
      DateTime dateTime = DateTime.parse(createdAt).toUtc();

      if (dateTime.year <= 1) {
        return "";
      }

      DateTime now = DateTime.now().toUtc();
      Duration difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return "Just now";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes}m ago";
      } else if (difference.inHours < 24) {
        return "${difference.inHours}h ago";
      } else if (difference.inDays < 30) {
        return "${difference.inDays}d ago";
      } else if (difference.inDays < 365) {
        int months = (difference.inDays / 30).floor();
        return "${months}mo ago";
      } else {
        int years = (difference.inDays / 365).floor();
        return "${years}y ago";
      }
    } catch (e) {
      return "Unknown date";
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      appBar: AppBar(
        title: Align(
          alignment: Alignment.center,
          child: Text(
            'My Profile',
            style: GoogleFonts.nunitoSans(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FutureBuilder<Map<String, dynamic>>(
                future: Future.wait([_productsFuture, _userInfoFuture])
                    .then((results) {
                  return {
                    'products': results[0],
                    'userInfo': results[1],
                  };
                }),
                builder: (context, snapshot) {
                  String artisanName = '';
                  String? imageUrl;

                  if (snapshot.connectionState == ConnectionState.done &&
                      !snapshot.hasError &&
                      snapshot.data != null) {
                    final productsData =
                        snapshot.data!['products'] as Map<String, dynamic>;
                    final userInfoData =
                        snapshot.data!['userInfo'] as Map<String, dynamic>;

                    if (!productsData.containsKey("error")) {
                      artisanName = productsData["FullName"]?.toString() ??
                          'Unknown Artisan';
                    }
                    if (!userInfoData.containsKey("error")) {
                      imageUrl = userInfoData['Image']?.toString();
                    }
                  }

                  return Padding(
                    padding: EdgeInsets.only(
                      top: screenHeight * 0.01875,
                      bottom: screenHeight * 0.025,
                      left: screenWidth * 0.025,
                      right: screenWidth * 0.025,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: screenWidth * 0.075,
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[600]
                              : Colors.grey[300],
                          child: imageUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: screenWidth * 0.15,
                                    height: screenWidth * 0.15,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                (loadingProgress.expectedTotalBytes ?? 1)
                                            : null,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white70
                                            : const Color(0xFF0C8A7B),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        size: screenWidth * 0.075,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: screenWidth * 0.075,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                        ),
                        SizedBox(width: screenWidth * 0.025),
                        TextButton(
                          child: Text(
                            artisanName,
                            style: GoogleFonts.nunitoSans(
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ProfilePage()),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 0.0,
                  right: screenWidth * 0.04,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: screenWidth * 0.375,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0C8A7B),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.01,
                      horizontal: screenWidth * 0.04,
                    ),
                    child: Text(
                      'My Products',
                      style: GoogleFonts.nunitoSans(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              FutureBuilder<Map<String, dynamic>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : const Color(0xFF0C8A7B),
                      ),
                    );
                  } else if (snapshot.hasError ||
                      snapshot.data?.containsKey("error") == true) {
                    return Center(
                      child: Text(
                        snapshot.data?["error"] ?? "Error loading products",
                        style: GoogleFonts.nunitoSans(
                          fontSize: screenWidth * 0.04,
                          color: Colors.red,
                        ),
                      ),
                    );
                  } else {
                    final products =
                        snapshot.data?["Products"] as List<dynamic>? ?? [];
                    if (products.isEmpty) {
                      return Center(
                        child: Text(
                          "No products available",
                          style: GoogleFonts.nunitoSans(
                            fontSize: screenWidth * 0.04,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: screenWidth * 0.04,
                          mainAxisSpacing: screenWidth * 0.04,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index] as Map<String, dynamic>;
                          final images = product['Images'] as List<dynamic>? ?? [];
                          final quantity = product['Quantity'] as int? ?? 0;
                          final status = quantity == 0 ? 'Not Available' : product['Status']?.toString() ?? 'Unknown';

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailsPage(product: product),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 2,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[900]
                                  : Colors.white,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: screenHeight * 0.16,
                                    width: double.infinity,
                                    child: images.isNotEmpty
                                        ? Image.network(
                                            images[0],
                                            fit: BoxFit.contain,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  color: Theme.of(context).brightness == Brightness.dark
                                                      ? Colors.white70
                                                      : const Color(0xFF0C8A7B),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.broken_image,
                                                size: screenWidth * 0.1,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.grey[400]
                                                    : Colors.grey,
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.broken_image,
                                            size: screenWidth * 0.125,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.grey[400]
                                                : Colors.grey,
                                          ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(screenWidth * 0.02),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['ProductName']?.toString() ??
                                              'Unknown Product',
                                          style: GoogleFonts.nunitoSans(
                                            fontSize: screenWidth * 0.04,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        Text(
                                          '${product['Price']?.toString() ?? 'N/A'} LE',
                                          style: GoogleFonts.nunitoSans(
                                            fontSize: screenWidth * 0.035,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        Text(
                                          status,
                                          style: GoogleFonts.nunitoSans(
                                            fontSize: screenWidth * 0.035,
                                            color: status == 'Available'
                                                ? const Color(0xFF0C8A7B)
                                                : Colors.red,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 0),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => Edit_Product(
                                                    productId:
                                                        product['ProductID'].toString(),
                                                    productData: {
                                                      'ProductName':
                                                          product['ProductName'] ?? '',
                                                      'Price': product['Price'] ?? 0.0,
                                                      'Quantity':
                                                          product['Quantity'] ?? 0,
                                                      'Description':
                                                          product['Description'] ?? '',
                                                      'Category': product['Category'] ??
                                                          product['CategoryName'] ??
                                                          product['Cat_Type'] ??
                                                          '',
                                                      'Status':
                                                          product['Status'] ?? 'Available',
                                                      'Images': product['Images'] ?? [],
                                                    },
                                                  ),
                                                ),
                                              );

                                              if (result == true) {
                                                _refreshData();
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0C8A7B),
                                              padding: EdgeInsets.symmetric(
                                                  vertical: screenHeight * 0.01),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(screenWidth * 0.02),
                                              ),
                                            ),
                                            child: Text(
                                              'EDIT',
                                              style: GoogleFonts.nunitoSans(
                                                fontSize: screenWidth * 0.035,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: screenHeight * 0.02),
              Padding(
                padding: EdgeInsets.only(
                  left: 0.0,
                  right: screenWidth * 0.04,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: screenWidth * 0.325,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0C8A7B),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.01,
                      horizontal: screenWidth * 0.04,
                    ),
                    child: Text(
                      'Reviews',
                      style: GoogleFonts.nunitoSans(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              FutureBuilder<Map<String, dynamic>>(
                future: _ratingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : const Color(0xFF0C8A7B),
                      ),
                    );
                  } else if (snapshot.hasError ||
                      snapshot.data?.containsKey("error") == true) {
                    return Center(
                      child: Text(
                        snapshot.data?["error"] ?? "Error loading reviews",
                        style: GoogleFonts.nunitoSans(
                          fontSize: screenWidth * 0.04,
                          color: Colors.red,
                        ),
                      ),
                    );
                  } else {
                    final ratings =
                        snapshot.data?["ratings"] as List<dynamic>? ?? [];
                    if (ratings.isEmpty) {
                      return Center(
                        child: Text(
                          "No reviews available",
                          style: GoogleFonts.nunitoSans(
                            fontSize: screenWidth * 0.04,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                      child: Column(
                        children: ratings.map((rating) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: screenWidth * 0.05,
                                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[600]
                                      : Colors.grey[300],
                                  child: rating["ClientImage"] != null
                                      ? ClipOval(
                                          child: Image.network(
                                            rating["ClientImage"],
                                            fit: BoxFit.cover,
                                            width: screenWidth * 0.1,
                                            height: screenWidth * 0.1,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        (loadingProgress.expectedTotalBytes ?? 1)
                                                    : null,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white70
                                                    : const Color(0xFF0C8A7B),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              );
                                            },
                                          ),
                                        )
                                      : Icon(
                                          Icons.person,
                                          color: Colors.white,
                                        ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            rating["ClientName"] ?? "Unknown",
                                            style: GoogleFonts.nunitoSans(
                                              fontSize: screenWidth * 0.04,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            formatRelativeTime(rating["CreatedAt"] ?? ""),
                                            style: GoogleFonts.nunitoSans(
                                              fontSize: screenWidth * 0.035,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (index) => Icon(
                                            Icons.star,
                                            color: index < (rating["Artisan_Rate"] as num).toInt()
                                                ? const Color(0xFF0C8A7B)
                                                : Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.grey[600]
                                                    : Colors.grey[300],
                                            size: screenWidth * 0.04,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.005),
                                      Text(
                                        rating["Comment"] ?? "",
                                        style: GoogleFonts.nunitoSans(
                                          fontSize: screenWidth * 0.035,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: screenHeight * 0.0),
            ],
          ),
        ),
      ),
    );
  }
}