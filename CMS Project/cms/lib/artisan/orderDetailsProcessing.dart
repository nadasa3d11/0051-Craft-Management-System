import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/artisan/orderDetails.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';

class OrderDetailsInProgress extends StatelessWidget {
  final int orderId;

  const OrderDetailsInProgress({Key? key, required this.orderId}) : super(key: key);

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
      orderId: orderId,
      orderStatus: "Processing",
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: ElevatedButton(
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

            final apiService = ApiService();
            final result = await apiService.shipOrder(orderId);
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
      ),
    );
  }
}