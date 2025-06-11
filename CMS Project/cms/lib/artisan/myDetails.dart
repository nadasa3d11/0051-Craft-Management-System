import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/artisan/editProdect.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailsPage({super.key, required this.product});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _ratingsFuture;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchRatings();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _fetchRatings() {
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
      return await _apiService.getProductRatings(widget.product['ProductID'].toString());
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _fetchRatings();
    });
  }

  String formatRelativeTime(String createdAt) {
    try {
      DateTime dateTime = DateTime.parse(createdAt).toUtc();

      if (dateTime.year <= 1) {
        return "Unknown date";
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

    final images = widget.product['Images'] as List<dynamic>? ?? [];
    final productName = widget.product['ProductName']?.toString() ?? 'Unknown Product';
    final description = widget.product['Description']?.toString() ?? 'No description available';
    final quantity = widget.product['Quantity'] as int? ?? 0;
    final status = quantity == 0 ? 'Not Available' : widget.product['Status']?.toString() ?? 'Unknown';
    final category = widget.product['Category']?.toString() ?? widget.product['CategoryName']?.toString() ?? widget.product['Cat_Type']?.toString() ?? 'N/A';
    final price = (widget.product['Price'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Details',
          style: GoogleFonts.nunitoSans(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [Colors.black, Colors.grey.shade900]
                : [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.05,
                screenWidth * 0.05,
                screenWidth * 0.05,
                screenHeight * 0.1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: screenHeight * 0.4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(screenWidth * 0.04),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: screenWidth * 0.02,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.04),
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            scrollDirection: Axis.horizontal,
                            itemCount: images.isNotEmpty ? images.length : 1,
                            itemBuilder: (context, index) {
                              if (images.isEmpty) {
                                return Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: screenWidth * 0.13,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[400]
                                        : Colors.grey,
                                  ),
                                );
                              }
                              return Image.network(
                                images[index].toString(),
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: screenHeight * 0.4,
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
                                  return Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: screenWidth * 0.13,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey[400]
                                          : Colors.grey,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          if (images.length > 1)
                            Positioned(
                              bottom: screenHeight * 0.02,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: SmoothPageIndicator(
                                  controller: _pageController,
                                  count: images.length,
                                  effect: WormEffect(
                                    dotHeight: screenWidth * 0.025,
                                    dotWidth: screenWidth * 0.025,
                                    activeDotColor: const Color(0xFF0C8A7B),
                                    dotColor: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    productName,
                    style: GoogleFonts.nunitoSans(
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  if (category != 'N/A')
                    Text(
                      category,
                      style: GoogleFonts.nunitoSans(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.black54,
                      ),
                    ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    "${price.toStringAsFixed(2)} LE",
                    style: GoogleFonts.nunitoSans(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0C8A7B),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'About The Product',
                    style: GoogleFonts.nunitoSans(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    description,
                    style: GoogleFonts.nunitoSans(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.white,
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: screenWidth * 0.015,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantity',
                              style: GoogleFonts.nunitoSans(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              quantity.toString(),
                              style: GoogleFonts.nunitoSans(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: GoogleFonts.nunitoSans(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              status,
                              style: GoogleFonts.nunitoSans(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w400,
                                color: status == 'Available'
                                    ? const Color(0xFF0C8A7B)
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
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
                        final ratingsData = snapshot.data!;
                        final reviews = ratingsData["reviews"] as List<dynamic>? ?? [];
                        final averageRating = ratingsData["averageRating"]?.toDouble() ?? 0.0;
                        final ratingCount = ratingsData["ratingCount"] as int? ?? 0;

                        Map<int, double> ratingDistribution = {5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0};
                        if (reviews.isNotEmpty) {
                          Map<int, int> ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
                          for (var review in reviews) {
                            int ratingValue = (review["Product_Rate"] as num).toInt();
                            ratingCounts[ratingValue] = (ratingCounts[ratingValue] ?? 0) + 1;
                          }
                          ratingDistribution = ratingCounts.map((rating, count) => MapEntry(
                                rating,
                                reviews.isNotEmpty ? (count / reviews.length) * 100 : 0.0,
                              ));
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Reviews',
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.expand_more,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.015),
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[900]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: screenWidth * 0.015,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Text(
                                              "${averageRating.toStringAsFixed(1)} OUT OF 5",
                                              style: GoogleFonts.nunitoSans(
                                                fontSize: screenWidth * 0.06,
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                            SizedBox(width: screenWidth * 0.03),
                                            Row(
                                              children: List.generate(
                                                5,
                                                (index) => Icon(
                                                  Icons.star,
                                                  color: index < averageRating.round()
                                                      ? const Color(0xFF0C8A7B)
                                                      : Theme.of(context).brightness == Brightness.dark
                                                          ? Colors.grey[600]
                                                          : Colors.grey[300],
                                                  size: screenWidth * 0.06,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Text(
                                    "$ratingCount ratings",
                                    style: GoogleFonts.nunitoSans(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey[400]
                                          : Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  Column(
                                    children: List.generate(5, (index) {
                                      int star = 5 - index;
                                      double percentage = ratingDistribution[star] ?? 0.0;
                                      return Padding(
                                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.0075),
                                        child: Row(
                                          children: [
                                            Text(
                                              "$star",
                                              style: GoogleFonts.nunitoSans(
                                                fontSize: screenWidth * 0.04,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                            SizedBox(width: screenWidth * 0.03),
                                            Expanded(
                                              child: LinearProgressIndicator(
                                                value: percentage / 100,
                                                backgroundColor: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.grey[600]
                                                    : Colors.grey[200],
                                                valueColor: const AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF0C8A7B)),
                                                minHeight: screenHeight * 0.01,
                                                borderRadius: BorderRadius.circular(screenWidth * 0.01),
                                              ),
                                            ),
                                            SizedBox(width: screenWidth * 0.03),
                                            Text(
                                              "${percentage.toStringAsFixed(0)}%",
                                              style: GoogleFonts.nunitoSans(
                                                fontSize: screenWidth * 0.04,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              "$ratingCount Reviews",
                              style: GoogleFonts.nunitoSans(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            if (reviews.isNotEmpty)
                              Column(
                                children: reviews.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final review = entry.value;
                                  return AnimatedOpacity(
                                    opacity: 1.0,
                                    duration: Duration(milliseconds: 500 + (index * 200)),
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                                      child: Container(
                                        padding: EdgeInsets.all(screenWidth * 0.04),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.grey[900]
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: screenWidth * 0.015,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: screenWidth * 0.06,
                                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.grey[600]
                                                  : Colors.grey[300],
                                              child: review["ClientImage"] != null
                                                  ? ClipOval(
                                                      child: Image.network(
                                                        review["ClientImage"],
                                                        fit: BoxFit.cover,
                                                        width: screenWidth * 0.12,
                                                        height: screenWidth * 0.12,
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
                                            SizedBox(width: screenWidth * 0.04),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        review["ClientName"] ?? "Unknown",
                                                        style: GoogleFonts.nunitoSans(
                                                          fontSize: screenWidth * 0.045,
                                                          fontWeight: FontWeight.w700,
                                                          color: Theme.of(context).brightness == Brightness.dark
                                                              ? Colors.white
                                                              : Colors.black87,
                                                        ),
                                                      ),
                                                      Text(
                                                        formatRelativeTime(review["CreatedAt"] ?? ""),
                                                        style: GoogleFonts.nunitoSans(
                                                          fontSize: screenWidth * 0.035,
                                                          fontWeight: FontWeight.w500,
                                                          color: Theme.of(context).brightness == Brightness.dark
                                                              ? Colors.grey[400]
                                                              : Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: screenHeight * 0.005),
                                                  Row(
                                                    children: List.generate(
                                                      5,
                                                      (index) => Icon(
                                                        Icons.star,
                                                        color: index < (review["Product_Rate"] as num).toInt()
                                                            ? const Color(0xFF0C8A7B)
                                                            : Theme.of(context).brightness == Brightness.dark
                                                                ? Colors.grey[600]
                                                                : Colors.grey[300],
                                                        size: screenWidth * 0.045,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: screenHeight * 0.01),
                                                  Text(
                                                    review["Comment"] ?? "",
                                                    style: GoogleFonts.nunitoSans(
                                                      fontSize: screenWidth * 0.04,
                                                      fontWeight: FontWeight.w400,
                                                      color: Theme.of(context).brightness == Brightness.dark
                                                          ? Colors.grey[400]
                                                          : Colors.black54,
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            if (reviews.isEmpty)
                              Center(
                                child: Text(
                                  "No reviews available",
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[400]
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                          ],
                        );
                      }
                    },
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Edit_Product(
                              productId: widget.product['ProductID'].toString(),
                              productData: {
                                'ProductName': widget.product['ProductName'] ?? '',
                                'Price': widget.product['Price'] ?? 0.0,
                                'Quantity': widget.product['Quantity'] ?? 0,
                                'Description': widget.product['Description'] ?? '',
                                'Category': widget.product['Category'] ??
                                    widget.product['CategoryName'] ??
                                    widget.product['Cat_Type'] ??
                                    '',
                                'Status': widget.product['Status'] ?? 'Available',
                                'Images': widget.product['Images'] ?? [],
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C8A7B),
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        'EDIT',
                        style: GoogleFonts.nunitoSans(
                          fontSize: screenWidth * 0.045,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}