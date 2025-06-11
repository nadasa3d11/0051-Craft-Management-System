import 'dart:io';
import 'package:flutter/material.dart';
import 'package:herfa/Shared%20Files/RateApp.dart';
import 'package:herfa/artisan/editProfileData.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';
import 'package:herfa/Shared%20Files/login_screen.dart';
import 'package:herfa/Shared%20Files/privacyPolicy.dart';
import 'package:herfa/Shared%20Files/support.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? userInfo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      isLoading = true;
    });

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
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final data = await _apiService.getMyInformation();
      if (!data.containsKey('error')) {
        setState(() {
          userInfo = data;
          isLoading = false;
        });
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Error"),
            content: Text('Error: ${data["error"]}'),
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
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text('Error: $e'),
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
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('Role');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _onRefresh() async {
    await _loadUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025),
              child: Text(
                'My Profile',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: screenWidth * 0.06,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
              ),
            ),
            CircleAvatar(
              radius: screenWidth * 0.125,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[300],
              child: userInfo?['Image'] != null
                  ? ClipOval(
                      child: Image.network(
                        userInfo!['Image'],
                        fit: BoxFit.cover,
                        width: screenWidth * 0.25,
                        height: screenWidth * 0.25,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: screenWidth * 0.125,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: screenWidth * 0.125,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
            ),
            SizedBox(height: screenHeight * 0.0125),
            Text(
              userInfo?['Full_Name'] ?? 'Unknown User',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: screenWidth * 0.05,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
            ),
            SizedBox(height: screenHeight * 0.025),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView(
                  padding: EdgeInsets.only(bottom: screenHeight * 0.1),
                  children: [
                    _buildListTile(
                      context,
                      icon: Icons.person_outline,
                      title: 'Profile',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileDetailsPage(),
                          ),
                        );
                        await _loadUserInfo();
                      },
                    ),
                    _buildListTile(
                      context,
                      icon: Icons.support_agent,
                      title: 'Support',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Support(),
                          ),
                        );
                        await _loadUserInfo();
                      },
                    ),
                    _buildListTile(
                      context,
                      icon: Icons.description,
                      title: 'Privacy Policy',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrivacyPolicy(),
                          ),
                        );
                        await _loadUserInfo();
                      },
                    ),
                    _buildListTile(
                      context,
                      icon: Icons.star_border,
                      title: 'Rate this app',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RateAppPage(),
                          ),
                        );
                        await _loadUserInfo();
                      },
                    ),
                    _buildListTile(
                      context,
                      icon: Icons.logout,
                      title: 'Log Out',
                      onTap: logout,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      elevation: 5,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.white,
      child: ListTile(
        tileColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        leading: Icon(
          icon,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          size: screenWidth * 0.06,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: screenWidth * 0.04,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
        ),
        trailing: title == 'Log Out'
            ? null
            : Icon(
                Icons.arrow_forward_ios,
                size: screenWidth * 0.04,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
        onTap: onTap ??
            () {
              if (route != null) {
                Navigator.pushNamed(context, route);
              }
            },
      ),
    );
  }
}