import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/artisan/orderDetailsComplete.dart';
import 'package:herfa/artisan/orderDetailsDelivered.dart';
import 'package:herfa/artisan/orderDetailsNew.dart';
import 'package:herfa/artisan/orderDetailsProcessing.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PageController _pageController = PageController(initialPage: 0);

  List<Map<String, dynamic>> pendingOrders = [];
  List<Map<String, dynamic>> processingOrders = [];
  List<Map<String, dynamic>> shippedOrders = [];
  List<Map<String, dynamic>> deliveredOrders = [];

  final Map<int, TextEditingController> _codeControllers = {};

  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchOrders();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _pageController.jumpToPage(_tabController.index);
        setState(() {});
      }
    });

    _pageController.addListener(() {
      int currentPage = _pageController.page?.round() ?? 0;
      if (_tabController.index != currentPage) {
        _tabController.animateTo(currentPage);
      }
    });
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });

    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Connection Error"),
          content: Text("No internet connection. Please check your network and try again."),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final pendingResult = await _apiService.getOrdersByStatus("Pending");
    final processingResult = await _apiService.getOrdersByStatus("Processing");
    final shippedResult = await _apiService.getOrdersByStatus("Shipped");
    final deliveredResult = await _apiService.getOrdersByStatus("Delivered");

    setState(() {
      pendingOrders =
          pendingResult.where((order) => !order.containsKey("error")).toList();
      processingOrders = processingResult
          .where((order) => !order.containsKey("error"))
          .toList();
      shippedOrders =
          shippedResult.where((order) => !order.containsKey("error")).toList();
      deliveredOrders = deliveredResult
          .where((order) => !order.containsKey("error"))
          .toList();

      for (var order in shippedOrders) {
        if (!_codeControllers.containsKey(order["Order_ID"])) {
          _codeControllers[order["Order_ID"]] = TextEditingController();
        }
      }

      _isLoading = false;
    });
  }

  Future<void> _onRefresh() async {
    await _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _codeControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
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
          'Orders',
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(screenHeight * 0.05),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.00375,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildTabButton('New', 0),
                  SizedBox(width: screenWidth * 0.02),
                  _buildTabButton('In progress', 1),
                  SizedBox(width: screenWidth * 0.02),
                  _buildTabButton('Delivered', 2),
                  SizedBox(width: screenWidth * 0.02),
                  _buildTabButton('Complete', 3),
                ],
              ),
            ),
          ),
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
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: PageView(
                controller: _pageController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildOrderList('New', pendingOrders),
                  _buildOrderList('In Progress', processingOrders),
                  _buildDeliveredList(),
                  _buildOrderList('Complete', deliveredOrders),
                ],
              ),
            ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    bool isSelected = _tabController.index == index;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xFF0C8A7B)
            : Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenHeight * 0.0075,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
          side: const BorderSide(color: Color(0xFF0C8A7B)),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: GoogleFonts.nunitoSans(
          fontSize: screenWidth * 0.035,
          fontWeight: FontWeight.bold,
          color: isSelected
              ? Colors.white
              : const Color(0xFF0C8A7B),
        ),
      ),
    );
  }

  Widget _buildOrderList(
      String tabName, List<Map<String, dynamic>> filteredOrders) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (filteredOrders.isEmpty) {
      return Center(
        child: Text(
          'No orders available in this category.',
          style: GoogleFonts.nunitoSans(
            fontSize: screenWidth * 0.04,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.04,
        screenWidth * 0.04,
        screenWidth * 0.04,
        screenHeight * 0.0,
      ),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return Padding(
          padding: EdgeInsets.only(bottom: screenHeight * 0.02),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ID ${order["Order_ID"]}',
                        style: GoogleFonts.nunitoSans(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      ElevatedButton(
                        onPressed: () async {
                          Widget detailsPage;
                          switch (tabName) {
                            case 'New':
                              detailsPage =
                                  OrderDetailsNew(orderId: order["Order_ID"]);
                              break;
                            case 'In Progress':
                              detailsPage = OrderDetailsInProgress(
                                  orderId: order["Order_ID"]);
                              break;
                            case 'Complete':
                              detailsPage = OrderDetailsComplete(
                                  orderId: order["Order_ID"]);
                              break;
                            default:
                              return;
                          }
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => detailsPage),
                          );
                          if (result == true) {
                            _fetchOrders();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : const Color(0xFFF1F1F1),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.01,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.05),
                          ),
                        ),
                        child: Text(
                          'Details',
                          style: GoogleFonts.nunitoSans(
                            fontSize: screenWidth * 0.035,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    order['Order_Date'].toString().substring(0, 10),
                    style: GoogleFonts.nunitoSans(
                      fontSize: screenWidth * 0.035,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  if (tabName == 'New')
                    ElevatedButton(
                      onPressed: () async {
                        bool isConnected = await _checkInternetConnection();
                        if (!isConnected) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Connection Error"),
                              content: Text("No internet connection. Please check your network and try again."),
                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[900]
                                  : Colors.white,
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

                        final result =
                            await _apiService.acceptOrder(order["Order_ID"]);
                        if (result.containsKey("error")) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Error"),
                              content: Text(result["error"]),
                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[900]
                                  : Colors.white,
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("OK"),
                                ),
                              ],
                            ),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Success"),
                              content: Text("Order accepted successfully!"),
                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[900]
                                  : Colors.white,
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _fetchOrders();
                                  },
                                  child: Text("OK"),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C8A7B),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.01,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        ),
                      ),
                      child: Text(
                        'Accept',
                        style: GoogleFonts.nunitoSans(
                          fontSize: screenWidth * 0.035,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (tabName == 'In Progress')
                    ElevatedButton(
                      onPressed: () async {
                        bool isConnected = await _checkInternetConnection();
                        if (!isConnected) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Connection Error"),
                              content: Text("No internet connection. Please check your network and try again."),
                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[900]
                                  : Colors.white,
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

                        final result =
                            await _apiService.shipOrder(order["Order_ID"]);
                        if (result.containsKey("error")) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Error"),
                              content: Text(result["error"]),
                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[900]
                                  : Colors.white,
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("OK"),
                                ),
                              ],
                            ),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Success"),
                              content: Text("Order shipped successfully!"),
                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[900]
                                  : Colors.white,
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _fetchOrders();
                                  },
                                  child: Text("OK"),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C8A7B),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.01,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        ),
                      ),
                      child: Text(
                        'Send',
                        style: GoogleFonts.nunitoSans(
                          fontSize: screenWidth * 0.035,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (tabName == 'Complete')
                    Text(
                      'Done',
                      style: GoogleFonts.nunitoSans(
                        fontSize: screenWidth * 0.035,
                        color: const Color(0xFF0C8A7B),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveredList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (shippedOrders.isEmpty) {
      return Center(
        child: Text(
          'No orders available in this category.',
          style: GoogleFonts.nunitoSans(
            fontSize: screenWidth * 0.04,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.04,
        screenWidth * 0.04,
        screenWidth * 0.04,
        60,
      ),
      itemCount: shippedOrders.length,
      itemBuilder: (context, index) {
        final order = shippedOrders[index];
        final controller = _codeControllers[order["Order_ID"]]!;
        return Padding(
          padding: EdgeInsets.only(bottom: screenHeight * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ID ${order["Order_ID"]}',
                        style: GoogleFonts.nunitoSans(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsDelivered(
                                  orderId: order["Order_ID"]),
                            ),
                          );
                          if (result == true) {
                            _fetchOrders();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : const Color(0xFFF1F1F1),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.01,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.05),
                          ),
                        ),
                        child: Text(
                          'Details',
                          style: GoogleFonts.nunitoSans(
                            fontSize: screenWidth * 0.035,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    order['Order_Date'].toString().substring(0, 10),
                    style: GoogleFonts.nunitoSans(
                      fontSize: screenWidth * 0.035,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Enter the receipt confirmation code',
                style: GoogleFonts.nunitoSans(
                  fontSize: screenWidth * 0.035,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: screenWidth * 0.5,
                    child: TextField(
                      controller: controller,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]!
                                : Colors.grey,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]!
                                : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFF0C8A7B),
                          ),
                        ),
                        hintText: 'Enter 6-digit code',
                        hintStyle: GoogleFonts.nunitoSans(
                          fontSize: screenWidth * 0.035,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey,
                        ),
                      ),
                      style: GoogleFonts.nunitoSans(
                        fontSize: screenWidth * 0.035,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (controller.text.length != 6) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Invalid Code"),
                            content: Text("Please enter a valid 6-digit code"),
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[900]
                                : Colors.white,
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

                      bool isConnected = await _checkInternetConnection();
                      if (!isConnected) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Connection Error"),
                            content: Text("No internet connection. Please check your network and try again."),
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[900]
                                : Colors.white,
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

                      final result = await _apiService.confirmDelivery(
                        order["Order_ID"],
                        controller.text,
                      );
                      if (result.containsKey("error")) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Error"),
                            content: Text(result["error"]),
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[900]
                                : Colors.white,
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("OK"),
                              ),
                            ],
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Success"),
                            content: Text("Code verified successfully! Order marked as Delivered."),
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[900]
                                : Colors.white,
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  controller.clear();
                                  _fetchOrders();
                                },
                                child: Text("OK"),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C8A7B),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.01,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      ),
                    ),
                    child: Text(
                      'Send',
                      style: GoogleFonts.nunitoSans(
                        fontSize: screenWidth * 0.035,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                children: List.generate(6, (index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                    child: Container(
                      width: screenWidth * 0.05,
                      height: screenWidth * 0.05,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]!
                              : Colors.grey,
                        ),
                        color: index < controller.text.length
                            ? const Color(0xFF0C8A7B)
                            : Colors.transparent,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}