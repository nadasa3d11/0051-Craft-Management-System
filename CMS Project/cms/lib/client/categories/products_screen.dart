import 'dart:io';
import 'package:flutter/material.dart';
import 'package:herfa/client/artisan_profile/artisan_profile.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:herfa/client/top_icon/favoriteProvider.dart';
import 'package:provider/provider.dart';
import '../home_screen/details_screen.dart';
import '../top_icon/search/search_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String categoryName;

  const ProductsScreen({super.key, required this.categoryName});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin {
  late Future<List<Product>> _productsFuture;
  final Map<int, AnimationController> _favoriteControllers = {};

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchFullProducts();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<List<Product>> _fetchFullProducts() async {
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
      return [];
    }

    final apiService = ApiService();
    final products =
        await apiService.fetchProductsByCategory(widget.categoryName);
    final fullProducts = await Future.wait(
      products.map((product) => apiService.fetchProductById(product.productId)),
    );
    return fullProducts;
  }

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
      _productsFuture = _fetchFullProducts();
    });
    await Provider.of<FavoritesProvider>(context, listen: false)
        .refreshFavorites();
  }

  @override
  void dispose() {
    _favoriteControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87);
    final secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.black54);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : const Color(0xFF0C8A7B),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.categoryName,
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : const Color(0xFF0C8A7B),
            ),
            iconSize: screenWidth * 0.08,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
        ],
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
          child: FutureBuilder<List<Product>>(
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
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    "No products available for this category.",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: secondaryTextColor,
                    ),
                  ),
                );
              }

              final products = snapshot.data!;

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(screenWidth * 0.04),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final rating = product.ratingAverage ?? 0.0;

                  _favoriteControllers.putIfAbsent(
                    product.productId,
                    () => AnimationController(
                      vsync: this,
                      duration: const Duration(milliseconds: 300),
                    ),
                  );

                  bool isOutOfStock = product.status == 'Not Available' ||
                      (product.quantity ?? 0) == 0;

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
                      elevation: 2,
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color.fromARGB(255, 255, 255, 255)
                          : Theme.of(context).cardColor,
                      margin: EdgeInsets.only(bottom: screenWidth * 0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: screenWidth * 0.32,
                                  height: screenWidth * 0.32,
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            screenWidth * 0.04),
                                        child: product.images.isNotEmpty
                                            ? Image.network(
                                                product.images.first,
                                                width: screenWidth * 0.32,
                                                height: screenWidth * 0.32,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      size: screenWidth * 0.13,
                                                      color: secondaryTextColor,
                                                    ),
                                                  );
                                                },
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white70
                                                          : const Color(
                                                              0xFF0C8A7B),
                                                    ),
                                                  );
                                                },
                                              )
                                            : Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: screenWidth * 0.13,
                                                  color: secondaryTextColor,
                                                ),
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
                                                  product.productId]!,
                                              curve: Curves.easeInOut,
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              favoritesProvider.isFavorite(
                                                      product.productId)
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: const Color(0xFF0C8A7B),
                                              size: screenWidth * 0.06,
                                            ),
                                            onPressed: () async {
                                              bool isConnected =
                                                  await _checkInternetConnection();
                                              if (!isConnected) {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: const Text(
                                                        "Connection Error"),
                                                    content: const Text(
                                                        "No internet connection. Please check your network and try again."),
                                                    backgroundColor: Theme.of(
                                                                    context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey[900]
                                                        : Colors.white,
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: const Text("OK"),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                return;
                                              }

                                              _favoriteControllers[
                                                      product.productId]!
                                                  .forward(from: 0);
                                              try {
                                                if (favoritesProvider
                                                    .isFavorite(
                                                        product.productId)) {
                                                  await favoritesProvider
                                                      .removeFavorite(
                                                          product.productId);
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      title:
                                                          const Text("Success"),
                                                      content: const Text(
                                                          'Product removed from favorites!'),
                                                      backgroundColor: Theme.of(
                                                                      context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.grey[900]
                                                          : Colors.white,
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child:
                                                              const Text("OK"),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                } else {
                                                  await favoritesProvider
                                                      .addFavorite(
                                                          product.productId);
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      title:
                                                          const Text("Success"),
                                                      content: const Text(
                                                          'Product added to favorites!'),
                                                      backgroundColor: Theme.of(
                                                                      context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.grey[900]
                                                          : Colors.white,
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child:
                                                              const Text("OK"),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: const Text("Error"),
                                                    content: Text(
                                                        'Failed to update favorites: $e'),
                                                    backgroundColor: Theme.of(
                                                                    context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey[900]
                                                        : Colors.white,
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: const Text("OK"),
                                                      ),
                                                    ],
                                                  ),
                                                );
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
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: const Text("Error"),
                                                  content: const Text(
                                                      'Cannot view artisan profile: Invalid SSN'),
                                                  backgroundColor:
                                                      Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.grey[900]
                                                          : Colors.white,
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
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
                                            backgroundImage:
                                                product.artisan?.profileImage !=
                                                            null &&
                                                        product
                                                            .artisan!
                                                            .profileImage!
                                                            .isNotEmpty
                                                    ? NetworkImage(product
                                                        .artisan!.profileImage!)
                                                    : const AssetImage(
                                                            'assets/cms.png')
                                                        as ImageProvider,
                                            onBackgroundImageError:
                                                (error, stackTrace) {},
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) {
                                    if (index < rating.floor()) {
                                      return Icon(
                                        Icons.star,
                                        color: const Color(0xFF0C8A7B),
                                        size: screenWidth * 0.06,
                                      );
                                    } else if (index < rating) {
                                      return Icon(
                                        Icons.star_half,
                                        color: const Color(0xFF0C8A7B),
                                        size: screenWidth * 0.06,
                                      );
                                    }
                                    return Icon(
                                      Icons.star_border,
                                      color: secondaryTextColor,
                                      size: screenWidth * 0.06,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    product.description,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      color: secondaryTextColor,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Qty: ${product.quantity ?? 'N/A'}  ",
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        "${product.price.toStringAsFixed(2)} LE",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Color(0xFF0C8A7B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  SizedBox(
                                    width: double.infinity,
                                    child: isOutOfStock
                                        ? Text(
                                            "Product is out of stock",
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.04,
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
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: const Text(
                                                        "Connection Error"),
                                                    content: const Text(
                                                        "No internet connection. Please check your network and try again."),
                                                    backgroundColor: Theme.of(
                                                                    context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey[900]
                                                        : Colors.white,
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: const Text("OK"),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                return;
                                              }

                                              try {
                                                await ApiService().addToCart(
                                                    product.productId);
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title:
                                                        const Text("Success"),
                                                    content: const Text(
                                                        'Product added to cart successfully!'),
                                                    backgroundColor: Theme.of(
                                                                    context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey[900]
                                                        : Colors.white,
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: const Text("OK"),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              } catch (e) {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: const Text("Error"),
                                                    content: Text(
                                                        'Failed to add product to cart: $e'),
                                                    backgroundColor: Theme.of(
                                                                    context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey[900]
                                                        : Colors.white,
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: const Text("OK"),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF0C8A7B),
                                              padding: EdgeInsets.symmetric(
                                                  vertical:
                                                      screenHeight * 0.015),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        screenWidth * 0.05),
                                              ),
                                            ),
                                            child: Text(
                                              "Add to cart",
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.black
                                                    : Colors.white,
                                                fontSize: screenWidth * 0.04,
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
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
