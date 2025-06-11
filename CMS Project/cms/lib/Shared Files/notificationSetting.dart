import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationSetting extends StatefulWidget {
  const NotificationSetting({super.key});

  @override
  _NotificationSettingState createState() => _NotificationSettingState();
}

class _NotificationSettingState extends State<NotificationSetting> {
  bool showNotificationSwitch = false;
  bool notificationSoundSwitch = false;
  bool lockScreenNotificationSwitch = false;
  bool _isRefreshing = false;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
    _initializeLocalNotifications();
    _loadSettings();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Connection Error"),
          content: const Text("No internet connection. Please check your network and try again."),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcmToken', fcmToken);
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (showNotificationSwitch) {
        _showLocalNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Navigator.pushNamed(context, '/notifications');
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          Navigator.pushNamed(context, '/notifications');
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: notificationSoundSwitch,
      showWhen: true,
      enableVibration: true,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? 'You have a new message',
      platformChannelSpecifics,
      payload: 'notification_payload',
    );
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isRefreshing = true;
    });
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showNotificationSwitch = prefs.getBool('showNotificationSwitch') ?? false;
      notificationSoundSwitch = prefs.getBool('notificationSoundSwitch') ?? false;
      lockScreenNotificationSwitch = prefs.getBool('lockScreenNotificationSwitch') ?? false;
      _isRefreshing = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showNotificationSwitch', showNotificationSwitch);
    await prefs.setBool('notificationSoundSwitch', notificationSoundSwitch);
    await prefs.setBool('lockScreenNotificationSwitch', lockScreenNotificationSwitch);
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "$title\n",
                  style: GoogleFonts.nunitoSans(
                    fontWeight: FontWeight.w600,
                    fontSize: MediaQuery.of(context).size.width * 0.05,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                TextSpan(
                  text: subtitle,
                  style: GoogleFonts.nunitoSans(
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF0C8A7B),
            inactiveThumbColor: Colors.white,
            activeColor: Colors.white,
            inactiveTrackColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double padding = MediaQuery.of(context).size.width * 0.08;
    final double spacing = MediaQuery.of(context).size.height * 0.04;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        title: Text(
          "Notification",
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width * 0.06,
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadSettings();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
            child: _isRefreshing
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _buildSwitchRow(
                        title: "Show notifications",
                        subtitle: "Receive push notifications for new messages",
                        value: showNotificationSwitch,
                        onChanged: (value) {
                          setState(() {
                            showNotificationSwitch = value;
                            _saveSettings();
                          });
                        },
                      ),
                      SizedBox(height: spacing),
                      _buildSwitchRow(
                        title: "Notification sounds",
                        subtitle: "Play sound for new messages",
                        value: notificationSoundSwitch,
                        onChanged: (value) {
                          setState(() {
                            notificationSoundSwitch = value;
                            _saveSettings();
                          });
                        },
                      ),
                      SizedBox(height: spacing),
                      _buildSwitchRow(
                        title: "Lock screen notifications",
                        subtitle: "Allow notifications on the lock screen",
                        value: lockScreenNotificationSwitch,
                        onChanged: (value) {
                          setState(() {
                            lockScreenNotificationSwitch = value;
                            _saveSettings();
                          });
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}