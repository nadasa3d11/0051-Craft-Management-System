import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'dart:async';
import 'package:herfa/client/home_screen/details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<String> recentSearches = ['Bags', 'Clothes', 'Decore'];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  Timer? _debounce;
  List<ProductModelInFilter> _allProducts = [];
  List<ProductModelInFilter> _filteredProducts = [];
  Future<List<ProductModelInFilter>>? _productsFuture;
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic> currentFilters = {
    'categories': <String>[],
    'minPrice': 0.0,
    'maxPrice': 5000.0,
    'minRating': null,
  };

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final products = await _apiService.fetchAllProducts2();
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });
      _performSearch();
    } catch (e) {
      String errorMessage = e.toString();
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Network')) {
        errorMessage =
            'No Internet Connection. Please check your connection and try again.';
      }
      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage;
      });
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
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  void _performSearch() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty && !recentSearches.contains(query)) {
      setState(() {
        recentSearches.add(query);
      });
    }

    String? category = currentFilters['categories'].isNotEmpty
        ? currentFilters['categories'].first
        : null;
    final minPrice = currentFilters['minPrice'] as double;
    final maxPrice = currentFilters['maxPrice'] as double;
    final minRating = currentFilters['minRating'] as double?;

    final hasFilters = category != null ||
        minPrice != 0.0 ||
        maxPrice != 5000.0 ||
        minRating != null;

    setState(() {
      if (hasFilters) {
        _productsFuture = _apiService.fetchProducts(
          query: query,
          categories: category != null ? [category] : [],
          minPrice: minPrice,
          maxPrice: maxPrice,
          minRating: minRating,
        );
        _filteredProducts = [];
      } else {
        _productsFuture = null;
        _filteredProducts = _allProducts.where((product) {
          final matchesQuery = query.isEmpty ||
              (product.name?.toLowerCase().contains(query) ?? false);
          return matchesQuery;
        }).toList();
      }
    });
  }

  void removeSearch(String item) {
    setState(() {
      recentSearches.remove(item);
    });
  }

  void clearSearches() {
    setState(() {
      recentSearches.clear();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87);
    final iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.grey;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      endDrawer: FilterDrawer(
        onFiltersChanged: (filters) {
          setState(() {
            currentFilters = filters;
          });
          _performSearch();
        },
        screenWidth: screenWidth,
        screenHeight: screenHeight,
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            (Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white),
        automaticallyImplyLeading: false,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  height: screenWidth * 0.09,
                  width: screenWidth * 0.09,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    color: Theme.of(context).cardColor.withOpacity(0.3),
                  ),
                  child: Icon(Icons.arrow_back,
                      color: iconColor, size: screenWidth * 0.06),
                ),
              ),
              SizedBox(width: screenWidth * 0.015),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search by product name",
                    hintStyle: TextStyle(
                        color: iconColor, fontSize: screenWidth * 0.04),
                    prefixIcon: Icon(Icons.search,
                        color: iconColor, size: screenWidth * 0.06),
                    filled: true,
                    fillColor: Theme.of(context).cardColor.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.06),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              SizedBox(width: screenWidth * 0.015),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_outlined,
                size: screenWidth * 0.08, color: iconColor),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchProducts();
        },
        color: const Color(0xFF0C8A7B),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.02),
            if (currentFilters['categories'].isNotEmpty ||
                currentFilters['minRating'] != null ||
                currentFilters['minPrice'] != 0 ||
                currentFilters['maxPrice'] != 5000)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Active Filters",
                        style: TextStyle(
                            color: textColor.withOpacity(0.6),
                            fontSize: screenWidth * 0.04)),
                    SizedBox(height: screenHeight * 0.02),
                    Wrap(
                      spacing: screenWidth * 0.02,
                      runSpacing: screenHeight * 0.01,
                      children: [
                        ...currentFilters['categories']
                            .map<Widget>((category) => Chip(
                                  label: Text(category,
                                      style: TextStyle(
                                          color: textColor,
                                          fontSize: screenWidth * 0.035)),
                                  deleteIcon: Icon(Icons.close,
                                      size: screenWidth * 0.04,
                                      color: textColor),
                                  onDeleted: () {
                                    setState(() {
                                      currentFilters['categories']
                                          .remove(category);
                                    });
                                    _performSearch();
                                  },
                                  backgroundColor: Colors.teal.withOpacity(0.1),
                                )),
                        if (currentFilters['minPrice'] != 0 ||
                            currentFilters['maxPrice'] != 5000)
                          Chip(
                            label: Text(
                                '${currentFilters['minPrice'].toInt()}-${currentFilters['maxPrice'].toInt()} LE',
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: screenWidth * 0.035)),
                            deleteIcon: Icon(Icons.close,
                                size: screenWidth * 0.04, color: textColor),
                            onDeleted: () {
                              setState(() {
                                currentFilters['minPrice'] = 0.0;
                                currentFilters['maxPrice'] = 5000.0;
                              });
                              _performSearch();
                            },
                            backgroundColor: Colors.teal.withOpacity(0.1),
                          ),
                        if (currentFilters['minRating'] != null)
                          Chip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${currentFilters['minRating']}+ ',
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: screenWidth * 0.035)),
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                              ],
                            ),
                            deleteIcon: Icon(Icons.close,
                                size: screenWidth * 0.04, color: textColor),
                            onDeleted: () {
                              setState(() {
                                currentFilters['minRating'] = null;
                              });
                              _performSearch();
                            },
                            backgroundColor: Colors.teal.withOpacity(0.1),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: screenWidth * 0.04),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: screenHeight * 0.025),
                                ElevatedButton(
                                  onPressed: _fetchProducts,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : (_productsFuture != null
                          ? FutureBuilder<List<ProductModelInFilter>>(
                              future: _productsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                if (snapshot.hasError) {
                                  String errorMessage =
                                      snapshot.error.toString();
                                  if (errorMessage
                                          .contains('SocketException') ||
                                      errorMessage.contains('Network')) {
                                    errorMessage =
                                        'No Internet Connection. Please check your connection and try again.';
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Error'),
                                        content: Text(errorMessage),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _performSearch();
                                            },
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (errorMessage
                                      .contains('User not logged in')) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Please log in to search for products.',
                                            style: TextStyle(
                                                color: textColor,
                                                fontSize: screenWidth * 0.04),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.025),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                  context, '/login');
                                            },
                                            child: const Text('Log In'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (errorMessage.contains(
                                      'Unauthorized: Please login again')) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Your session has expired. Please log in again.',
                                            style: TextStyle(
                                                color: textColor,
                                                fontSize: screenWidth * 0.04),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.025),
                                          ElevatedButton(
                                            onPressed: () {
                                              AuthService().clearTokens();
                                              Navigator.pushReplacementNamed(
                                                  context, '/login');
                                            },
                                            child: const Text('Log In'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  if (errorMessage.contains('Errors:')) {
                                    errorMessage = errorMessage.replaceFirst(
                                        'Exception: Failed to load products: 400, Errors: {',
                                        '');
                                    errorMessage =
                                        errorMessage.replaceFirst('}', '');
                                    errorMessage =
                                        'Invalid search parameters:\n$errorMessage';
                                  } else if (errorMessage
                                      .contains('Failed to load products')) {
                                    errorMessage =
                                        'No products match your search or filters.';
                                  }
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            errorMessage,
                                            style: TextStyle(
                                                color: textColor,
                                                fontSize: screenWidth * 0.04),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.025),
                                          ElevatedButton(
                                            onPressed: _performSearch,
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                final products = snapshot.data;
                                if (products == null || products.isEmpty) {
                                  return const Center(
                                      child: Text('No products found'));
                                }

                                return GridView.builder(
                                  padding: EdgeInsets.all(screenWidth * 0.04),
                                  gridDelegate:
                                      SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: screenWidth * 0.5,
                                    crossAxisSpacing: screenWidth * 0.025,
                                    mainAxisSpacing: screenHeight * 0.025,
                                    childAspectRatio: 0.64,
                                  ),
                                  itemCount: products.length,
                                  itemBuilder: (context, index) {
                                    final product = products[index];
                                    return ProductCard(
                                      product: product,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                    );
                                  },
                                );
                              },
                            )
                          : (_filteredProducts.isEmpty
                              ? const Center(child: Text('No products found'))
                              : GridView.builder(
                                  padding: EdgeInsets.all(screenWidth * 0.04),
                                  gridDelegate:
                                      SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: screenWidth * 0.5,
                                    crossAxisSpacing: screenWidth * 0.025,
                                    mainAxisSpacing: screenHeight * 0.025,
                                    childAspectRatio: 0.65,
                                  ),
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = _filteredProducts[index];
                                    return ProductCard(
                                      product: product,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                    );
                                  },
                                ))),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterDrawer extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersChanged;
  final double screenWidth;
  final double screenHeight;

  const FilterDrawer({
    Key? key,
    required this.onFiltersChanged,
    required this.screenWidth,
    required this.screenHeight,
  }) : super(key: key);

  @override
  _FilterDrawerState createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  double minPrice = 0;
  double maxPrice = 5000;
  int selectedRating = 0;

  List<String> categories = [
    "Bags",
    "Mobile Cover",
    "Decor",
    "Wood",
    "Flowers",
    "Accessories",
    "Pottery",
    "Textiles",
    "Blacksmith",
    "Clothes"
  ];
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87);
    final iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.grey;

    return Drawer(
      width: widget.screenWidth * 0.8,
      child: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        child: Padding(
          padding: EdgeInsets.all(widget.screenWidth * 0.04),
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Filter",
                      style: TextStyle(
                          fontSize: widget.screenWidth * 0.05,
                          fontWeight: FontWeight.w700,
                          color: textColor)),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: iconColor, size: widget.screenWidth * 0.06),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              SizedBox(height: widget.screenHeight * 0.02),
              Text("Category",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: widget.screenWidth * 0.04,
                      color: textColor)),
              Wrap(
                spacing: widget.screenWidth * 0.02,
                children: categories.map((category) {
                  bool isSelected = selectedCategory == category;
                  return ChoiceChip(
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(widget.screenWidth * 0.05)),
                    label: Text(category,
                        style: TextStyle(
                            color: textColor,
                            fontSize: widget.screenWidth * 0.035)),
                    selected: isSelected,
                    selectedColor: Colors.teal.withOpacity(0.1),
                    backgroundColor:
                        Theme.of(context).cardColor.withOpacity(0.1),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedCategory = category;
                        } else {
                          selectedCategory = null;
                        }
                      });
                      _applyFilters();
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: widget.screenHeight * 0.02),
              Text("Customer Review",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: widget.screenWidth * 0.04,
                      color: textColor)),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      Icons.star,
                      color: index < selectedRating ? Colors.amber : iconColor,
                      size: widget.screenWidth * 0.06,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedRating = index + 1;
                      });
                      _applyFilters();
                    },
                  );
                }),
              ),
              SizedBox(height: widget.screenHeight * 0.02),
              Text("Price Range",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: widget.screenWidth * 0.04,
                      color: textColor)),
              RangeSlider(
                min: 0,
                max: 5000,
                activeColor: Colors.teal,
                inactiveColor: iconColor,
                values: RangeValues(minPrice, maxPrice),
                onChanged: (RangeValues values) {
                  setState(() {
                    minPrice = values.start;
                    maxPrice = values.end;
                  });
                  _applyFilters();
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${minPrice.toInt()} LE",
                      style: TextStyle(
                          color: textColor,
                          fontSize: widget.screenWidth * 0.04)),
                  Text("${maxPrice.toInt()} LE",
                      style: TextStyle(
                          color: textColor,
                          fontSize: widget.screenWidth * 0.04)),
                ],
              ),
              SizedBox(height: widget.screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = null;
                        selectedRating = 0;
                        minPrice = 0;
                        maxPrice = 5000;
                      });
                      _applyFilters();
                    },
                    child: Text(
                      "Reset",
                      style: TextStyle(
                          color: iconColor,
                          fontSize: widget.screenWidth * 0.04),
                    ),
                  ),
                  SizedBox(width: widget.screenWidth * 0.05),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Apply",
                        style: TextStyle(fontSize: widget.screenWidth * 0.04)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyFilters() {
    final Map<String, dynamic> filters = {
      'categories': selectedCategory != null ? [selectedCategory!] : [],
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minRating': selectedRating > 0 ? selectedRating.toDouble() : null,
    };
    widget.onFiltersChanged(filters);
  }
}

