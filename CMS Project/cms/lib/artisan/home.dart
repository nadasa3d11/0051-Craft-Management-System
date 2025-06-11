import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? productsData;
  Map<String, dynamic>? artisanRatings;
  bool isLoading = true;
  String? errorMessage;

  int availableProducts = 0;
  int unavailableProducts = 0;
  double averagePrice = 0.0;
  Map<String, int> categoryDistribution = {};
  double averageProductRating = 0.0;
  double averageArtisanRating = 0.0;

  Map<String, double> monthlyProfits = {};
  List<Map<String, dynamic>> topProducts = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> fetchData() async {
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      setState(() {
        isLoading = false;
        errorMessage = "No internet connection. Please check your network and try again.";
      });
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
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final [userInfoResponse, productsResponse] = await Future.wait([
        _apiService.getMyInformation(),
        _apiService.getProducts(),
      ]);

      if (userInfoResponse.containsKey("error")) {
        throw Exception(userInfoResponse["error"]);
      }
      final String artisanSSN = userInfoResponse["SSN"]?.toString() ?? "";

      if (productsResponse.containsKey("error")) {
        throw Exception(productsResponse["error"]);
      }

      List<dynamic> products = productsResponse["Products"] ?? [];
      setState(() {
        productsData = productsResponse;
      });

      analyzeProducts(products);

      if (artisanSSN.isNotEmpty) {
        final artisanRatingsResponse =
            await _apiService.getArtisanRatings(artisanSSN);
        if (artisanRatingsResponse.containsKey("error")) {
          throw Exception(artisanRatingsResponse["error"]);
        }

        setState(() {
          artisanRatings = artisanRatingsResponse;
          averageArtisanRating = artisanRatingsResponse["averageRating"] ?? 0.0;
        });
      }

      await fetchOrderAnalytics(products);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    await fetchData();
  }

  double _getProductPrice(int productId, List<dynamic> products) {
    final product = products.firstWhere(
      (prod) => prod["ProductID"] == productId,
      orElse: () => null,
    );
    return product != null ? (product["Price"] as num).toDouble() : 0.0;
  }

  Future<void> fetchOrderAnalytics(List<dynamic> allProducts) async {
    final deliveredOrders = await _apiService.getOrdersByStatus("Delivered");

    if (deliveredOrders.isEmpty || deliveredOrders[0].containsKey("error")) {
      setState(() {
        monthlyProfits = {};
        topProducts = [];
      });
      return;
    }

    Map<String, double> tempMonthlyProfits = {};
    Map<String, int> productSales = {};

    for (var order in deliveredOrders) {
      final orderId = order["Order_ID"];
      final orderDate = order["Order_Date"];

      final orderDetails = await _apiService.getOrderDetails(orderId);
      if (orderDetails.containsKey("error")) {
        continue;
      }

      double profit = 0.0;
      List<dynamic> products = orderDetails["Products"] ?? [];
      for (var product in products) {
        int productId = product["Product_ID"];
        int quantity = product["Quantity"]?.toInt() ?? 0;
        double price = _getProductPrice(productId, allProducts);
        profit += price * quantity;

        String productName = product["Product_Name"] ?? "Unknown";
        productSales[productName] = (productSales[productName] ?? 0) + quantity;
      }

      DateTime dateTime = DateTime.parse(orderDate);
      String monthYear = DateFormat('MMM yyyy').format(dateTime);

      tempMonthlyProfits[monthYear] =
          (tempMonthlyProfits[monthYear] ?? 0.0) + profit;
    }

    setState(() {
      monthlyProfits = tempMonthlyProfits;
    });

    List<MapEntry<String, int>> sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      topProducts = sortedProducts
          .take(5)
          .map((entry) => {
                "name": entry.key,
                "quantity": entry.value,
              })
          .toList();
    });
  }

  void analyzeProducts(List<dynamic> products) {
    availableProducts = 0;
    unavailableProducts = 0;
    double totalPrice = 0.0;
    double totalRating = 0.0;
    int ratedProducts = 0;
    categoryDistribution.clear();

    for (var product in products) {
      int quantity = product["Quantity"]?.toInt() ?? 0;
      String status = product["Status"]?.toString() ?? "Available";

      if (quantity == 0 || status == "Not Available") {
        unavailableProducts++;
      } else {
        availableProducts++;
      }

      totalPrice += (product["Price"] ?? 0.0).toDouble();

      String category = product["CategoryName"] ?? "Unknown";
      categoryDistribution[category] =
          (categoryDistribution[category] ?? 0) + 1;

      double rating = product["RatingAverage"]?.toDouble() ?? 0.0;
      if (rating > 0) {
        totalRating += rating;
        ratedProducts++;
      }
    }

    averagePrice = products.isNotEmpty ? totalPrice / products.length : 0.0;
    averageProductRating =
        ratedProducts > 0 ? totalRating / ratedProducts : 0.0;
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
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        centerTitle: true,
        title: Text(
          "Analytics & Reports",
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.bold,
            textStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: screenWidth * 0.06,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 0,
              automaticallyImplyLeading: false,
              floating: false,
              pinned: false,
            ),
          ];
        },
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF0C8A7B)))
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: screenWidth * 0.04,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        ElevatedButton(
                          onPressed: _onRefresh,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0C8A7B),
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.015),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.025),
                            ),
                          ),
                          child: Text(
                            "Retry",
                            style: GoogleFonts.nunitoSans(
                              fontSize: screenWidth * 0.04,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          screenWidth * 0.04,
                          screenWidth * 0.04,
                          screenWidth * 0.04,
                          screenHeight * 0.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatCard(
                                    "Available Products",
                                    availableProducts.toString(),
                                    Colors.green[100]!,
                                    screenWidth,
                                    screenHeight),
                                _buildStatCard(
                                    "Unavailable Products",
                                    unavailableProducts.toString(),
                                    Colors.red[100]!,
                                    screenWidth,
                                    screenHeight),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatCard(
                                    "Average Price",
                                    "${averagePrice.toStringAsFixed(2)} EGP",
                                    Colors.blue[100]!,
                                    screenWidth,
                                    screenHeight),
                                _buildStatCard(
                                    "Avg Product Rating",
                                    averageProductRating.toStringAsFixed(1),
                                    Colors.yellow[100]!,
                                    screenWidth,
                                    screenHeight),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            _buildStatCard(
                                "Artisan Rating",
                                averageArtisanRating.toStringAsFixed(1),
                                Colors.purple[100]!,
                                screenWidth,
                                screenHeight,
                                fullWidth: true),
                            SizedBox(height: screenHeight * 0.03),
                            Text(
                              "Category Distribution",
                              style: GoogleFonts.nunitoSans(
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.045,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            categoryDistribution.entries
                                    .where((entry) => entry.key != "Unknown")
                                    .isEmpty
                                ? Text(
                                    "No categories available",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      color: Colors.grey,
                                    ),
                                  )
                                : Column(
                                    children: categoryDistribution.entries
                                        .where((entry) => entry.key != "Unknown")
                                        .map((entry) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: screenHeight * 0.005),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              entry.key,
                                              style: TextStyle(
                                                  fontSize: screenWidth * 0.04),
                                            ),
                                            Text(
                                              "${entry.value} products",
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.04,
                                                color: Color(0xFF0C8A7B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                            SizedBox(height: screenHeight * 0.03),
                            Text(
                              "Monthly Profits",
                              style: GoogleFonts.nunitoSans(
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.045,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            monthlyProfits.isEmpty
                                ? Text(
                                    "No profits available",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      color: Colors.grey,
                                    ),
                                  )
                                : Column(
                                    children: monthlyProfits.entries.map((entry) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: screenHeight * 0.005),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              entry.key,
                                              style: TextStyle(
                                                  fontSize: screenWidth * 0.04),
                                            ),
                                            Text(
                                              "${entry.value.toStringAsFixed(2)} EGP",
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.04,
                                                color: Color(0xFF0C8A7B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                            SizedBox(height: screenHeight * 0.03),
                            Text(
                              "Top Demanded Products",
                              style: GoogleFonts.nunitoSans(
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.045,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            topProducts.isEmpty
                                ? Text(
                                    "No sales yet",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      color: Colors.grey,
                                    ),
                                  )
                                : Column(
                                    children: topProducts.map((product) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: screenHeight * 0.005),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              product["name"],
                                              style: TextStyle(
                                                  fontSize: screenWidth * 0.04),
                                            ),
                                            Text(
                                              "${product["quantity"]} sold",
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.04,
                                                color: Color(0xFF0C8A7B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                            SizedBox(height: screenHeight * 0.03),
                            Text(
                              "Products Overview",
                              style: GoogleFonts.nunitoSans(
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.045,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: [
                                  DataColumn(
                                      label: Text("Name",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color))),
                                  DataColumn(
                                      label: Text("Price (EGP)",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color))),
                                  DataColumn(
                                      label: Text("Quantity",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color))),
                                  DataColumn(
                                      label: Text("Status",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color))),
                                  DataColumn(
                                      label: Text("Rating",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color))),
                                ],
                                rows: (productsData?["Products"] as List<dynamic>?)
                                        ?.map((product) {
                                      return DataRow(cells: [
                                        DataCell(Text(
                                            product["ProductName"]?.toString() ??
                                                "N/A",
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color))),
                                        DataCell(Text(
                                            product["Price"]?.toString() ?? "0.0",
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color))),
                                        DataCell(Text(
                                            product["Quantity"]?.toString() ?? "0",
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color))),
                                        DataCell(Text(
                                            product["Status"]?.toString() ?? "N/A",
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color))),
                                        DataCell(Text(
                                            product["RatingAverage"]
                                                    ?.toStringAsFixed(1) ??
                                                "0.0",
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color))),
                                      ]);
                                    }).toList() ??
                                    []),
                              ),
                            ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color,
      double screenWidth, double screenHeight,
      {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : screenWidth * 0.4,
      height: fullWidth ? null : screenHeight * 0.15,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.04,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: fullWidth ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C8A7B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}