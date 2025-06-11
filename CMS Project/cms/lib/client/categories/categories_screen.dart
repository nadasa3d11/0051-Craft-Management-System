import 'dart:io';
import 'package:flutter/material.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'products_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  Future<List<Category>> _categoriesFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

Future<void> _loadCategories() async {
  print('Loading categories...');
  bool isConnected = await _checkInternetConnection();
  print('Internet connection: $isConnected');
  if (!isConnected) {
    print('No internet connection, setting empty categories');
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });
    setState(() {
      _categoriesFuture = Future.value([]);
      print('CategoriesFuture set to empty list');
    });
    return;
  }
  print('Fetching categories from API');
  setState(() {
    _categoriesFuture = ApiService().fetchCategories();
    print('CategoriesFuture set to API call');
  });
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
      _categoriesFuture = ApiService().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    int crossAxisCount = screenWidth < 600 ? 2 : (screenWidth < 900 ? 3 : 4);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Categories",
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
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
          child: FutureBuilder<List<Category>>(
            future: _categoriesFuture,
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
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: Colors.red,
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No categories available.',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.black54,
                    ),
                  ),
                );
              }

              final categories = snapshot.data!;

              return Padding(
                padding: EdgeInsets.all(screenWidth * 0.06),
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: screenWidth * 0.06,
                    mainAxisSpacing: screenWidth * 0.06,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductsScreen(categoryName: category.catType),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.04),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(screenWidth * 0.04),
                              child: category.firstProductImage != null
                                  ? Image.network(
                                      category.firstProductImage!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
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
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            color: Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white70
                                                : const Color(0xFF0C8A7B),
                                          ),
                                        );
                                      },
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: screenWidth * 0.13,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[400]
                                            : Colors.grey,
                                      ),
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: screenHeight * 0.08,
                                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(screenWidth * 0.04),
                                    bottomRight: Radius.circular(screenWidth * 0.04),
                                  ),
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.black.withOpacity(0.6)
                                      : Colors.black.withOpacity(0.5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      category.catType,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    Text(
                                      "${category.productCount} Products",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.035,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}