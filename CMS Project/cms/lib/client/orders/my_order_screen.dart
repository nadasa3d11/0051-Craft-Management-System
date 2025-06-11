import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'order_details.dart';

class MyOrderScreen extends StatefulWidget {
  const MyOrderScreen({super.key});

  @override
  State<MyOrderScreen> createState() => _MyOrderScreenState();
}

class _MyOrderScreenState extends State<MyOrderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  final ApiService apiService = ApiService();
  bool _isLoading = true;

  List<Order> pendingOrders = [];
  List<Order> processingOrders = [];
  List<Order> shippedOrders = [];
  List<Order> canceledOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pageController = PageController(initialPage: 0);
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
        pendingOrders = [];
        processingOrders = [];
        shippedOrders = [];
        canceledOrders = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final pendingResult = await apiService.fetchOrders("Pending");
      final processingResult = await apiService.fetchOrders("Processing");
      final shippedResult = await apiService.fetchOrders("Shipped");
      final canceledResult = await apiService.fetchOrders("Cancelled");

      setState(() {
        pendingOrders = pendingResult;
        processingOrders = processingResult;
        shippedOrders = shippedResult;
        canceledOrders = canceledResult;
        _isLoading = false;
      });
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text('Error fetching orders: $e'),
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
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
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
          'My Orders',
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
                  _buildTabButton('Pending', 0),
                  SizedBox(width: screenWidth * 0.02),
                  _buildTabButton('Processing', 1),
                  SizedBox(width: screenWidth * 0.02),
                  _buildTabButton('Shipped', 2),
                  SizedBox(width: screenWidth * 0.02),
                  _buildTabButton('Cancelled', 3),
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
                  _buildOrderList('Pending', pendingOrders),
                  _buildOrderList('Processing', processingOrders),
                  _buildOrderList('Shipped', shippedOrders),
                  _buildOrderList('Cancelled', canceledOrders),
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
          color: isSelected ? Colors.white : const Color(0xFF0C8A7B),
        ),
      ),
    );
  }

  Widget _buildOrderList(String tabName, List<Order> filteredOrders) {
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
      padding: EdgeInsets.all(screenWidth * 0.04),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return Padding(
          padding: EdgeInsets.only(bottom: screenHeight * 0.02),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ID ${order.orderId}',
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

                      try {
                        final detailedOrder = await apiService.fetchOrderDetails(order.orderId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(order: detailedOrder),
                          ),
                        );
                      } catch (e) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Error"),
                            content: Text('Error fetching order details: $e'),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
                    style: GoogleFonts.nunitoSans(
                      fontSize: screenWidth * 0.035,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  if (tabName == 'Pending')
                    ElevatedButton(
                      onPressed: () async {
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

                        try {
                          await apiService.cancelOrder(order.orderId);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Success"),
                              content: const Text('Order canceled successfully'),
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
                          await _fetchOrders();
                        } catch (e) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Error"),
                              content: Text('Error canceling order: $e'),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.01,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.nunitoSans(
                          fontSize: screenWidth * 0.035,
                          color: Colors.white,
                        ),
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
}