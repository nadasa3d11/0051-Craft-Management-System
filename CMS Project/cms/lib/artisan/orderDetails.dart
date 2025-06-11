import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:intl/intl.dart';

class OrderDetailsBase extends StatefulWidget {
  final int orderId;
  final String orderStatus;
  final Widget? additionalContent;
  final Widget? bottomNavigationBar;

  const OrderDetailsBase({
    Key? key,
    required this.orderId,
    required this.orderStatus,
    this.additionalContent,
    this.bottomNavigationBar,
  }) : super(key: key);

  @override
  _OrderDetailsBaseState createState() => _OrderDetailsBaseState();
}

class _OrderDetailsBaseState extends State<OrderDetailsBase> {
  Map<String, dynamic>? orderDetails;
  Map<String, dynamic>? myProductsData;
  bool _isLoading = true;
  final ApiService _apiService = ApiService();
  String? orderDate;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _fetchOrderDetails(),
      _fetchOrderDate(),
      _fetchMyProducts(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchOrderDetails() async {
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
      return;
    }

    final result = await _apiService.getOrderDetails(widget.orderId);

    setState(() {
      if (!result.containsKey("error")) {
        orderDetails = result;
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Error"),
            content: Text(result["error"]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _fetchOrderDate() async {
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
      return;
    }

    final orders = await _apiService.getOrdersByStatus(widget.orderStatus);

    if (orders.isNotEmpty) {
      final order = orders.firstWhere(
        (order) => order["Order_ID"] == widget.orderId,
        // ignore: null_check_always_fails
        orElse: () => null!,
      );

      // ignore: unnecessary_null_comparison
      if (order != null && order["Order_Date"] != null) {
        DateTime dateTime = DateTime.parse(order["Order_Date"]);
        setState(() {
          orderDate = DateFormat('dd/MM/yyyy').format(dateTime);
        });
      } else {
        setState(() {
          orderDate = "N/A";
        });
      }
    } else {
      setState(() {
        orderDate = "N/A";
      });
    }
  }

  Future<void> _fetchMyProducts() async {
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
      return;
    }

    final result = await _apiService.getProducts();

    setState(() {
      if (!result.containsKey("error")) {
        myProductsData = result;
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Error"),
            content: Text(result["error"]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _onRefresh() async {
    await _fetchData();
  }

  Widget _buildHeader() {
    String headerText;
    IconData icon;

    switch (widget.orderStatus) {
      case "Pending":
        headerText = "Details New Order";
        icon = Icons.new_releases;
        break;
      case "Processing":
        headerText = "The Order is in Progress";
        icon = Icons.hourglass_empty;
        break;
      case "Shipped":
        headerText = "The Order is Delivered";
        icon = Icons.local_shipping;
        break;
      case "Delivered":
      default:
        headerText = "This order has been received";
        icon = Icons.check;
        break;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.0375,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0C8A7B),
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: screenWidth * 0.02),
          Text(
            headerText,
            style: GoogleFonts.nunitoSans(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(width: screenWidth * 0.025),
          Icon(
            icon,
            color: Colors.white,
            size: screenWidth * 0.075,
          ),
        ],
      ),
    );
  }

  double _getProductPrice(int productId) {
    if (myProductsData == null || myProductsData!["Products"] == null) {
      return 0.0;
    }

    final products = myProductsData!["Products"] as List;
    final product = products.firstWhere(
      (prod) => prod["ProductID"] == productId,
      orElse: () => null,
    );

    return product != null ? (product["Price"] as num).toDouble() : 0.0;
  }

  double _calculateTotalProductsPrice() {
    if (orderDetails == null || orderDetails!["Products"] == null) {
      return 0.0;
    }

    double total = 0.0;
    for (var product in orderDetails!["Products"]) {
      int productId = product["Product_ID"];
      int quantity = product["Quantity"];
      double price = _getProductPrice(productId);
      total += price * quantity;
    }
    return total;
  }

  Widget _buildProductList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (orderDetails == null || orderDetails!["Products"] == null) {
      return const SizedBox.shrink();
    }

    final products = orderDetails!["Products"] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.01,
            horizontal: screenWidth * 0.035,
          ),
          child: Text(
            "Products:",
            style: GoogleFonts.lato(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),
        ...products.map((product) {
          final price = _getProductPrice(product["Product_ID"]);
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.005,
              horizontal: screenWidth * 0.035,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "x${product["Quantity"]} ${product["Product_Name"]}",
                      style: GoogleFonts.lato(
                        fontSize: screenWidth * 0.035,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    Text(
                      "${(price * product["Quantity"]).toStringAsFixed(2)}LE",
                      style: GoogleFonts.lato(
                        fontSize: screenWidth * 0.035,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.01,
        horizontal: screenWidth * 0.035,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: screenWidth * 0.035,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: screenWidth * 0.035,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
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
        centerTitle: true,
        title: Text(
          'Details Order',
          style: GoogleFonts.nunitoSans(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
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
                : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : const Color(0xFF0C8A7B),
              ),
            )
          : orderDetails == null
              ? Center(
                  child: Text(
                    'Failed to load order details.',
                    style: GoogleFonts.lato(
                      fontSize: screenWidth * 0.04,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      top: screenHeight * 0.02,
                      right: screenWidth * 0.0625,
                      left: screenWidth * 0.0625,
                      bottom: screenHeight * 0.1,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: _buildHeader()),
                        SizedBox(height: screenHeight * 0.02),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order Code #${orderDetails!["Order_ID"]}',
                              style: GoogleFonts.lato(
                                fontSize: screenWidth * 0.035,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            Text(
                              orderDate ?? "Loading...",
                              style: GoogleFonts.lato(
                                fontSize: screenWidth * 0.035,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.03125),
                        _buildDetailRow(
                          "Client Name:",
                          orderDetails!["Client"]["Full_Name"],
                        ),
                        _buildDetailRow(
                          "Client Address",
                          orderDetails!["Client"]["Address"],
                        ),
                        _buildDetailRow(
                          "Phone Number",
                          orderDetails!["Client"]["Phone_Number"],
                        ),
                        _buildDetailRow(
                          "Zip Code",
                          orderDetails!["Zip_Code"],
                        ),
                        _buildProductList(),
                        _buildDetailRow(
                          "Products price",
                          "${_calculateTotalProductsPrice().toStringAsFixed(2)}LE",
                        ),
                        _buildDetailRow(
                          "Shipping",
                          "${orderDetails!["Shipping_Cost"].toStringAsFixed(2)}LE",
                        ),
                        _buildDetailRow(
                          "TOTAL",
                          "${(_calculateTotalProductsPrice() + orderDetails!["Shipping_Cost"]).toStringAsFixed(2)}LE",
                        ),
                        if (widget.additionalContent != null) ...[
                          SizedBox(height: screenHeight * 0.02),
                          widget.additionalContent!,
                        ],
                        Container(
                          alignment: Alignment.center,
                          child: SizedBox(
                            child: widget.bottomNavigationBar,
                            width: screenWidth * 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}