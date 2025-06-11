import 'package:flutter/material.dart';
import 'package:herfa/admin/artisanManagement.dart';
import 'package:herfa/admin/clientManagement.dart';
import 'package:herfa/admin/complaints_screen.dart';
import 'package:herfa/admin/dashboardAdmin.dart';
import 'package:herfa/admin/ordersManagement.dart';
import 'package:herfa/Shared%20Files/notifications.dart';

class CustomNavigatorAdmin extends StatefulWidget {
  @override
  _CustomNavigatorAdminState createState() => _CustomNavigatorAdminState();
}

class _CustomNavigatorAdminState extends State<CustomNavigatorAdmin> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    DashboardPage(),
    ArtisansManagementScreen(),
    OrdersManagementScreen(),
    ClientsManagementScreen(),
    ComplaintsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget buildMenuItem(
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: Theme.of(context).iconTheme.color,
          ),
          title: Text(
            text,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.04,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          onTap: onTap,
        ),
        Container(
          height: 1,
          margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.025),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
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
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => NotificationsScreen()));
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
                  Icons.notifications_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.075,
                ),
              ),
            ),
          ),
        ],
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
              items: [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.home,
                    size: screenWidth * 0.06,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      _selectedIndex == 1 ? Colors.white : Colors.white70,
                      BlendMode.srcIn,
                    ),
                    child: Image(
                      image: AssetImage('img/potter 1.png'),
                      width: screenWidth * 0.06,
                      height: screenWidth * 0.06,
                    ),
                  ),
                  label: 'Artisan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.shopping_bag_rounded,
                    size: screenWidth * 0.06,
                  ),
                  label: 'Order',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.people_alt_outlined,
                    size: screenWidth * 0.06,
                  ),
                  label: 'Client',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.report_problem_rounded,
                    size: screenWidth * 0.06,
                  ),
                  label: 'Complaint',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}