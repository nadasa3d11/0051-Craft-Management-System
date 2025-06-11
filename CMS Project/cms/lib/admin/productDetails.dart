import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:herfa/admin/artisanProfile.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProductDetailsforArtisanPage extends StatefulWidget {
  final int productId;
  final String ssn;

  const ProductDetailsforArtisanPage({super.key, required this.productId, required this.ssn});

  @override
  _ProductDetailsforArtisanPageState createState() => _ProductDetailsforArtisanPageState();
}

class _ProductDetailsforArtisanPageState extends State<ProductDetailsforArtisanPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _productDetailsFuture;
  late Future<Map<String, dynamic>> _ratingsFuture;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _productDetailsFuture = _apiService.getProductDetails(widget.productId);
      _ratingsFuture = _apiService.getProductRatings(widget.productId.toString());
    });
  }

  Future<void> _onRefresh() async {
    _fetchData();
    await Future.wait([_productDetailsFuture, _ratingsFuture]);
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

  Future<void> _deleteProduct() async {
    bool confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Product',
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this product?',
          style: GoogleFonts.nunitoSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No',
              style: GoogleFonts.nunitoSans(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes',
              style: GoogleFonts.nunitoSans(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      String result = await _apiService.deleteProductAdmin(widget.productId);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text(
              'Deletion Result',
              style: GoogleFonts.nunitoSans(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Text(
              result,
              style: GoogleFonts.nunitoSans(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArtisanProfile(ssn: widget.ssn),
                    ),
                  );
                },
                child: Text(
                  'OK',
                  style: GoogleFonts.nunitoSans(),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Details',
          style: GoogleFonts.nunitoSans(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _productDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data?.containsKey("error") == true) {
            return Center(
              child: Text(
                snapshot.data?["error"] ?? "Error loading product details",
                style: GoogleFonts.nunitoSans(
                  fontSize: screenWidth * 0.04,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            );
          } else {
            final productData = snapshot.data!;
            final images = productData['images'] as List<dynamic>? ?? [];
            final productName = productData['name']?.toString() ?? 'Unknown Product';
            final description = productData['description']?.toString() ?? 'No description available';
            final quantity = productData['quantity']?.toString() ?? 'N/A';
            final status = productData['status']?.toString() ?? 'Unknown';
            final category = productData['category']?.toString() ?? 'Unknown';
            final price = (productData['price'] as num?)?.toDouble() ?? 0.0;

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).colorScheme.surfaceVariant,
                  ],
                ),
              ),
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: screenHeight * 0.4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(screenWidth * 0.04),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor.withOpacity(0.1),
                                blurRadius: 8,
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
                                          size: screenWidth * 0.12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: screenWidth * 0.12,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                          dotColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          category,
                          style: GoogleFonts.nunitoSans(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'About The Product',
                          style: GoogleFonts.nunitoSans(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          description,
                          style: GoogleFonts.nunitoSans(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            height: 1.5,
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
                        SizedBox(height: screenHeight * 0.03),
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor.withOpacity(0.1),
                                blurRadius: 6,
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
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.005),
                                  Text(
                                    quantity,
                                    style: GoogleFonts.nunitoSans(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
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
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
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
                                          : Theme.of(context).colorScheme.error,
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
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError ||
                                snapshot.data?.containsKey("error") == true) {
                              return Center(
                                child: Text(
                                  snapshot.data?["error"] ?? "Error loading reviews",
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: screenWidth * 0.04,
                                    color: Theme.of(context).colorScheme.error,
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
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.expand_more,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.015),
                                  Container(
                                    padding: EdgeInsets.all(screenWidth * 0.04),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                                          blurRadius: 6,
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
                                                      color: Theme.of(context).textTheme.bodyLarge?.color,
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
                                                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.02),
                                        Column(
                                          children: List.generate(5, (index) {
                                            int star = 5 - index;
                                            double percentage = ratingDistribution[star] ?? 0.0;
                                            return Padding(
                                              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.007),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    "$star",
                                                    style: GoogleFonts.nunitoSans(
                                                      fontSize: screenWidth * 0.04,
                                                      fontWeight: FontWeight.w600,
                                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                                    ),
                                                  ),
                                                  SizedBox(width: screenWidth * 0.03),
                                                  Expanded(
                                                    child: LinearProgressIndicator(
                                                      value: percentage / 100,
                                                      backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
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
                                                      color: Theme.of(context).textTheme.bodyLarge?.color,
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
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
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
                                                color: Theme.of(context).cardColor,
                                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  CircleAvatar(
                                                    radius: screenWidth * 0.06,
                                                    backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                                                    child: review["ClientImage"] != null
                                                        ? ClipOval(
                                                            child: Image.network(
                                                              review["ClientImage"],
                                                              fit: BoxFit.cover,
                                                              width: screenWidth * 0.12,
                                                              height: screenWidth * 0.12,
                                                              loadingBuilder: (context, child,
                                                                  loadingProgress) {
                                                                if (loadingProgress == null)
                                                                  return child;
                                                                return CircularProgressIndicator(
                                                                  value: loadingProgress
                                                                              .expectedTotalBytes !=
                                                                          null
                                                                      ? loadingProgress
                                                                              .cumulativeBytesLoaded /
                                                                          (loadingProgress
                                                                                  .expectedTotalBytes ??
                                                                              1)
                                                                      : null,
                                                                );
                                                              },
                                                              errorBuilder:
                                                                  (context, error, stackTrace) {
                                                                return Icon(
                                                                  Icons.person,
                                                                  color: Theme.of(context)
                                                                      .colorScheme.onSurface,
                                                                );
                                                              },
                                                            ),
                                                          )
                                                        : Icon(
                                                            Icons.person,
                                                            color: Theme.of(context).colorScheme.onSurface,
                                                          ),
                                                  ),
                                                  SizedBox(width: screenWidth * 0.04),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                              review["ClientName"] ?? "Unknown",
                                                              style: GoogleFonts.nunitoSans(
                                                                fontSize: screenWidth * 0.045,
                                                                fontWeight: FontWeight.w700,
                                                                color: Theme.of(context)
                                                                    .textTheme
                                                                    .bodyLarge
                                                                    ?.color,
                                                              ),
                                                            ),
                                                            Text(
                                                              formatRelativeTime(
                                                                  review["CreatedAt"] ?? ""),
                                                              style: GoogleFonts.nunitoSans(
                                                                fontSize: screenWidth * 0.035,
                                                                fontWeight: FontWeight.w500,
                                                                color: Theme.of(context)
                                                                    .textTheme
                                                                    .bodyMedium
                                                                    ?.color,
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
                                                              color: index <
                                                                      (review["Product_Rate"]
                                                                              as num)
                                                                          .toInt()
                                                                  ? const Color(0xFF0C8A7B)
                                                                  : Theme.of(context)
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .withOpacity(0.3),
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
                                                            color: Theme.of(context)
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.color,
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
                                          color: Theme.of(context).textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            }
                          },
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _deleteProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                  ),
                                  elevation: 5,
                                ),
                                child: Text(
                                  'DELETE',
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: screenWidth * 0.045,
                                    color: Theme.of(context).colorScheme.onError,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
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
                                  'BACK',
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: screenWidth * 0.045,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.03),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}