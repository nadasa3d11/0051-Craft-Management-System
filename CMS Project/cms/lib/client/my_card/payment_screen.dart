import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/client/my_card/order_completed_screen.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'cart_item.dart';

class PaymentScreen extends StatefulWidget {
  final double totalPrice;
  final double shippingCost;
  final List<CartItem> cartItems;
  final String fullName;
  final String phone;
  final String address;
  final String zipcode;
  final String shippingMethod;

  const PaymentScreen({
    super.key,
    required this.totalPrice,
    required this.shippingCost,
    required this.cartItems,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.zipcode,
    required this.shippingMethod,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ApiService _apiService = ApiService();
  bool isPlacingOrder = false;

  Future<void> _placeOrder() async {
    setState(() {
      isPlacingOrder = true;
    });

    try {
      await _apiService.checkout(
        cartItems: widget.cartItems,
        paymentMethod: "Cash",
        shippingMethod: widget.shippingMethod,
        shippingCost: widget.shippingCost,
        address: widget.address,
        zipCode: widget.zipcode,
        fullName: widget.fullName,
        phoneNumber: widget.phone,
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Order placed successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  widget.cartItems.clear();
                });
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderCompletedScreen()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      String errorMessage = 'Failed to place order: $e';
      if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
        errorMessage = 'No Internet Connection. Please check your connection and try again.';
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        isPlacingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double finalTotal = widget.totalPrice + widget.shippingCost;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      appBar: AppBar(
        title: Text(
          "Payment",
          style: GoogleFonts.nunitoSans(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.01875),
              Container(
                height: screenHeight * 0.0625,
                width: screenWidth * 0.375,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C8A7B),
                  borderRadius: BorderRadius.circular(screenWidth * 0.0175),
                ),
                child: const Text(
                  "Payment",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.075),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.02),
                    Container(
                      height: screenHeight * 0.125,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C8A7B),
                        borderRadius: BorderRadius.circular(screenWidth * 0.0375),
                      ),
                      child: const Text(
                        "Payment Upon Receipt",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    Text(
                      "Order Summary",
                      style: TextStyle(
                        fontSize: screenWidth * 0.0625,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Products price",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        Text(
                          "${widget.totalPrice.toStringAsFixed(2)} LE",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Shipping",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        Text(
                          "${widget.shippingCost.toStringAsFixed(2)} LE",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        Text(
                          "${finalTotal.toStringAsFixed(2)} LE",
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                height: screenHeight * 0.1375,
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: ElevatedButton(
                  onPressed: isPlacingOrder ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C8A7B),
                    minimumSize: Size(double.infinity, screenHeight * 0.0625),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                  ),
                  child: isPlacingOrder
                      ? CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: screenWidth * 0.01,
                        )
                      : Text(
                          "Place My Order",
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (isPlacingOrder)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}