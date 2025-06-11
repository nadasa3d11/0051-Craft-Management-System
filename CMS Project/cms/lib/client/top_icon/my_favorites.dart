import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:herfa/client/artisan_profile/artisan_profile.dart';
import 'package:herfa/client/top_icon/favoriteProvider.dart';
import 'package:provider/provider.dart';
import '../home_screen/details_screen.dart';

class MyFavoritesScreen extends StatefulWidget {
  const MyFavoritesScreen({super.key});

  @override
  State<MyFavoritesScreen> createState() => _MyFavoritesScreenState();
}

class _MyFavoritesScreenState extends State<MyFavoritesScreen> with TickerProviderStateMixin {
  late Future<List<Product>> _favoritesFuture;
  final Map<int, AnimationController> _favoriteControllers = {};
  final Map<int, AnimationController> _cartControllers = {};

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _fetchFullFavoriteProducts();
  }

  Future<List<Product>> _fetchFullFavoriteProducts() async {
    try {
      final apiService = ApiService();
      final favorites = await apiService.fetchFavorites();
      final fullProducts = await Future.wait(
        favorites.map((product) => apiService.fetchProductById(product.productId)),
      );
      return fullProducts;
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
        throw Exception('No Internet Connection. Please check your connection and try again.');
      }
      throw Exception('Error fetching favorites: $e');
    }
  }

  @override
  void dispose() {
    _favoriteControllers.values.forEach((controller) => controller.dispose());
    _cartControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _favoritesFuture = _fetchFullFavoriteProducts();
    });
    await Provider.of<FavoritesProvider>(context, listen: false).refreshFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    int crossAxisCount = screenWidth < 600 ? 2 : (screenWidth < 900 ? 3 : 4);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Favorites",
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color ??
                (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        ),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFF0C8A7B),
          child: FutureBuilder<List<Product>>(
            future: _favoritesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        snapshot.error.toString(),
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      ElevatedButton(
                        onPressed: _onRefresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    "No favorite products available.",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                );
              }

              final products = snapshot.data!;

              return GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(screenWidth * 0.04),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: screenWidth * 0.04,
                  mainAxisSpacing: screenWidth * 0.04,
                  childAspectRatio: 0.55,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];

                  _favoriteControllers.putIfAbsent(
                    product.productId,
                    () => AnimationController(
                      vsync: this,
                      duration: const Duration(milliseconds: 300),
                    ),
                  );
                  _cartControllers.putIfAbsent(
                    product.productId,
                    () => AnimationController(
                      vsync: this,
                      duration: const Duration(milliseconds: 300),
                    ),
                  );

                  bool isOutOfStock = product.status == 'Not Available' || (product.quantity ?? 0) == 0;

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
                      elevation: 1,
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.04),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: screenWidth * 0.4,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(screenWidth * 0.04),
                                    topRight: Radius.circular(screenWidth * 0.04),
                                  ),
                                  child: FutureBuilder<String?>(
                                    future: AuthService().getAccessToken(),
                                    builder: (context, snapshot) {
                                      String? token = snapshot.data;
                                      return CachedNetworkImage(
                                        imageUrl: product.images.isNotEmpty ? product.images.first : '',
                                        width: double.infinity,
                                        height: screenWidth * 0.4,
                                        fit: BoxFit.cover,
                                        httpHeaders: token != null
                                            ? {'Authorization': 'Bearer $token'}
                                            : null,
                                        placeholder: (context, url) => Center(
                                          child: CircularProgressIndicator(
                                            color: Theme.of(context).colorScheme.onBackground,
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: screenWidth * 0.15,
                                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                                      CurvedAnimation(
                                        parent: _favoriteControllers[product.productId]!,
                                        curve: Curves.easeInOut,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.favorite,
                                        color: const Color(0xFF0C8A7B),
                                        size: screenWidth * 0.07,
                                      ),
                                      onPressed: () async {
                                        _favoriteControllers[product.productId]!.forward(from: 0);
                                        try {
                                          await favoritesProvider.removeFavorite(product.productId);
                                          setState(() {
                                            products.removeAt(index);
                                          });
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Success'),
                                              content: const Text('Product removed from favorites!'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                        } catch (e) {
                                          String errorMessage = 'Failed to update favorites: $e';
                                          if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
                                            errorMessage = 'No Internet Connection. Please check your connection and try again.';
                                          }
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Error'),
                                              content: Text(errorMessage),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('OK'),
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
                                      if (product.artisan?.ssn == null || product.artisan!.ssn.isEmpty) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Error'),
                                            content: const Text('Cannot view artisan profile: Invalid SSN'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('OK'),
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
                                            artisanSSN: product.artisan!.ssn,
                                          ),
                                        ),
                                      );
                                    },
                                    child: FutureBuilder<String?>(
                                      future: AuthService().getAccessToken(),
                                      builder: (context, tokenSnapshot) {
                                        String? token = tokenSnapshot.data;
                                        final profileImage = product.artisan?.profileImage;
                                        return CircleAvatar(
                                          radius: screenWidth * 0.035,
                                          backgroundColor: Theme.of(context).cardColor.withOpacity(0.7),
                                          child: (profileImage != null && profileImage.isNotEmpty)
                                              ? ClipOval(
                                                  child: CachedNetworkImage(
                                                    imageUrl: profileImage,
                                                    fit: BoxFit.cover,
                                                    width: screenWidth * 0.07,
                                                    height: screenWidth * 0.07,
                                                    httpHeaders: token != null
                                                        ? {'Authorization': 'Bearer $token'}
                                                        : null,
                                                    placeholder: (context, url) => CircularProgressIndicator(
                                                      color: Theme.of(context).colorScheme.onBackground,
                                                      strokeWidth: 2,
                                                    ),
                                                    errorWidget: (context, url, error) {
                                                      return Icon(
                                                        Icons.person,
                                                        size: screenWidth * 0.035,
                                                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.person,
                                                  size: screenWidth * 0.035,
                                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                                                ),
                                        );
                                      },
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
                                  product.name,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  "${product.price.toStringAsFixed(2)} LE",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0C8A7B),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Row(
                                  children: [
                                    RatingBarIndicator(
                                      rating: product.ratingAverage ?? 0.0,
                                      itemBuilder: (context, _) => const Icon(
                                        Icons.star,
                                        color: Color(0xFF0C8A7B),
                                      ),
                                      itemCount: 5,
                                      itemSize: screenWidth * 0.05,
                                      direction: Axis.horizontal,
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                SizedBox(
                                  width: double.infinity,
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 1.0, end: 0.95).animate(
                                      CurvedAnimation(
                                        parent: _cartControllers[product.productId]!,
                                        curve: Curves.easeInOut,
                                      ),
                                    ),
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
                                              _cartControllers[product.productId]!.forward(from: 0);
                                              try {
                                                await ApiService().addToCart(product.productId);
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Success'),
                                                    content: const Text('Product added to cart successfully!'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              } catch (e) {
                                                String errorMessage = 'Failed to add product to cart: $e';
                                                if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
                                                  errorMessage = 'No Internet Connection. Please check your connection and try again.';
                                                }
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Error'),
                                                    content: Text(errorMessage),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0C8A7B),
                                              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                              ),
                                            ),
                                            child: Text(
                                              "Add to cart",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: screenWidth * 0.04,
                                              ),
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
              );
            },
          ),
        ),
      ),
    );
  }
}