import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/artisan/orderDetails.dart';

class OrderDetailsComplete extends StatelessWidget {
  final int orderId;

  const OrderDetailsComplete({Key? key, required this.orderId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return OrderDetailsBase(
      orderId: orderId,
      orderStatus: "Delivered",
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04), 
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0C8A7B),
            padding: EdgeInsets.symmetric(
              horizontal: 0,
              vertical: screenHeight * 0.015, 
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
            ),
          ),
          child: Text(
            'Done',
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