class ProductCard extends StatelessWidget {
  final ProductModelInFilter product;
  final double screenWidth;
  final double screenHeight;

  const ProductCard({
    Key? key,
    required this.product,
    required this.screenWidth,
    required this.screenHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87);
    final iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.grey;

    return GestureDetector(
        onTap: () {
          if (product.productId != 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetails(
                  product: {
                    'ProductID': product.productId,
                    'ProductName': product.name,
                    'Price': product.price,
                    'Quantity': product.quantity,
                    'Category': product.category,
                    'Status': product.status,
                  },
                ),
              ),
            );
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Error'),
                content: const Text('Product ID not available'),
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
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: screenWidth * 0.0125,
                offset: Offset(0, screenWidth * 0.005),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(screenWidth * 0.03)),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: product.productImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.productImage.first,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(Icons.image_not_supported,
                                    color: iconColor, size: screenWidth * 0.1),
                              ),
                            )
                          : Container(
                              color:
                                  Theme.of(context).cardColor.withOpacity(0.3),
                              child: Center(
                                child: Icon(Icons.image_not_supported,
                                    color: iconColor, size: screenWidth * 0.1),
                              ),
                            ),
                    ),
                  ),
                  if (product.status != null &&
                      product.status!.toLowerCase() == "sale")
                    Positioned(
                      top: screenWidth * 0.02,
                      left: screenWidth * 0.02,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.02,
                            vertical: screenHeight * 0.01),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.01),
                        ),
                        child: Text(
                          "SALE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.025,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (product.quantity != null && product.quantity! <= 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(screenWidth * 0.03)),
                        ),
                        child: Center(
                          child: Text(
                            "OUT OF STOCK",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.03,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'Unknown Product',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.035,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: screenWidth * 0.005),
                        Text(
                          "${product.ratingAverage ?? 0}",
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${product.price ?? 0} LE",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.035,
                            color: textColor,
                          ),
                        ),
                        if (product.quantity != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.015,
                                vertical: screenHeight * 0.005),
                            decoration: BoxDecoration(
                              color: product.quantity! > 5
                                  ? Colors.green.withOpacity(0.1)
                                  : (product.quantity! > 0
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1)),
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.01),
                            ),
                            child: Text(
                              product.quantity! > 5
                                  ? "In Stock"
                                  : (product.quantity! > 0
                                      ? "Low Stock"
                                      : "Out of Stock"),
                              style: TextStyle(
                                fontSize: screenWidth * 0.025,
                                color: product.quantity! > 5
                                    ? Colors.green
                                    : (product.quantity! > 0
                                        ? Colors.orange
                                        : Colors.red),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
