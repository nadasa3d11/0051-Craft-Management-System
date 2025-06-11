import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'edit_order_screen.dart';
import 'order_details_screen.dart';

class OrdersManagementScreen extends StatefulWidget {
  @override
  _OrdersManagementScreenState createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  bool isLoading = true;
  bool isAscending = true;
  final AuthService _authService = AuthService();
  final String baseUrl = "https://herfa-system-handmade.runasp.net";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchOrders();
    _searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> refreshToken() async {
    try {
      String? refreshToken = await _authService.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/Auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _authService.saveTokens(data['AccessToken'], data['RefreshToken']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchOrders() async {
    const String apiUrl = 'https://herfa-system-handmade.runasp.net/api/Admin/all-orders';

    try {
      String? token = await _authService.getAccessToken();
      if (token == null) {
        setState(() {
          isLoading = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login Required'),
            content: const Text('You need to log in first!'),
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

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          orders = data.cast<Map<String, dynamic>>();
          filteredOrders = List.from(orders);
          sortOrders();
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        bool refreshed = await refreshToken();
        if (refreshed) {
          await fetchOrders();
        } else {
          setState(() {
            isLoading = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Session Expired'),
              content: const Text('Session expired, please log in again!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          isLoading = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Fetch Failed'),
            content: const Text('Please check your internet connection.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Please check your internet connection.'),
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

  Future<void> _onRefresh() async {
    setState(() {
      isLoading = true;
    });
    await fetchOrders();
  }

  void _filterOrders() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredOrders = orders.where((order) {
        String orderId = (order['Order_ID']?.toString() ?? '').toLowerCase();
        String orderCode = (order['Order_ID']?.toString() ?? '').toLowerCase();
        String status = (order['Order_Status']?.toString() ?? '').toLowerCase();
        return orderId.contains(query) || orderCode.contains(query) || status.contains(query);
      }).toList();
      sortOrders();
    });
  }

  void sortOrders() {
    filteredOrders.sort((a, b) {
      int idA = a['Order_ID'] ?? 0;
      int idB = b['Order_ID'] ?? 0;
      return isAscending ? idA.compareTo(idB) : idB.compareTo(idB);
    });
  }

  void toggleSortOrder(String? value) {
    setState(() {
      isAscending = value == "Oldest";
      sortOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // ignore: unused_local_variable
    final screenHeight = MediaQuery.of(context).size.height;

    return Theme(
      data: Theme.of(context).copyWith(
        cardTheme: CardTheme(
          color: MediaQuery.of(context).platformBrightness == Brightness.light
              ? Colors.white
              : Color(0xFF1E2A32), 
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.05),
            side: const BorderSide(color: Colors.teal, width: 1), 
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.nunitoSans(
            color: MediaQuery.of(context).platformBrightness == Brightness.light
                ? Colors.black
                : Colors.white70, 
          ),
          bodyMedium: GoogleFonts.nunitoSans(
            color: MediaQuery.of(context).platformBrightness == Brightness.light
                ? Colors.black87
                : Colors.white70, 
          ),
          bodySmall: GoogleFonts.nunitoSans(
            color: MediaQuery.of(context).platformBrightness == Brightness.light
                ? Colors.black54
                : Colors.white60, 
          ),
        ),
        iconTheme: IconThemeData(
          color: MediaQuery.of(context).platformBrightness == Brightness.light
              ? Colors.black
              : Colors.white70, 
        ),
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Orders Management',
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.bold,
              textStyle: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: screenWidth * 0.06,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search by ID, Code, or Status",
                        hintStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.075),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      onChanged: (value) {
                        _filterOrders();
                      },
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.025),
                  DropdownButton<String>(
                    value: isAscending ? "Oldest" : "Newest",
                    items: ["Newest", "Oldest"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      toggleSortOrder(value);
                    },
                    underline: const SizedBox(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredOrders.isEmpty
                      ? Center(
                          child: Text(
                            'No orders found',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: screenWidth * 0.045,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _onRefresh,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              return OrderCard(
                                order: filteredOrders[index],
                                onEdit: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditOrderScreen(
                                        order: filteredOrders[index],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onEdit;

  const OrderCard({required this.order, required this.onEdit});

  String formatDate(String? date) {
    if (date == null) return 'Not specified';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Not specified';
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
      case 'Complete':
        return Colors.green;
      case 'Processing':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      color: Theme.of(context).brightness == Brightness.light ? Colors.white : Theme.of(context).cardTheme.color,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        side: const BorderSide(color: Colors.teal, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.025,
          vertical: screenHeight * 0.007,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${order['Order_ID'] ?? 'Not specified'}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Order Date",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        formatDate(order['Order_Date']),
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.075),
                      Text(
                        "From",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.03,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        order['ClientName'] ?? 'Not specified',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        "Arrived Date",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        formatDate(order['Arrived_Date']),
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.05),
                      Text(
                        "To",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.03,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        (order['ArtisanNames'] != null && order['ArtisanNames'].isNotEmpty)
                            ? order['ArtisanNames'][0]
                            : 'Not specified',
                        style: TextStyle(
                          fontSize: screenWidth * 0.025,
                          color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor(order['Order_Status'] ?? 'Not specified').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    child: Text(
                      order['Order_Status'] ?? 'Not specified',
                      style: TextStyle(
                        color: getStatusColor(order['Order_Status'] ?? 'Not specified'),
                        fontSize: screenWidth * 0.03,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Colors.blue,
                    size: screenWidth * 0.06,
                  ),
                  onPressed: onEdit,
                ),
                InkWell(
                  onTap: () {
                    if (order['Order_ID'] == null || order['Order_ID'] is! int) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error'),
                          content: const Text('Invalid Order ID'),
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
                        builder: (context) => OrderDetailsScreen(
                          orderId: order['Order_ID'] as int,
                          arrivedDate: order['Arrived_Date']?.toString(),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    "Details",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}