import 'dart:io';
import 'package:flutter/material.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<List<NotificationModel>>? _notificationsFuture;
  final ApiService _apiService = ApiService();
  List<NotificationModel> _notifications = [];
  NotificationModel? _lastDeletedNotification;
  int? _lastDeletedIndex;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _fetchNotifications() async {
    print('Starting _fetchNotifications');
    bool isConnected = await _checkInternetConnection();
    print('Internet connection check: $isConnected');
    if (!isConnected) {
      if (mounted) {
        print('No internet connection, showing dialog');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Connection Error"),
            content: const Text(
                "No internet connection. Please check your network and try again."),
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
      }
      return;
    }

    try {
      print('Calling ApiService.getMyNotifications');
      setState(() {
        _notificationsFuture =
            _apiService.getMyNotifications().then((notifications) {
          print('Notifications fetched: ${notifications.length} notifications');
          setState(() {
            _notifications = notifications;
          });
          return notifications;
        }).catchError((e) {
          print('Error in getMyNotifications: $e');
          throw e;
        });
      });
    } catch (e) {
      print('Error in _fetchNotifications: $e');
      if (mounted) {
        setState(() {
          _notificationsFuture = Future.error(e);
        });
      }
    }
  }

  void _markAsReadAndNavigate(NotificationModel notification) async {
    if (!notification.isRead) {
      bool isConnected = await _checkInternetConnection();
      if (!isConnected) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Connection Error"),
            content: const Text(
                "No internet connection. Please check your network and try again."),
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

      final result =
          await _apiService.markNotificationAsRead(notification.notificationId);
      if (result.containsKey("success")) {
        setState(() {
          notification.isRead = true;
        });
      }
    }
    _navigateBasedOnType(notification);
  }

  void _navigateBasedOnType(NotificationModel notification) {
    switch (notification.notificationType) {
      case 'Payment':
        Navigator.pushNamed(context, '/orders',
            arguments: {'tab': 'processing'});
        break;
      case 'OrderShipped':
        Navigator.pushNamed(context, '/orders', arguments: {'tab': 'shipping'});
        break;
      case 'ComplaintResponse':
        Navigator.pushNamed(context, '/support');
        break;
      case 'AppRating':
        Navigator.pushNamed(context, '/app_ratings');
        break;
      case 'NewComplaint':
        Navigator.pushNamed(context, '/complaint');
        break;
      case 'NewProduct':
        Navigator.pushNamed(context, '/product', arguments: {'productId': 0});
        break;
      case 'NewOrder':
        Navigator.pushNamed(context, '/orders');
        break;
      case 'ProductRating':
        Navigator.pushNamed(context, '/product', arguments: {'productId': 0});
        break;
      case 'Rating':
        Navigator.pushNamed(context, '/artisan', arguments: {'artisanId': ''});
        break;
      default:
        break;
    }
  }

  void _deleteNotification(int notificationId, int index) async {
    setState(() {
      _lastDeletedNotification = _notifications[index];
      _lastDeletedIndex = index;
      _notifications.removeAt(index);
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notification Deleted"),
        content: const Text("The notification has been deleted."),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (_lastDeletedNotification != null &&
                    _lastDeletedIndex != null) {
                  _notifications.insert(
                      _lastDeletedIndex!, _lastDeletedNotification!);
                  _lastDeletedNotification = null;
                  _lastDeletedIndex = null;
                }
              });
              Navigator.pop(context);
            },
            child: const Text("Undo"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              bool isConnected = await _checkInternetConnection();
              if (!isConnected) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Connection Error"),
                    content: const Text(
                        "No internet connection. Please check your network and try again."),
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
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
                setState(() {
                  if (_lastDeletedIndex != null &&
                      _lastDeletedNotification != null) {
                    _notifications.insert(
                        _lastDeletedIndex!, _lastDeletedNotification!);
                  }
                });
                _lastDeletedNotification = null;
                _lastDeletedIndex = null;
                return;
              }

              final result =
                  await _apiService.deleteNotification(notificationId);
              if (!result.containsKey("success")) {
                setState(() {
                  if (_lastDeletedIndex != null &&
                      _lastDeletedNotification != null) {
                    _notifications.insert(
                        _lastDeletedIndex!, _lastDeletedNotification!);
                  }
                });
              }
              _lastDeletedNotification = null;
              _lastDeletedIndex = null;
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (_lastDeletedNotification != null &&
          _lastDeletedIndex != null &&
          mounted) {
        Navigator.pop(context, 'timeout');

        _apiService.deleteNotification(notificationId).then((result) {
          if (!result.containsKey("success")) {
            setState(() {
              if (_lastDeletedIndex != null) {
                _notifications.insert(
                    _lastDeletedIndex!, _lastDeletedNotification!);
              }
            });
          }
        });
        _lastDeletedNotification = null;
        _lastDeletedIndex = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          print('RefreshIndicator: Refreshing notifications');
          _fetchNotifications();
          await _notificationsFuture;
        },
        child: FutureBuilder<List<NotificationModel>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (_notificationsFuture == null) {
              print('FutureBuilder: _notificationsFuture is null');
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0C8A7B),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              print('FutureBuilder: ConnectionState.waiting');
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              );
            }
            if (snapshot.hasError) {
              print('FutureBuilder: Error: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.redAccent
                            : Colors.red,
                        fontSize: screenWidth * 0.04,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    ElevatedButton(
                      onPressed: () {
                        print('Retry button pressed');
                        _fetchNotifications();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.015,
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                    ),
                  ],
                ),
              );
            }
            if (_notifications.isEmpty) {
              print('FutureBuilder: No notifications found');
              return Center(
                child: Text(
                  'No notifications found',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              );
            }
            print(
                'FutureBuilder: Building ListView with ${_notifications.length} notifications');
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: screenWidth * 0.04,
                left: screenWidth * 0.04,
                right: screenWidth * 0.04,
                bottom: 0.0,
              ),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Dismissible(
                  key: Key(notification.notificationId.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: screenWidth * 0.06,
                    ),
                  ),
                  onDismissed: (direction) {
                    _deleteNotification(notification.notificationId, index);
                  },
                  child: NotificationCard(
                    notification: notification,
                    onTap: () => _markAsReadAndNavigate(notification),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: screenHeight * 0.015),
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: notification.isRead
              ? null
              : Border.all(
                  color: const Color(0xFF0C8A7B),
                  width: 2,
                ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            notification.senderName.toLowerCase() == 'system'
                ? Container(
                    width: screenWidth * 0.12,
                    height: screenWidth * 0.12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey,
                      size: screenWidth * 0.07,
                    ),
                  )
                : CircleAvatar(
                    radius: screenWidth * 0.06,
                    backgroundImage: notification.profileImage != null
                        ? NetworkImage(notification.profileImage!)
                        : null,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey.shade200,
                    child: notification.profileImage == null
                        ? Icon(
                            Icons.person,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey,
                            size: screenWidth * 0.07,
                          )
                        : null,
                  ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    _formatTimeDifference(notification.createdAt),
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.002),
                  Text(
                    notification.senderName,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeDifference(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }
}
