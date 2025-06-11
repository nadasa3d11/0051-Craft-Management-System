import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:herfa/client/artisan_profile/artisan_profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:herfa/client/top_icon/favoriteProvider.dart';
import 'package:provider/provider.dart';
import 'details_screen.dart';
import 'dart:io';

class AllProductsScreen extends StatefulWidget {
  final String productType;
  final Future<List<Product>> productsFuture;

  const AllProductsScreen({
    super.key,
    required this.productType,
    required this.productsFuture,
  });

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final Map<int, AnimationController> _favoriteControllers = {};
  List<Product> allProducts = [];
  List<Product> displayedProducts = [];
  int currentPage = 1;
  final int pageSize = 10;
  bool isLoadingMore = false;
  bool hasMore = true;

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Error',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: Colors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.productType == "All") {
      _loadAllProducts();
    } else {
      widget.productsFuture.then((products) {
        setState(() {
          allProducts = products
            ..sort((a, b) => (a.productId ?? 0).compareTo(b.productId ?? 0));
          displayedProducts = allProducts.take(pageSize).toList();
          hasMore = allProducts.length > pageSize;
        });
      }).catchError((e) async {
        setState(() {
          isLoadingMore = false;
        });
        if (!await _checkInternetConnection()) {
          _showErrorDialog('No internet connection. Please check your network.');
        } else {
          _showErrorDialog('Failed to load initial products: $e');
        }
      });
    }
    _scrollController.addListener(() {
      final pixels = _scrollController.position.pixels;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final triggerPoint = maxScroll - 200;
      if (pixels >= triggerPoint && !isLoadingMore && hasMore) {
        _loadMoreProducts();
      }
    });
  }

  Future<void> _loadAllProducts() async {
    setState(() {
      isLoadingMore = true;
    });
    try {
      final products = await _apiService.fetchAllProductsFull2();
      setState(() {
        allProducts = products
          ..sort((a, b) => (a.productId ?? 0).compareTo(b.productId ?? 0));
        displayedProducts = allProducts.take(pageSize).toList();
        currentPage++;
        isLoadingMore = false;
        hasMore = allProducts.length > pageSize;
      });
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
      if (!await _checkInternetConnection()) {
        _showErrorDialog('No internet connection. Please check your network.');
      } else {
        _showErrorDialog('Failed to load products: $e');
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (isLoadingMore || !hasMore) {
      return;
    }
    setState(() {
      isLoadingMore = true;
    });
    try {
      final startIndex = displayedProducts.length;
      final endIndex = startIndex + pageSize > allProducts.length
          ? allProducts.length
          : startIndex + pageSize;

      if (startIndex >= allProducts.length) {
        setState(() {
          isLoadingMore = false;
          hasMore = false;
        });
        return;
      }

      final newProducts = allProducts.sublist(startIndex, endIndex);
      setState(() {
        displayedProducts.addAll(newProducts);
        isLoadingMore = false;
        hasMore = endIndex < allProducts.length;
        currentPage = (displayedProducts.length / pageSize).ceil();
      });
    } catch (error) {
      setState(() {
        isLoadingMore = false;
      });
      if (!await _checkInternetConnection()) {
        _showErrorDialog('No internet connection. Please check your network.');
      } else {
        _showErrorDialog('Failed to load more products: $error');
      }
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      allProducts.clear();
      displayedProducts.clear();
      currentPage = 1;
      hasMore = true;
      isLoadingMore = false;
    });

    try {
      List<Product> products;
      if (widget.productType == "All") {
        products = await _apiService.fetchAllProductsFull2();
      } else {
        products = await _apiService.fetchLatestProducts();
      }

      setState(() {
        allProducts = products
          ..sort((a, b) => (a.productId ?? 0).compareTo(b.productId ?? 0));
        displayedProducts = allProducts.take(pageSize).toList();
        hasMore = allProducts.length > pageSize;
        isLoadingMore = false;
      });

      await Provider.of<FavoritesProvider>(context, listen: false)
          .refreshFavorites();
    } catch (e) {
      setState(() {
        isLoadingMore = false;
        displayedProducts = [];
      });
      if (!await _checkInternetConnection()) {
        _showErrorDialog('No internet connection. Please check your network.');
      } else {
        _showErrorDialog('Failed to refresh products. Please try again.');
      }
    }
  }

  Future<Product> _fetchProductWithArtisan(int productId) async {
    return await _apiService.fetchProductById(productId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _favoriteControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        centerTitle: true,
        title: Text(
          widget.productType == "All" ? "All Products" : "New Products",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        color: Colors.teal,
        child: isLoadingMore
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.teal,
                ),
              )
            : displayedProducts.isEmpty && widget.productType == "All"
                ? Center(
                    child: Text(
                      'No products available',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.04,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: screenWidth * 0.03,
                      mainAxisSpacing: screenHeight * 0.015,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: displayedProducts.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == displayedProducts.length && isLoadingMore) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.teal,
                          ),
                        );
                      }
                      final product = displayedProducts[index];
                      _favoriteControllers.putIfAbsent(
                        product.productId ?? 0,
                        () => AnimationController(
                          vsync: this,
                          duration: const Duration(milliseconds: 300),
                        ),
                      );
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetails(
                                product: {
                                  'ProductID': product.productId,
                                  'ProductName': product.name,
                                  'Price': product.price,
                                  'Quantity': product.quantity,
                                  'Description': product.description,
                                  'Category': product.category,
                                  'Status': product.status,
                                  'Images': product.images,
                                },
                              ),
                            ),
                          );
                        },
                        child: Card(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: screenHeight * 0.16,
                                width: double.infinity,
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                      ),
                                      child: product.images.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: product.images[0],
                                              fit: BoxFit.fill,
                                              width: double.infinity,
                                              height: screenHeight * 0.16,
                                              placeholder: (context, url) =>
                                                  Center(
                                                child: CircularProgressIndicator(
                                                  color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                      ? Colors.white70
                                                      : Colors.teal,
                                                ),
                                              ),
                                              errorWidget: (context, url,
                                                      error) =>
                                                  Icon(
                                                Icons.error,
                                                size: screenHeight * 0.06,
                                                color: Colors.grey,
                                              ),
                                            )
                                          : Icon(
                                              Icons.image_not_supported,
                                              size: screenHeight * 0.06,
                                              color: Colors.grey,
                                            ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: ScaleTransition(
                                        scale: Tween<double>(
                                                begin: 1.0, end: 1.3)
                                            .animate(
                                          CurvedAnimation(
                                            parent: _favoriteControllers[
                                                product.productId ?? 0]!,
                                            curve: Curves.easeInOut,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            favoritesProvider.isFavorite(
                                                    product.productId ?? 0)
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: const Color(0xFF0C8A7B),
                                            size: screenWidth * 0.06,
                                          ),
                                          onPressed: () async {
                                            _favoriteControllers[
                                                    product.productId ?? 0]!
                                                .forward(from: 0);
                                            try {
                                              if (favoritesProvider.isFavorite(
                                                  product.productId ?? 0)) {
                                                await favoritesProvider
                                                    .removeFavorite(
                                                        product.productId ?? 0);
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: Text(
                                                      'Success',
                                                      style: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                    content: Text(
                                                      'Product removed from favorites!',
                                                      style:
                                                          GoogleFonts.poppins(),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: Text(
                                                          'OK',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            color: Colors.teal,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              } else {
                                                await favoritesProvider
                                                    .addFavorite(
                                                        product.productId ?? 0);
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: Text(
                                                      'Success',
                                                      style: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                    content: Text(
                                                      'Product added to favorites!',
                                                      style:
                                                          GoogleFonts.poppins(),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: Text(
                                                          'OK',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            color: Colors.teal,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (!await _checkInternetConnection()) {
                                                _showErrorDialog(
                                                    'No internet connection. Please check your network.');
                                              } else {
                                                _showErrorDialog(
                                                    'Failed to update favorites: $e');
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: screenWidth * 0.015,
                                      left: screenWidth * 0.015,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (product.artisan?.ssn == null ||
                                              product.artisan!.ssn.isEmpty) {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(
                                                  'Error',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                content: Text(
                                                  'Cannot view artisan profile: Invalid artisan data',
                                                  style: GoogleFonts.poppins(),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: Text(
                                                      'OK',
                                                      style: GoogleFonts.poppins(
                                                        color: Colors.teal,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            return;
                                          }
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ArtisanProfileforClient(
                                                artisanSSN:
                                                    product.artisan!.ssn,
                                              ),
                                            ),
                                          );
                                        },
                                        child: CircleAvatar(
                                          radius: screenWidth * 0.035,
                                          backgroundColor:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[600]
                                                  : Colors.grey[200],
                                          child: (product.artisan?.profileImage
                                                      ?.isNotEmpty ??
                                                  false)
                                              ? ClipOval(
                                                  child: CachedNetworkImage(
                                                    imageUrl: product.artisan!
                                                        .profileImage!,
                                                    fit: BoxFit.cover,
                                                    width: screenWidth * 0.07,
                                                    height: screenWidth * 0.07,
                                                    placeholder: (context, url) =>
                                                        CircularProgressIndicator(
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white70
                                                          : Colors.teal,
                                                      strokeWidth: 2,
                                                    ),
                                                    errorWidget:
                                                        (context, url, error) {
                                                      return Icon(
                                                        Icons.person,
                                                        size:
                                                            screenWidth * 0.035,
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
                                                  size: screenWidth * 0.035,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.grey[400]
                                                      : Colors.grey,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name.isNotEmpty
                                          ? product.name
                                          : 'No Name',
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth * 0.032,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: screenHeight * 0.003),
                                    Text(
                                      product.description.isNotEmpty
                                          ? product.description
                                          : 'No Description',
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth * 0.028,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    Text(
                                      "${product.price} LE",
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth * 0.032,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.teal,
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
      ),
    );
  }
}