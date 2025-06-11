import 'package:flutter/material.dart';
import 'package:herfa/Shared%20Files/aboutUs.dart';
import 'package:herfa/Shared%20Files/themeProvide.dart';
import 'package:herfa/artisan/addProduct.dart';
import 'package:herfa/artisan/home.dart';
import 'package:herfa/artisan/myProfile.dart';
import 'package:herfa/artisan/orders.dart';
import 'package:herfa/Shared%20Files/notificationSetting.dart';
import 'package:herfa/Shared%20Files/notifications.dart';
import 'package:herfa/Shared%20Files/privacyPolicy.dart';
import 'package:herfa/Shared%20Files/support.dart';
import 'package:herfa/Shared%20Files/termsOfUse.dart';
import 'package:provider/provider.dart';

class CustomNavigator extends StatefulWidget {
  @override
  _CustomNavigatorState createState() => _CustomNavigatorState();
}

class _CustomNavigatorState extends State<CustomNavigator> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    AnalyticsPage(),
    OrdersPage(),
    Add_Product(),
    NotificationsScreen(),
    MainProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required double iconSize,
    required double fontSize,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            size: iconSize,
          ),
          title: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          onTap: onTap,
        ),
        Container(
          height: 1,
          margin: EdgeInsets.symmetric(horizontal: iconSize * 0.33),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 3,
                offset: Offset(0, 5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          _pages[_selectedIndex],
          Positioned(
            top: screenHeight * 0.05,
            right: screenWidth * 0.025,
            child: GestureDetector(
              onTap: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              child: Container(
                width: screenWidth * 0.1,
                height: screenWidth * 0.1,
                decoration: BoxDecoration(
                  color: Color(0xFF0C8A7B),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      offset: Offset(4, 4),
                      blurRadius: 10,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      offset: Offset(-4, -4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: screenWidth * 0.075,
                ),
              ),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        child: ListView(
          padding: EdgeInsets.only(
            top: screenHeight * 0.075,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
          ),
          children: [
            buildMenuItem(
              icon: Icons.notifications_none_rounded,
              text: "Notification",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationSetting()),
              ),
              iconSize: screenWidth * 0.06,
              fontSize: screenWidth * 0.04,
            ),
            Padding(padding: EdgeInsets.only(top: screenHeight * 0.0375)),
            buildMenuItem(
              icon: Icons.support_agent_rounded,
              text: "Support",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Support()),
              ),
              iconSize: screenWidth * 0.06,
              fontSize: screenWidth * 0.04,
            ),
            Padding(padding: EdgeInsets.only(top: screenHeight * 0.0375)),
            buildMenuItem(
              icon: Icons.sticky_note_2_outlined,
              text: "Terms of Use",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TermsOfUse()),
              ),
              iconSize: screenWidth * 0.06,
              fontSize: screenWidth * 0.04,
            ),
            Padding(padding: EdgeInsets.only(top: screenHeight * 0.0375)),
            buildMenuItem(
              icon: Icons.privacy_tip_outlined,
              text: "Privacy Policy",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicy()),
              ),
              iconSize: screenWidth * 0.06,
              fontSize: screenWidth * 0.04,
            ),
            Padding(padding: EdgeInsets.only(top: screenHeight * 0.0375)),
            buildMenuItem(
              icon: Icons.report_gmailerrorred,
              text: "About Us",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => About_Us()),
              ),
              iconSize: screenWidth * 0.06,
              fontSize: screenWidth * 0.04,
            ),
            Padding(padding: EdgeInsets.only(top: screenHeight * 0.0375)),
            ListTile(
              leading: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                size: screenWidth * 0.06,
              ),
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
                activeColor: Colors.teal,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: screenHeight * 0.00625,
          left: screenWidth * 0.0325,
          right: screenWidth * 0.0325,
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF0C8A7B),
                borderRadius: BorderRadius.circular(screenWidth * 0.2525),
              ),
              height: screenHeight * 0.075,
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(screenWidth * 0.2525),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: Offset(10, 10),
                      blurRadius: 4,
                    ),
                    BoxShadow(
                      color: Color(0xFF0C8A7B),
                      spreadRadius: -8,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Order'),
                BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.notifications), label: 'Alerts'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}