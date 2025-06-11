import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:herfa/client/artisan_profile/artisan_profile.dart';
import 'package:herfa/client/top_icon/favoriteProvider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetails({super.key, required this.product});

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Future<Map<String, dynamic>> _productDetailsFuture = Future.value({});
  Future<Map<String, dynamic>> _ratingsFuture = Future.value({});
  final PageController _pageController = PageController();
  late AnimationController _favoriteController;

  @override
  void initState() {
    super.initState();
    print('ProductID: ${widget.product['ProductID']}');
    _loadData();
    _favoriteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _loadData() async {
    bool isConnected = await _checkInternetConnection();
    print('Internet connection: $isConnected');
    if (!isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Connection Error"),
            content: const Text(
                "No internet connection. Please check your network and try again."),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.white,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      });
      setState(() {
        _productDetailsFuture =
            Future.value({"error": "No internet connection"});
        _ratingsFuture = Future.value({"error": "No internet connection"});
        print('ProductDetailsFuture set to error: No internet connection');
      });
      return;
    }

    setState(() {
      _productDetailsFuture =
          _apiService.getProductDetails(widget.product['ProductID'] as int);
      _ratingsFuture =
          _apiService.getProductRatings(widget.product['ProductID'].toString());
      print(
          'ProductDetailsFuture set to API call for ProductID: ${widget.product['ProductID']}');
    });
  }

  // void _fetchRatings() {
  //   _ratingsFuture = _apiService.getProductRatings(widget.product['ProductID'].toString());
  // }

  Future<void> _onRefresh() async {
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Connection Error"),
          content: const Text(
              "No internet connection. Please check your network and try again."),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _productDetailsFuture =
          _apiService.getProductDetails(widget.product['ProductID'] as int);
      _ratingsFuture =
          _apiService.getProductRatings(widget.product['ProductID'].toString());
      print(
          'Refreshing ProductDetails for ProductID: ${widget.product['ProductID']}');
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
  void dispose() {
    _pageController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

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
          color: const Color(0xFF0C8A7B),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _productDetailsFuture,
            builder: (context, productSnapshot) {
              print(
                  'ProductDetails FutureBuilder state: ${productSnapshot.connectionState}');
              if (productSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : const Color(0xFF0C8A7B),
                  ),
                );
              } else if (productSnapshot.hasError ||
                  productSnapshot.data?.containsKey("error") == true) {
                print(
                    'ProductDetails FutureBuilder error: ${productSnapshot.error ?? productSnapshot.data?["error"]}');
                return Center(
                  child: Text(
                    productSnapshot.data?["error"] ??
                        "Error loading product details: ${productSnapshot.error}",
                    style: GoogleFonts.nunitoSans(
                      fontSize: screenWidth * 0.04,
                      color: Colors.red,
                    ),
                  ),
                );
              }

              final productData = productSnapshot.data!;
              print('ProductDetails data loaded: $productData');
              final images = productData['images'] as List<dynamic>? ?? [];
              final productName =
                  productData['name']?.toString() ?? 'Unknown Product';
              final description = productData['description']?.toString() ??
                  'No description available';
              final quantity = productData['quantity']?.toString() ?? 'N/A';
              final status = productData['status']?.toString() ?? 'Unknown';
              final category = productData['category']?.toString() ?? 'N/A';
              final price = (productData['price'] as num?)?.toDouble() ?? 0.0;

              final artisanData =
                  productData['artisan'] as Map<String, dynamic>?;
              Artisan? artisan;
              if (artisanData != null) {
                try {
                  artisan = Artisan.fromJson(artisanData);
                } catch (e) {}
              }

              bool isOutOfStock = status == 'Not Available' ||
                  (int.tryParse(quantity) ?? 0) == 0;

              return SingleChildScrollView(
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
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.04),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: screenWidth * 0.02,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.04),
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    images.isNotEmpty ? images.length : 1,
                                itemBuilder: (context, index) {
                                  if (images.isEmpty) {
                                    print('No images available for product');
                                    return Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: screenWidth * 0.13,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[400]
                                            : Colors.grey,
                                      ),
                                    );
                                  }
                                  print('Loading image: ${images[index]}');
                                  return CachedNetworkImage(
                                    imageUrl: images[index].toString(),
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: screenHeight * 0.4,
                                    httpHeaders: const {
                                      'Accept': 'image/*',
                                      'Connection': 'keep-alive',
                                    },
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white70
                                            : const Color(0xFF0C8A7B),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) {
                                      print(
                                          'Image load error: $error, URL: $url');
                                      return Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: screenWidth * 0.13,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
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
                      SizedBox(height: screenHeight * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (artisan == null || artisan.ssn.isEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Error"),
                                    content: const Text(
                                        'Cannot view artisan profile: Invalid artisan data'),
                                    backgroundColor:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[900]
                                            : Colors.white,
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("OK"),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ArtisanProfileforClient(
                                    artisanSSN: artisan!.ssn,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: screenWidth * 0.05,
                                  backgroundColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[600]
                                          : Colors.grey[200],
                                  child: artisan != null &&
                                          artisan.profileImage != null &&
                                          artisan.profileImage!.isNotEmpty
                                      ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: artisan.profileImage!,
                                            fit: BoxFit.cover,
                                            width: screenWidth * 0.1,
                                            height: screenWidth * 0.1,
                                            httpHeaders: const {
                                              'Accept': 'image/*',
                                              'Connection': 'keep-alive',
                                            },
                                            placeholder: (context, url) =>
                                                CircularProgressIndicator(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white70
                                                  : const Color(0xFF0C8A7B),
                                              strokeWidth: 2,
                                            ),
                                            errorWidget: (context, url, error) {
                                              return Icon(
                                                Icons.person,
                                                size: screenWidth * 0.05,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[400]
                                                    : Colors.grey,
                                              );
                                            },
                                          ),
                                        )
                                      : Icon(
                                          Icons.person,
                                          size: screenWidth * 0.05,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[400]
                                              : Colors.grey,
                                        ),
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  artisan != null && artisan.fullName.isNotEmpty
                                      ? artisan.fullName
                                      : 'Artisan',
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ScaleTransition(
                            scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                              CurvedAnimation(
                                parent: _favoriteController,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                favoritesProvider
                                        .isFavorite(widget.product['ProductID'])
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: const Color(0xFF0C8A7B),
                                size: screenWidth * 0.07,
                              ),
                              onPressed: () async {
                                bool isConnected =
                                    await _checkInternetConnection();
                                if (!isConnected) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Connection Error"),
                                      content: const Text(
                                          "No internet connection. Please check your network and try again."),
                                      backgroundColor:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[900]
                                              : Colors.white,
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                _favoriteController.forward(from: 0);
                                try {
                                  if (favoritesProvider.isFavorite(
                                      widget.product['ProductID'])) {
                                    await favoritesProvider.removeFavorite(
                                        widget.product['ProductID']);
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Success"),
                                        content: const Text(
                                            'Product removed from favorites!'),
                                        backgroundColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[900]
                                                : Colors.white,
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    await favoritesProvider.addFavorite(
                                        widget.product['ProductID']);
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Success"),
                                        content: const Text(
                                            'Product added to favorites!'),
                                        backgroundColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[900]
                                                : Colors.white,
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Error"),
                                      content: Text(
                                          'Failed to update favorites: $e'),
                                      backgroundColor:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[900]
                                              : Colors.white,
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: GoogleFonts.nunitoSans(
                              fontSize: screenWidth * 0.07,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
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
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.black54,
                              ),
                            ),
                        ],
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[900]
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.03),
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
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  quantity,
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
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
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
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
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : const Color(0xFF0C8A7B),
                              ),
                            );
                          } else if (snapshot.hasError ||
                              snapshot.data?.containsKey("error") == true) {
                            return Center(
                              child: Text(
                                snapshot.data?["error"] ??
                                    "Error loading reviews",
                                style: GoogleFonts.nunitoSans(
                                  fontSize: screenWidth * 0.04,
                                  color: Colors.red,
                                ),
                              ),
                            );
                          } else {
                            final ratingsData = snapshot.data!;
                            final reviews =
                                ratingsData["reviews"] as List<dynamic>? ?? [];
                            final averageRating =
                                ratingsData["averageRating"]?.toDouble() ?? 0.0;
                            final ratingCount =
                                ratingsData["ratingCount"] as int? ?? 0;

                            Map<int, double> ratingDistribution = {
                              5: 0.0,
                              4: 0.0,
                              3: 0.0,
                              2: 0.0,
                              1: 0.0
                            };
                            if (reviews.isNotEmpty) {
                              Map<int, int> ratingCounts = {
                                5: 0,
                                4: 0,
                                3: 0,
                                2: 0,
                                1: 0
                              };
                              for (var review in reviews) {
                                int ratingValue =
                                    (review["Product_Rate"] as num).toInt();
                                ratingCounts[ratingValue] =
                                    (ratingCounts[ratingValue] ?? 0) + 1;
                              }
                              ratingDistribution =
                                  ratingCounts.map((rating, count) => MapEntry(
                                        rating,
                                        reviews.isNotEmpty
                                            ? (count / reviews.length) * 100
                                            : 0.0,
                                      ));
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reviews',
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                Container(
                                  padding: EdgeInsets.all(screenWidth * 0.04),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[900]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        screenWidth * 0.03),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: screenWidth * 0.015,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Text(
                                                  "${averageRating.toStringAsFixed(1)} OUT OF 5",
                                                  style: GoogleFonts.nunitoSans(
                                                    fontSize:
                                                        screenWidth * 0.06,
                                                    fontWeight: FontWeight.w800,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                ),
                                                SizedBox(
                                                    width: screenWidth * 0.03),
                                                Row(
                                                  children: List.generate(
                                                    5,
                                                    (index) => Icon(
                                                      Icons.star,
                                                      color: index <
                                                              averageRating
                                                                  .round()
                                                          ? const Color(
                                                              0xFF0C8A7B)
                                                          : Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.grey[600]
                                                              : Colors
                                                                  .grey[300],
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
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[400]
                                              : Colors.grey,
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.02),
                                      Column(
                                        children: List.generate(5, (index) {
                                          int star = 5 - index;
                                          double percentage =
                                              ratingDistribution[star] ?? 0.0;
                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical:
                                                    screenHeight * 0.0075),
                                            child: Row(
                                              children: [
                                                Text(
                                                  "$star",
                                                  style: GoogleFonts.nunitoSans(
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                ),
                                                SizedBox(
                                                    width: screenWidth * 0.03),
                                                Expanded(
                                                  child:
                                                      LinearProgressIndicator(
                                                    value: percentage / 100,
                                                    backgroundColor: Theme.of(
                                                                    context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey[600]
                                                        : Colors.grey[200],
                                                    valueColor:
                                                        const AlwaysStoppedAnimation<
                                                                Color>(
                                                            Color(0xFF0C8A7B)),
                                                    minHeight:
                                                        screenHeight * 0.01,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            screenWidth * 0.01),
                                                  ),
                                                ),
                                                SizedBox(
                                                    width: screenWidth * 0.03),
                                                Text(
                                                  "${percentage.toStringAsFixed(0)}%",
                                                  style: GoogleFonts.nunitoSans(
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
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
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.03),
                                if (reviews.isNotEmpty)
                                  Column(
                                    children:
                                        reviews.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final review = entry.value;
                                      return AnimatedOpacity(
                                        opacity: 1.0,
                                        duration: Duration(
                                            milliseconds: 500 + (index * 200)),
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              bottom: screenHeight * 0.02),
                                          child: Container(
                                            padding: EdgeInsets.all(
                                                screenWidth * 0.04),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[900]
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      screenWidth * 0.03),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius:
                                                      screenWidth * 0.015,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                  radius: screenWidth * 0.06,
                                                  backgroundColor:
                                                      Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.grey[600]
                                                          : Colors.grey[300],
                                                  child: review[
                                                              "ClientImage"] !=
                                                          null
                                                      ? ClipOval(
                                                          child:
                                                              CachedNetworkImage(
                                                            imageUrl: review[
                                                                "ClientImage"],
                                                            fit: BoxFit.cover,
                                                            width: screenWidth *
                                                                0.12,
                                                            height:
                                                                screenWidth *
                                                                    0.12,
                                                            httpHeaders: const {
                                                              'Accept':
                                                                  'image/*',
                                                              'Connection':
                                                                  'keep-alive',
                                                            },
                                                            placeholder: (context,
                                                                    url) =>
                                                                CircularProgressIndicator(
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                      Color>(
                                                                Theme.of(context).brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors
                                                                        .white70
                                                                    : const Color(
                                                                        0xFF0C8A7B),
                                                              ),
                                                            ),
                                                            errorWidget:
                                                                (context, url,
                                                                    error) {
                                                              return Icon(
                                                                Icons.person,
                                                                color: Colors
                                                                    .white,
                                                              );
                                                            },
                                                          ),
                                                        )
                                                      : Icon(
                                                          Icons.person,
                                                          color: Colors.white,
                                                        ),
                                                ),
                                                SizedBox(
                                                    width: screenWidth * 0.04),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            review["ClientName"] ??
                                                                "Unknown",
                                                            style: GoogleFonts
                                                                .nunitoSans(
                                                              fontSize:
                                                                  screenWidth *
                                                                      0.045,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .dark
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black87,
                                                            ),
                                                          ),
                                                          Text(
                                                            formatRelativeTime(
                                                                review["CreatedAt"] ??
                                                                    ""),
                                                            style: GoogleFonts
                                                                .nunitoSans(
                                                              fontSize:
                                                                  screenWidth *
                                                                      0.035,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .dark
                                                                  ? Colors
                                                                      .grey[400]
                                                                  : Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(
                                                          height: screenHeight *
                                                              0.005),
                                                      Row(
                                                        children: List.generate(
                                                          5,
                                                          (index) => Icon(
                                                            Icons.star,
                                                            color: index <
                                                                    (review["Product_Rate"]
                                                                            as num)
                                                                        .toInt()
                                                                ? const Color(
                                                                    0xFF0C8A7B)
                                                                : Theme.of(context)
                                                                            .brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors.grey[
                                                                        600]
                                                                    : Colors.grey[
                                                                        300],
                                                            size: screenWidth *
                                                                0.045,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                          height: screenHeight *
                                                              0.01),
                                                      Text(
                                                        review["Comment"] ?? "",
                                                        style: GoogleFonts
                                                            .nunitoSans(
                                                          fontSize:
                                                              screenWidth *
                                                                  0.04,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
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
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
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
                        child: isOutOfStock
                            ? Text(
                                "Product is out of stock",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  color: Colors.red,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              )
                            : ElevatedButton(
                                onPressed: () async {
                                  bool isConnected =
                                      await _checkInternetConnection();
                                  if (!isConnected) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Connection Error"),
                                        content: const Text(
                                            "No internet connection. Please check your network and try again."),
                                        backgroundColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[900]
                                                : Colors.white,
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }

                                  try {
                                    final productId =
                                        widget.product['ProductID'] as int? ??
                                            0;
                                    await _apiService.addToCart(productId);
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Success"),
                                        content: const Text(
                                            'Product added to cart successfully!'),
                                        backgroundColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[900]
                                                : Colors.white,
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                  } catch (e) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Error"),
                                        content: Text(
                                            'Failed to add product to cart: $e'),
                                        backgroundColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[900]
                                                : Colors.white,
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0C8A7B),
                                  padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.02),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        screenWidth * 0.03),
                                  ),
                                  elevation: 5,
                                ),
                                child: Text(
                                  'Add to Cart',
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
              );
            },
          ),
        ),
      ),
    );
  }
}
