import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herfa/admin/appRatings.dart';
import 'package:herfa/admin/categoriesAdmin.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:herfa/Shared%20Files/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  String artisansCount = '0';
  String clientsCount = '0';
  String ordersCount = '0';
  String complaintsCount = '0';
  String categoriesCount = '0';
  bool _isLoading = true;
  String? _errorMessage;
  late Future<Map<String, dynamic>> _ratingsFuture;

  @override
  void initState() {
    super.initState();
    _ratingsFuture = _apiService.getAppRatings();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashboardResponse = await _apiService.getDashboardData();
      if (!dashboardResponse.containsKey('error')) {
        setState(() {
          artisansCount = dashboardResponse['Artisans']['Count'].toString();
          clientsCount = dashboardResponse['Clients']['Count'].toString();
          ordersCount = dashboardResponse['Orders']['Count'].toString();
          complaintsCount = dashboardResponse['Complaints']['Count'].toString();
          categoriesCount = dashboardResponse['Categories']['Count'].toString();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Please check your internet connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAllData() async {
    setState(() {
      _ratingsFuture = _apiService.getAppRatings();
      _fetchDashboardData();
    });
  }

  Future<void> logout() async {
    await _authService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('Role');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF0C8A7B),
          brightness: MediaQuery.of(context).platformBrightness,
        ).copyWith(
          primary: Color(0xFF0C8A7B),
          onPrimary: Colors.black,
          secondary: Colors.amber,
          surface: Colors.white,
        ),
        cardTheme: CardTheme(
          color: MediaQuery.of(context).platformBrightness == Brightness.light
              ? Colors.white
              : Color(0xFF1E2A32), 
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: Color(0xFF0C8A7B), 
              width: 3,
            ),
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.nunitoSans(
            color: MediaQuery.of(context).platformBrightness == Brightness.light
                ? Colors.black
                : Colors.white70,
          ),
          titleMedium: GoogleFonts.nunitoSans(
            color: MediaQuery.of(context).platformBrightness == Brightness.light
                ? Colors.black
                : Colors.white70,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: MediaQuery.of(context).platformBrightness ==
                  Brightness.light
              ? Colors.white
              : Theme.of(context)
                  .scaffoldBackgroundColor, 
          foregroundColor: Colors.black, 
          elevation: 0,
        ),
      ),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              centerTitle: true,
              title: Text(
                "Dashboard",
                style: GoogleFonts.nunitoSans(
                  fontWeight: FontWeight.bold,
                  textStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : Theme.of(context).cardTheme.color,
                    fontSize: screenWidth * 0.06,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.logout,
                  color: Theme.of(context).appBarTheme.foregroundColor ??
                      (MediaQuery.of(context).platformBrightness ==
                              Brightness.light
                          ? Colors.black
                          : Colors.white70),
                  size: screenWidth * 0.06,
                ),
                onPressed: logout,
              ),
            ),
            body: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.025),
                            ElevatedButton(
                              onPressed: _fetchDashboardData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0C8A7B),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(screenWidth * 0.05),
                                ),
                              ),
                              child: Text(
                                "Retry",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshAllData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            padding: EdgeInsets.only(
                              right: screenWidth * 0.0125,
                              left: screenWidth * 0.0125,
                              top: screenHeight * 0.025,
                              bottom: screenHeight * 0.03,
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => RatingsPage()),
                                    );
                                  },
                                  child: FutureBuilder<Map<String, dynamic>>(
                                    future: _ratingsFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Container(
                                          width: screenWidth * 0.9,
                                          height: screenHeight * 0.15,
                                          padding: EdgeInsets.all(
                                              screenWidth * 0.03),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF0C8A7B),
                                                Color(0xFF0C8A7B)
                                                    .withOpacity(0.7)
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                                screenWidth * 0.05),
                                          ),
                                          child: const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                        );
                                      }
                                      if (snapshot.hasError ||
                                          (snapshot.data != null &&
                                              snapshot.data!
                                                  .containsKey("error"))) {
                                        return Container(
                                          width: screenWidth * 0.9,
                                          height: screenHeight * 0.15,
                                          padding: EdgeInsets.all(
                                              screenWidth * 0.03),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF0C8A7B),
                                                Color(0xFF0C8A7B)
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                                screenWidth * 0.05),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Please check your internet connection.',
                                              style: GoogleFonts.notoSans(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        );
                                      }
                                      final data = snapshot.data!;
                                      final averageRating =
                                          data["averageRating"] as double;
                                      // ignore: unused_local_variable
                                      final totalRatings =
                                          data["totalRatings"] as int;
                                      return Container(
                                        width: screenWidth * 0.9,
                                        height: screenHeight * 0.15,
                                        padding:
                                            EdgeInsets.all(screenWidth * 0.03),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF0C8A7B),
                                              Color(0xFF0C8A7B)
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              screenWidth * 0.05),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'App Ratings',
                                              style: GoogleFonts.notoSans(
                                                fontSize: screenWidth * 0.05,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(
                                                height: screenHeight * 0.01),
                                            Text(
                                              averageRating.toStringAsFixed(1),
                                              style: GoogleFonts.notoSans(
                                                fontSize: screenWidth * 0.1,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.025),
                                Wrap(
                                  spacing: screenWidth * 0.025,
                                  runSpacing: screenHeight * 0.0125,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildDashboardCard(
                                      title: 'Artisans',
                                      count: artisansCount,
                                      imagePath: 'img/artisan.png',
                                      width: screenWidth * 0.45,
                                      height: screenHeight * 0.225,
                                    ),
                                    _buildDashboardCard(
                                      title: 'Clients',
                                      count: clientsCount,
                                      imagePath: 'img/clients.png',
                                      width: screenWidth * 0.45,
                                      height: screenHeight * 0.225,
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.025),
                                Center(
                                  child: Wrap(
                                    spacing: screenWidth * 0.025,
                                    runSpacing: screenHeight * 0.0125,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      _buildDashboardCard(
                                        title: 'Orders',
                                        count: ordersCount,
                                        imagePath: 'img/order.png',
                                        width: screenWidth * 0.45,
                                        height: screenHeight * 0.225,
                                      ),
                                      _buildDashboardCard(
                                        title: 'Complaints',
                                        count: complaintsCount,
                                        imagePath: 'img/problem.png',
                                        width: screenWidth * 0.45,
                                        height: screenHeight * 0.225,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.025),
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _buildDashboardCard(
                                      title: 'Categories',
                                      count: categoriesCount,
                                      imagePath: 'img/category.png',
                                      width: screenWidth * 0.625,
                                      height: screenHeight * 0.1875,
                                      borderRadius: screenWidth * 0.05,
                                    ),
                                    Positioned(
                                      bottom: -screenHeight * 0.025,
                                      right: -screenWidth * 0.05,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    CategoriesPage()),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF0C8A7B),
                                          shape: const CircleBorder(),
                                          padding: EdgeInsets.all(
                                              screenWidth * 0.04),
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: screenWidth * 0.06,
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
        },
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String count,
    required String imagePath,
    double? width,
    double? height,
    double borderRadius = 30,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Theme.of(context).cardTheme.color,
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunitoSans(
                      fontSize: MediaQuery.of(context).size.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.0125),
                  Text(
                    count,
                    style: TextStyle(
                      color: Color(0xFF27514C),
                      fontSize: MediaQuery.of(context).size.width * 0.07,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Image.asset(
              imagePath,
              width: MediaQuery.of(context).size.width * 0.125,
              height: MediaQuery.of(context).size.height * 0.0625,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
