import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/aboutUs.dart';
import 'package:herfa/client/home_screen/details_screen.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:herfa/Shared%20Files/login_screen.dart';
import 'package:herfa/Shared%20Files/notificationSetting.dart';
import 'package:herfa/Shared%20Files/privacyPolicy.dart';
import 'package:herfa/Shared%20Files/support.dart';
import 'package:herfa/Shared%20Files/termsOfUse.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:herfa/client/top_icon/favoriteProvider.dart';
import 'package:provider/provider.dart';
import 'package:herfa/client/artisan_profile/artisan_profile.dart';
import '../categories/categories_screen.dart';
import 'all_products.dart';

class HomeforClient extends StatefulWidget {
  const HomeforClient({super.key});

  @override
  State<HomeforClient> createState() => _HomeforClientState();
}

class _HomeforClientState extends State<HomeforClient> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? userInfo;
  bool isLoading = true;
  late Future<List<Product>> allProducts;
  late Future<List<Product>> newProducts;
  final Map<int, AnimationController> _favoriteControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _favoriteControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _loadData() async {
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Connection Error"),
          content: const Text("No internet connection. Please check your network and try again."),
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
      setState(() {
        userInfo = null;
        allProducts = Future.value([]);
        newProducts = Future.value([]);
        isLoading = false;
      });
      return;
    }

    await _loadUserInfo();
    allProducts = _apiService.fetchAllProductsFull2();
    newProducts = _apiService.fetchLatestProducts();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadUserInfo() async {
    try {
      final data = await _apiService.getMyInformation();
      if (!data.containsKey('error')) {
        setState(() {
          userInfo = data;
        });
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: Text('Error: ${data["error"]}'),
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
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text('Error: $e'),
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
    }
  }

  Future<void> _onRefresh() async {
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Connection Error"),
          content: const Text("No internet connection. Please check your network and try again."),
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
      isLoading = true;
      allProducts = _apiService.fetchAllProductsFull2();
      newProducts = _apiService.fetchLatestProducts();
    });
    await _loadUserInfo();
    await Provider.of<FavoritesProvider>(context, listen: false).refreshFavorites();
    setState(() {
      isLoading = false;
    });
  }

  Widget buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.black),
          title: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          onTap: onTap,
        ),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 3,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ??
        (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87);

    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "HERFA",
          style: TextStyle(
            color: textColor,
            fontSize: screenWidth * 0.075,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CategoriesScreen()),
            );
          },
          icon: const Icon(
            Icons.category_sharp,
            size: 33,
            color: Color(0xFF0C8A7B),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: EdgeInsets.all(screenWidth * 0.0125),
          physics: const BouncingScrollPhysics(),
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: screenWidth * 0.08,
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[300],
                        child: userInfo?['Image'] != null
                            ? ClipOval(
                                child: Image.network(
                                  userInfo!['Image'],
                                  fit: BoxFit.cover,
                                  width: screenWidth * 0.25,
                                  height: screenWidth * 0.25,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: screenWidth * 0.125,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: screenWidth * 0.125,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                      ),
                      SizedBox(width: screenWidth * 0.0125),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome,",
                            style: TextStyle(color: textColor.withOpacity(0.6)),
                          ),
                          Text(
                            userInfo?['Full_Name'] ?? 'Unknown User',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(padding: EdgeInsets.only(bottom: screenHeight * 0.02)),
                const Image(image: AssetImage('img/home2.png')),
                Container(
                  height: screenHeight * 0.1,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.0125,
                    horizontal: screenWidth * 0.075,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Products",
                        style: GoogleFonts.lato(
                          fontSize: screenWidth * 0.055,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        child: Text(
                          "show all",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllProductsScreen(
                                productType: "All",
                                productsFuture: _apiService.fetchAllProductsFull2(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: screenHeight * 0.28375,
                  width: double.infinity,
                  child: FutureBuilder<List<Product>>(
                    future: allProducts,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        final error = snapshot.error.toString();
                        if (error.contains('Unauthorized') || error.contains('User not logged in')) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          });
                          return const Center(child: Text('Please log in again'));
                        }
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error loading recommended products: $error',
                                  style: TextStyle(color: textColor)),
                              SizedBox(height: screenHeight * 0.02),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    allProducts = _apiService.fetchAllProductsFull2();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.black,
                                ),
                                child: Text('Retry', style: TextStyle(color: textColor)),
                              ),
                            ],
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No recommended products found'));
                      }
                      final sortedProducts = snapshot.data!
                        ..sort((a, b) {
                          final aId = a.productId ?? 0;
                          final bId = b.productId ?? 0;
                          return aId.compareTo(bId);
                        });
                      final limitedProducts = sortedProducts.take(10).toList();
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        itemCount: limitedProducts.length,
                        itemBuilder: (BuildContext context, int index) {
                          final product = limitedProducts[index];
                          _favoriteControllers.putIfAbsent(
                            product.productId ?? 0,
                            () => AnimationController(
                              vsync: this,
                              duration: const Duration(milliseconds: 300),
                            ),
                          );
                          return InkWell(
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
                            child: SizedBox(
                              width: screenWidth * 0.325,
                              child: Card(
                                color: Theme.of(context).cardColor,
                                elevation: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: screenHeight * 0.15,
                                      width: screenWidth * 0.3,
                                      child: Stack(
                                        children: [
                                          product.images.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: product.images[0],
                                                  fit: BoxFit.cover,
                                                  width: screenWidth * 0.3,
                                                  height: screenHeight * 0.15,
                                                  placeholder: (context, url) => Center(
                                                    child: CircularProgressIndicator(
                                                      color: Theme.of(context).brightness == Brightness.dark
                                                          ? Colors.white70
                                                          : const Color(0xFF0C8A7B),
                                                    ),
                                                  ),
                                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                                )
                                              : const Icon(Icons.image_not_supported, size: 120),
                                          Positioned(
                                            top: screenWidth * 0.015,
                                            left: screenWidth * 0.015,
                                            child: GestureDetector(
                                              onTap: () {
                                                if (product.artisan?.ssn == null || product.artisan!.ssn.isEmpty) {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text("Error"),
                                                      content: const Text('Cannot view artisan profile: Invalid artisan data'),
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
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ArtisanProfileforClient(
                                                      artisanSSN: product.artisan!.ssn,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: CircleAvatar(
                                                radius: screenWidth * 0.035,
                                                backgroundColor: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.grey[600]
                                                    : Colors.grey[200],
                                                child: (product.artisan?.profileImage?.isNotEmpty ?? false)
                                                    ? ClipOval(
                                                        child: CachedNetworkImage(
                                                          imageUrl: product.artisan!.profileImage!,
                                                          fit: BoxFit.cover,
                                                          width: screenWidth * 0.07,
                                                          height: screenWidth * 0.07,
                                                          placeholder: (context, url) => CircularProgressIndicator(
                                                            color: Theme.of(context).brightness == Brightness.dark
                                                                ? Colors.white70
                                                                : const Color(0xFF0C8A7B),
                                                            strokeWidth: 2,
                                                          ),
                                                          errorWidget: (context, url, error) {
                                                            return Icon(
                                                              Icons.person,
                                                              size: screenWidth * 0.035,
                                                              color: Theme.of(context).brightness == Brightness.dark
                                                                  ? Colors.grey[400]
                                                                  : Colors.grey,
                                                            );
                                                          },
                                                        ),
                                                      )
                                                    : Icon(
                                                        Icons.person,
                                                        size: screenWidth * 0.035,
                                                        color: Theme.of(context).brightness == Brightness.dark
                                                            ? Colors.grey[400]
                                                            : Colors.grey,
                                                      ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: ScaleTransition(
                                              scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                                                CurvedAnimation(
                                                  parent: _favoriteControllers[product.productId ?? 0]!,
                                                  curve: Curves.easeInOut,
                                                ),
                                              ),
                                              child: IconButton(
                                                icon: Icon(
                                                  favoritesProvider.isFavorite(product.productId ?? 0)
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: const Color(0xFF0C8A7B),
                                                  size: screenWidth * 0.07,
                                                ),
                                                onPressed: () async {
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

                                                  _favoriteControllers[product.productId ?? 0]!.forward(from: 0);
                                                  try {
                                                    if (favoritesProvider.isFavorite(product.productId ?? 0)) {
                                                      await favoritesProvider.removeFavorite(product.productId ?? 0);
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: const Text("Success"),
                                                          content: const Text('Product removed from favorites!'),
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
                                                    } else {
                                                      await favoritesProvider.addFavorite(product.productId ?? 0);
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: const Text("Success"),
                                                          content: const Text('Product added to favorites!'),
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
                                                    }
                                                  } catch (e) {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text("Error"),
                                                        content: Text('Failed to update favorites: $e'),
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
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      product.name.isNotEmpty ? product.name : 'No Name',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      product.description.isNotEmpty ? product.description : 'No Description',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      "${product.price} LE",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
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
                SizedBox(height: screenHeight * 0.0125),
                const Image(image: AssetImage('img/home1.png')),
                Container(
                  height: screenHeight * 0.1,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.0125,
                    horizontal: screenWidth * 0.075,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "New Products",
                        style: GoogleFonts.lato(
                          fontSize: screenWidth * 0.055,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        child: Text(
                          "show all",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllProductsScreen(
                                productType: "New",
                                productsFuture: _apiService.fetchLatestProducts(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: screenHeight * 0.28375,
                  width: double.infinity,
                  child: FutureBuilder<List<Product>>(
                    future: newProducts,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        final error = snapshot.error.toString();
                        if (error.contains('Unauthorized') || error.contains('User not logged in')) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          });
                          return const Center(child: Text('Please log in again'));
                        }
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error loading new products: $error', style: TextStyle(color: textColor)),
                              SizedBox(height: screenHeight * 0.02),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    newProducts = _apiService.fetchLatestProducts();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.black,
                                ),
                                child: Text('Retry', style: TextStyle(color: textColor)),
                              ),
                            ],
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No new products available'));
                      }
                      final limitedNewProducts = snapshot.data!.take(10).toList();
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        itemCount: limitedNewProducts.length,
                        itemBuilder: (BuildContext context, int index) {
                          final product = limitedNewProducts[index];
                          _favoriteControllers.putIfAbsent(
                            product.productId ?? 0,
                            () => AnimationController(
                              vsync: this,
                              duration: const Duration(milliseconds: 300),
                            ),
                          );
                          return InkWell(
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
                              color: Theme.of(context).cardColor,
                              elevation: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: screenHeight * 0.15,
                                    width: screenWidth * 0.3,
                                    child: Stack(
                                      children: [
                                        product.images.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: product.images[0],
                                                fit: BoxFit.cover,
                                                width: screenWidth * 0.3,
                                                height: screenHeight * 0.15,
                                                placeholder: (context, url) => Center(
                                                  child: CircularProgressIndicator(
                                                    color: Theme.of(context).brightness == Brightness.dark
                                                        ? Colors.white70
                                                        : const Color(0xFF0C8A7B),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) => const Icon(Icons.error),
                                              )
                                            : const Icon(Icons.image_not_supported, size: 120),
                                        Positioned(
                                          top: screenWidth * 0.015,
                                          left: screenWidth * 0.015,
                                          child: GestureDetector(
                                            onTap: () {
                                              if (product.artisan?.ssn == null || product.artisan!.ssn.isEmpty) {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text("Error"),
                                                    content: const Text('Cannot view artisan profile: Invalid artisan data'),
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
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ArtisanProfileforClient(
                                                    artisanSSN: product.artisan!.ssn,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: CircleAvatar(
                                              radius: screenWidth * 0.035,
                                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.grey[600]
                                                  : Colors.grey[200],
                                              child: (product.artisan?.profileImage?.isNotEmpty ?? false)
                                                  ? ClipOval(
                                                      child: CachedNetworkImage(
                                                        imageUrl: product.artisan!.profileImage!,
                                                        fit: BoxFit.cover,
                                                        width: screenWidth * 0.07,
                                                        height: screenWidth * 0.07,
                                                        placeholder: (context, url) => CircularProgressIndicator(
                                                          color: Theme.of(context).brightness == Brightness.dark
                                                              ? Colors.white70
                                                              : const Color(0xFF0C8A7B),
                                                          strokeWidth: 2,
                                                        ),
                                                        errorWidget: (context, url, error) {
                                                          return Icon(
                                                            Icons.person,
                                                            size: screenWidth * 0.035,
                                                            color: Theme.of(context).brightness == Brightness.dark
                                                                ? Colors.grey[400]
                                                                : Colors.grey,
                                                          );
                                                        },
                                                      ),
                                                    )
                                                  : Icon(
                                                      Icons.person,
                                                      size: screenWidth * 0.035,
                                                      color: Theme.of(context).brightness == Brightness.dark
                                                          ? Colors.grey[400]
                                                          : Colors.grey,
                                                    ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: ScaleTransition(
                                            scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                                              CurvedAnimation(
                                                parent: _favoriteControllers[product.productId ?? 0]!,
                                                curve: Curves.easeInOut,
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: Icon(
                                                favoritesProvider.isFavorite(product.productId ?? 0)
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: const Color(0xFF0C8A7B),
                                                size: screenWidth * 0.07,
                                              ),
                                              onPressed: () async {
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

                                                _favoriteControllers[product.productId ?? 0]!.forward(from: 0);
                                                try {
                                                  if (favoritesProvider.isFavorite(product.productId ?? 0)) {
                                                    await favoritesProvider.removeFavorite(product.productId ?? 0);
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text("Success"),
                                                        content: const Text('Product removed from favorites!'),
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
                                                  } else {
                                                    await favoritesProvider.addFavorite(product.productId ?? 0);
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text("Success"),
                                                        content: const Text('Product added to favorites!'),
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
                                                  }
                                                } catch (e) {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text("Error"),
                                                      content: Text('Failed to update favorites: $e'),
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
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    product.name.isNotEmpty ? product.name : 'No Name',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    product.description.isNotEmpty ? product.description : 'No Description',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    "${product.price} LE",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
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
                Padding(padding: EdgeInsets.only(bottom: screenHeight * 0.0)),
              ],
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.white,
        child: ListView(
          padding: EdgeInsets.only(
            top: screenHeight * 0.075,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
          ),
          children: [
            buildMenuItem(
              icon: Icons.notifications_none_rounded,
              text: "Notification",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationSetting()),
              ),
            ),
            Padding(padding: EdgeInsets.only(top: screenHeight * 0.0375)),
            buildMenuItem(
              icon: Icons.support_agent_rounded,
              text: "Support",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Support()),
              ),
            ),
            Padding(padding: EdgeInsets.only(top: screenHeight * 0.0375)),
            buildMenuItem(
              icon: Icons.sticky_note_2_outlined,
              text: "Terms of Use",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TermsOfUse()),
              ),
            ),
            Padding(padding: EdgeInsets.only(top: screenHeight * 0.0375)),
            buildMenuItem(
              icon: Icons.privacy_tip_outlined,
              text: "Privacy Policy",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicy()),
              ),
            ),
            Padding(padding: EdgeInsets.only(top: screenHeight * 0.0375)),
            buildMenuItem(
              icon: Icons.report_gmailerrorred,
              text: "About Us",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => About_Us()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}