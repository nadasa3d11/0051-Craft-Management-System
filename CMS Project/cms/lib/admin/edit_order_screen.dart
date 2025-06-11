import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class EditOrderScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const EditOrderScreen({required this.order});

  @override
  _EditOrderScreenState createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _orderPriceController;
  late TextEditingController _addressController;
  String? _paymentStatus;
  String? _paymentMethod;
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final String baseUrl = "https://herfa-system-handmade.runasp.net";

  @override
  void initState() {
    super.initState();
    _orderPriceController = TextEditingController(
        text: widget.order['Order_Price']?.toString() ?? '0');
    _addressController = TextEditingController(
        text: widget.order['Receive_Address']?.toString() ?? '');
    _paymentStatus = widget.order['Payment_Status']?.toString();
    _paymentMethod = widget.order['Payment_Method']?.toString();
  }

  @override
  void dispose() {
    _orderPriceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Not specified';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Not specified';
    }
  }

  String displayValue(dynamic value) {
    if (value == null || value.toString().isEmpty) return 'Not specified';
    return value.toString();
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
        await _authService.saveTokens(
            data['AccessToken'], data['RefreshToken']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String apiUrl =
        '$baseUrl/api/Admin/update-order/${widget.order['Order_ID']}';

    final requestBody = {
      "Payment_Status": _paymentStatus,
      "Order_Price": double.parse(_orderPriceController.text),
      "Payment_Method": _paymentMethod,
      "Receive_Address": _addressController.text,
    };

    try {
      String? token = await _authService.getAccessToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
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

      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Order updated successfully'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.pop(context); 
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (response.statusCode == 401) {
        bool refreshed = await refreshToken();
        if (refreshed) {
          await _updateOrder();
        } else {
          setState(() {
            _isLoading = false;
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
          _isLoading = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Update Failed'),
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
        _isLoading = false;
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
          'Edit Details',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFF0C8A7B), width: 4),
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Code',
                              style: GoogleFonts.nunitoSans(
                                fontSize: screenWidth * 0.045,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              displayValue(widget.order['Order_ID']),
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
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
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    Text(
                                      formatDate(widget.order['Order_Date']),
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                      ),
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
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    Text(
                                      widget.order['Arrived_Date'] == null ||
                                              widget.order['Arrived_Date']
                                                  .toString()
                                                  .isEmpty
                                          ? 'Not yet arrived'
                                          : formatDate(
                                              widget.order['Arrived_Date']),
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                      ),
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
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            DropdownButtonFormField<String>(
                              value: _paymentStatus,
                              items: ['Paid', 'NotPaid']
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _paymentStatus = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a payment status';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
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
                                      'Order From',
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: screenWidth * 0.045,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    Text(
                                      displayValue(widget.order['Order_From']),
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
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
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    Text(
                                      displayValue(widget.order['Order_To']),
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
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
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                hintText: 'Enter address',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an address';
                                }
                                return null;
                              },
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                            Divider(height: screenHeight * 0.03, thickness: 1),
                            Text(
                              'Order Price',
                              style: GoogleFonts.nunitoSans(
                                fontSize: screenWidth * 0.045,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            TextFormField(
                              controller: _orderPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Enter price',
                                suffixText: '\$',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a price';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                            Divider(height: screenHeight * 0.03, thickness: 1),
                            Text(
                              'Payment Method',
                              style: GoogleFonts.nunitoSans(
                                fontSize: screenWidth * 0.045,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            DropdownButtonFormField<String>(
                              value: _paymentMethod,
                              items: ['PayPal', 'Paymob', 'Cash']
                                  .map((method) => DropdownMenuItem(
                                        value: method,
                                        child: Text(
                                          method,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _paymentMethod = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a payment method';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
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
                              onPressed: _updateOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0C8A7B),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.075,
                                  vertical: screenHeight * 0.015,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(screenWidth * 0.04),
                                ),
                              ),
                              child: Text(
                                'Save',
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
