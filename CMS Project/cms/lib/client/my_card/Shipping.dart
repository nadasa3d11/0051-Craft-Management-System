import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_item.dart';
import 'payment_screen.dart';

enum ShippingMethod {
  freeDelivery,
  standardDelivery,
  fastDelivery,
}

class CheckoutScreen extends StatefulWidget {
  final double totalPrice;
  final List<CartItem> cartItems;

  const CheckoutScreen({super.key, required this.totalPrice, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _zipcodeController = TextEditingController();
  ShippingMethod? _shippingMethod = ShippingMethod.freeDelivery;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _zipcodeController.dispose();
    super.dispose();
  }

  ({double shippingCost, String shippingMethodString}) _getShippingDetails() {
    switch (_shippingMethod) {
      case ShippingMethod.freeDelivery:
        return (shippingCost: 0.0, shippingMethodString: "Free");
      case ShippingMethod.standardDelivery:
        return (shippingCost: 50.0, shippingMethodString: "HomeDelivery");
      case ShippingMethod.fastDelivery:
        return (shippingCost: 50.0, shippingMethodString: "FastDelivery");
      default:
        return (shippingCost: 0.0, shippingMethodString: "Free");
    }
  }

  void _continueToPayment() {
    if (_formKey.currentState!.validate()) {
      final shippingDetails = _getShippingDetails();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            totalPrice: widget.totalPrice,
            shippingCost: shippingDetails.shippingCost,
            cartItems: widget.cartItems,
            fullName: _fullNameController.text,
            phone: _phoneController.text,
            address: _addressController.text,
            zipcode: _zipcodeController.text,
            shippingMethod: shippingDetails.shippingMethodString,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final shippingDetails = _getShippingDetails();
    double finalTotal = widget.totalPrice + shippingDetails.shippingCost;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      appBar: AppBar(
        title: Text(
          "Shipping Data",
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
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
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
                  "Shipping",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.0625),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: "Full name",
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: "Phone",
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: "Address",
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      controller: _zipcodeController,
                      decoration: InputDecoration(
                        labelText: "Zipcode",
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your zipcode';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      "Shipping method",
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    RadioListTile<ShippingMethod>(
                      title: Text(
                        "Free Delivery to home",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        "from 3 to 7 business days",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey,
                        ),
                      ),
                      value: ShippingMethod.freeDelivery,
                      groupValue: _shippingMethod,
                      activeColor: const Color(0xFF0C8A7B),
                      onChanged: (ShippingMethod? value) {
                        setState(() {
                          _shippingMethod = value;
                        });
                      },
                    ),
                    RadioListTile<ShippingMethod>(
                      title: Text(
                        "50.00LE Delivery to home",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        "from 1 to 3 business days",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey,
                        ),
                      ),
                      value: ShippingMethod.standardDelivery,
                      groupValue: _shippingMethod,
                      activeColor: const Color(0xFF0C8A7B),
                      onChanged: (ShippingMethod? value) {
                        setState(() {
                          _shippingMethod = value;
                        });
                      },
                    ),
                    RadioListTile<ShippingMethod>(
                      title: Text(
                        "50.00LE Fast Delivery",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        "in the same day",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey,
                        ),
                      ),
                      value: ShippingMethod.fastDelivery,
                      groupValue: _shippingMethod,
                      activeColor: const Color(0xFF0C8A7B),
                      onChanged: (ShippingMethod? value) {
                        setState(() {
                          _shippingMethod = value;
                        });
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Price:",
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
                    SizedBox(height: screenHeight * 0.02),
                    Container(
                      height: screenHeight * 0.0875,
                      child: ElevatedButton(
                        onPressed: _continueToPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C8A7B),
                          minimumSize: Size(double.infinity, screenHeight * 0.0625),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          ),
                        ),
                        child: Text(
                          "Continue to payment",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}