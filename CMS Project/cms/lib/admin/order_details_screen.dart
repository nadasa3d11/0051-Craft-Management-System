import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'edit_order_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  final String? arrivedDate;

  const OrderDetailsScreen({required this.orderId, this.arrivedDate});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? order;
  bool isLoading = true;
  final AuthService _authService = AuthService();
  final String baseUrl = "https://herfa-system-handmade.runasp.net";

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
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

  Future<void> fetchOrderDetails() async {
    final String apiUrl = '$baseUrl/api/Order/order-details-Admin/${widget.orderId}';

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
        final data = jsonDecode(response.body);
        setState(() {
          order = data as Map<String, dynamic>;
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        bool refreshed = await refreshToken();
        if (refreshed) {
          await fetchOrderDetails();
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
            title: const Text('Load Failed'),
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
    await fetchOrderDetails();
  }

  String formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'N/A';
    }
  }

  bool isPaid() {
    return order!['Payment_Status'] == 'Paid';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Order Details',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? Center(
                  child: Text(
                    'Failed to load order details',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.05),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF0C8A7B), width: 4),
                              borderRadius: BorderRadius.circular(screenWidth * 0.12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Code',
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: screenWidth * 0.045,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  '${order!['Order_ID'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                Divider(height: screenHeight * 0.03, thickness: 1),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Order Date',
                                          style: GoogleFonts.nunitoSans(
                                            fontSize: screenWidth * 0.045,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        Row(
                                          children: [
                                            Text(
                                              formatDate(order!['Order_Date']),
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                              ),
                                            ),
                                            SizedBox(width: screenWidth * 0.01),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color: Theme.of(context).textTheme.bodyMedium?.color,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Arrived Date',
                                          style: GoogleFonts.nunitoSans(
                                            fontSize: screenWidth * 0.045,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        Row(
                                          children: [
                                            Text(
                                              formatDate(widget.arrivedDate),
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                              ),
                                            ),
                                            SizedBox(width: screenWidth * 0.01),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color: Theme.of(context).textTheme.bodyMedium?.color,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Divider(height: screenHeight * 0.03, thickness: 1),
                                Text(
                                  'Payment Status',
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: screenWidth * 0.045,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Row(
                                  children: [
                                    Radio(
                                      value: true,
                                      groupValue: isPaid(),
                                      onChanged: (value) {},
                                    ),
                                    Text(
                                      'Paid',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.05),
                                    Radio(
                                      value: false,
                                      groupValue: isPaid(),
                                      onChanged: (value) {},
                                    ),
                                    Text(
                                      'Not',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(height: screenHeight * 0.03, thickness: 1),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Order From',
                                          style: GoogleFonts.nunitoSans(
                                            fontSize: screenWidth * 0.045,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        Text(
                                          order!['Client']?['Full_Name'] ?? 'N/A',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Order To',
                                          style: GoogleFonts.nunitoSans(
                                            fontSize: screenWidth * 0.045,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        Text(
                                          (order!['Products'] != null &&
                                                  order!['Products'].isNotEmpty &&
                                                  order!['Products'][0] != null &&
                                                  order!['Products'][0]['Artisan_Name'] != null)
                                              ? order!['Products'][0]['Artisan_Name']
                                              : 'N/A',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                Text(
                                  'Address',
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: screenWidth * 0.045,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  order!['Client']?['Address'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                Divider(height: screenHeight * 0.03, thickness: 1),
                                Text(
                                  'Order Price',
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: screenWidth * 0.045,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  '${order!['Order_Price'] ?? 'N/A'}\$',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                Divider(height: screenHeight * 0.03, thickness: 1),
                                Text(
                                  'Payment method',
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: screenWidth * 0.045,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  order!['Payment_Method'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                Divider(height: screenHeight * 0.03, thickness: 1),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(screenWidth * 0.04),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (order != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditOrderScreen(
                                            order: order!,
                                          ),
                                        ),
                                      );
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Error'),
                                          content: const Text('Order data is not available'),
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.075,
                                      vertical: screenHeight * 0.015,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                    ),
                                  ),
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.05,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}