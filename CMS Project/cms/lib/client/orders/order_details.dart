import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:herfa/client/rate_product/rate_product.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

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
          'Order Details',
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
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.04,
                horizontal: screenWidth * 0.04,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0C8A7B),
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
              child: Center(
                child: Text(
                  "Your Order Is ${order.orderStatus}",
                  style: GoogleFonts.nunitoSans(
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order Code #${order.orderId}",
                  style: GoogleFonts.nunitoSans(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                Text(
                  "${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}",
                  style: GoogleFonts.nunitoSans(
                    fontSize: screenWidth * 0.04,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),
            if (order.products != null && order.products!.isNotEmpty)
              ...order.products!.map((product) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.productName,
                            style: GoogleFonts.nunitoSans(
                              fontSize: screenWidth * 0.04,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "x${product.quantity}",
                              style: GoogleFonts.nunitoSans(
                                fontSize: screenWidth * 0.04,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            if (order.orderStatus.toLowerCase() == "shipped") ...[
                              SizedBox(width: screenWidth * 0.02),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RateProductScreen(
                                        productId: product.productId,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0C8A7B),
                                  minimumSize: Size(screenWidth * 0.15, screenHeight * 0.04),
                                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                                  ),
                                ),
                                child: Text(
                                  "Rate It",
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    Divider(height: screenHeight * 0.02),
                  ],
                );
              }).toList(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Products price",
                  style: GoogleFonts.nunitoSans(
                    fontSize: screenWidth * 0.04,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                Text(
                  "${order.orderPrice?.toStringAsFixed(2)} LE",
                  style: GoogleFonts.nunitoSans(
                    fontSize: screenWidth * 0.04,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
            Divider(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Shipping",
                  style: GoogleFonts.nunitoSans(
                    fontSize: screenWidth * 0.04,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                Text(
                  "${order.shippingCost?.toStringAsFixed(2)} LE",
                  style: GoogleFonts.nunitoSans(
                    fontSize: screenWidth * 0.04,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
            Divider(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total",
                  style: GoogleFonts.nunitoSans(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                Text(
                  "${order.totalAmount?.toStringAsFixed(2)} LE",
                  style: GoogleFonts.nunitoSans(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
            if (order.conformCode != null) ...[
              SizedBox(height: screenHeight * 0.03),
              Center(
                child: Text(
                  "This Code Is Used Upon Delivery\n#${order.conformCode}",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunitoSans(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: Size(screenWidth * 0.5, screenHeight * 0.06),
                    side: const BorderSide(color: Color(0xFF0C8A7B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    ),
                  ),
                  child: Text(
                    "Return Home",
                    style: GoogleFonts.nunitoSans(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0C8A7B),
                    ),
                  ),
                ),
                if (order.orderStatus.toLowerCase() == "pending") ...[
                  SizedBox(width: screenWidth * 0.02),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await ApiService().cancelOrder(order.orderId);
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Success'),
                            content: const Text('Order canceled successfully'),
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
                      } catch (e) {
                        String errorMessage = 'Error canceling order: $e';
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
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: Size(screenWidth * 0.3, screenHeight * 0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.nunitoSans(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }
}