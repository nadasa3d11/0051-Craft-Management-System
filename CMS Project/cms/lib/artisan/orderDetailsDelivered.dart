import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/artisan/orderDetails.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';

class OrderDetailsDelivered extends StatefulWidget {
  final int orderId;

  const OrderDetailsDelivered({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailsDeliveredState createState() => _OrderDetailsDeliveredState();
}

class _OrderDetailsDeliveredState extends State<OrderDetailsDelivered> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return OrderDetailsBase(
      orderId: widget.orderId,
      orderStatus: "Shipped",
      additionalContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter the receipt confirmation code',
            style: GoogleFonts.lato(
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
                  controller: _codeController,
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
                    hintStyle: GoogleFonts.lato(
                      fontSize: screenWidth * 0.035,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey,
                    ),
                  ),
                  style: GoogleFonts.lato(
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
                  if (_codeController.text.length != 6) {
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

                  final apiService = ApiService();
                  final result = await apiService.confirmDelivery(
                    widget.orderId,
                    _codeController.text,
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
                              Navigator.pop(context, true); 
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
                    vertical: screenHeight * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  ),
                ),
                child: Text(
                  'Send',
                  style: GoogleFonts.nunitoSans(
                    fontSize: screenWidth * 0.04,
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
                    color: index < _codeController.text.length
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
  }
}