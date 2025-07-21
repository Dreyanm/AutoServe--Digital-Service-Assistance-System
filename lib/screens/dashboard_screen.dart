import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemChrome
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'resort_information_screen.dart';
import 'service_request_screen.dart';
import 'profile_screen.dart';
import 'facilities_screen.dart';
import 'activities_screen.dart';
import 'my_bookings_screen.dart';
import 'create_ticket_screen.dart';
import 'search_screen.dart';
import 'chat_list_screen.dart';
import 'staff_panel_screen.dart';
import 'notification_screen.dart';
import 'favorites_screen.dart';
import '../helpers/notification_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // For the bottom navigation bar
  String? userName;
  String? userEmail;
  String? userRole;
  int _unreadMessagesCount = 0;
  int _unreadNotificationsCount = 0;
  List<Map<String, dynamic>> _favoriteItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUnreadMessagesCount();
    _loadUnreadNotificationsCount();
    _checkUserRole();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString('user_favorites');
    if (favoritesJson != null) {
      final List<dynamic> favoritesList = json.decode(favoritesJson);
      setState(() {
        _favoriteItems = favoritesList.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_favorites', json.encode(_favoriteItems));
  }

  bool _isFavorite(String itemId, String itemType) {
    return _favoriteItems.any((item) => 
        item['id'] == itemId && item['type'] == itemType);
  }

  bool _isFavoriteRecommended(Map<String, dynamic> item) {
    return _favoriteItems.any((fav) => 
        fav['name'] == item['name'] && fav['type'] == item['type']);
  }

  Future<void> _toggleFavorite(Map<String, dynamic> item) async {
    final String itemId = item['id'];
    final String itemType = item['type'];
    
    setState(() {
      if (_isFavorite(itemId, itemType)) {
        _favoriteItems.removeWhere((fav) => 
            fav['id'] == itemId && fav['type'] == itemType);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['title']} removed from favorites'),
            backgroundColor: Colors.red[600],
          ),
        );
      } else {
        _favoriteItems.add({
          'id': itemId,
          'type': itemType,
          'title': item['title'],
          'location': item['location'],
          'price': item['price'],
          'rating': item['rating'],
          'imagePath': item['imagePath'],
          'dateAdded': DateTime.now().toIso8601String(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['title']} added to favorites'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    });
    await _saveFavorites();
  }

  Future<void> _toggleFavoriteRecommended(Map<String, dynamic> item) async {
    setState(() {
      if (_isFavoriteRecommended(item)) {
        _favoriteItems.removeWhere((fav) => 
            fav['name'] == item['name'] && fav['type'] == item['type']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['name']} removed from favorites'),
            backgroundColor: Colors.red[600],
          ),
        );
      } else {
        _favoriteItems.add({
          'name': item['name'],
          'image': item['image'],
          'type': item['type'],
          'location': item['location'],
          'price': item['price'],
          'rating': item['rating'],
          'dateAdded': DateTime.now().toIso8601String(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['name']} added to favorites'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    });
    await _saveFavorites();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'User';
      userEmail = prefs.getString('user_email') ?? 'user@resort.com';
      userRole = prefs.getString('user_role') ?? 'customer';
    });
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final String role = prefs.getString('user_role') ?? 'customer';
    
    // If staff or admin, show option to access staff panel
    if ((role == 'staff' || role == 'admin') && mounted) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _showRoleWelcomeDialog();
        }
      });
    }
  }

  void _showRoleWelcomeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                userRole == 'admin' ? Icons.admin_panel_settings : Icons.support_agent,
                color: userRole == 'admin' ? Colors.red[600] : Colors.blue[600],
              ),
              const SizedBox(width: 8),
              Text(
                userRole == 'admin' ? 'Admin Access' : 'Staff Access',
                style: TextStyle(
                  color: userRole == 'admin' ? Colors.red[600] : Colors.blue[600],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome ${userName}!'),
              const SizedBox(height: 8),
              Text(
                userRole == 'admin' 
                    ? 'You have administrator privileges. You can access the staff panel to manage customer conversations and resort operations.'
                    : 'You have staff privileges. You can access the staff panel to respond to customer inquiries and manage bookings.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Stay Here'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StaffPanelScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: userRole == 'admin' ? Colors.red[600] : Colors.blue[600],
              ),
              child: Text(
                'Open Staff Panel',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadUnreadMessagesCount() async {
    final prefs = await SharedPreferences.getInstance();
    int totalUnread = 0;
    
    // Count unread messages from both staff and admin conversations
    for (String recipientType in ['staff', 'admin']) {
      final String messageKey = 'chat_messages_$recipientType';
      final String? messagesJson = prefs.getString(messageKey);
      
      if (messagesJson != null) {
        final List<dynamic> messagesList = json.decode(messagesJson);
        final List<Map<String, dynamic>> messages = 
            messagesList.map((e) => Map<String, dynamic>.from(e)).toList();
        
        // Count unread messages from this recipient type
        int unreadCount = messages.where((message) => 
            message['senderType'] == recipientType && 
            message['isRead'] == false
        ).length;
        
        totalUnread += unreadCount;
      }
    }
    
    setState(() {
      _unreadMessagesCount = totalUnread;
    });
  }

  Future<void> _loadUnreadNotificationsCount() async {
    final unreadCount = await NotificationHelper.getUnreadNotificationCount();
    setState(() {
      _unreadNotificationsCount = unreadCount;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // In a real app, you would navigate to different pages here
    // For this example, we'll just update the selected index.
    switch (index) {
      case 0:
      // Home
        break;
      case 1:
      // Favorites
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FavoritesScreen(
              favoriteItems: _favoriteItems,
              onFavoriteToggle: (item) async {
                // Handle both data structures when removing from favorites
                if (item.containsKey('name')) {
                  await _toggleFavoriteRecommended(item);
                } else {
                  await _toggleFavorite(item);
                }
              },
            ),
          ),
        ).then((_) {
          // Refresh favorites when returning
          _loadFavorites();
        });
        break;
      case 2:
      // My bookings
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyBookingsScreen(),
          ),
        );
        break;
      case 3:
      // Chats
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatListScreen(),
          ),
        ).then((_) {
          // Refresh unread count when returning from chat
          _loadUnreadMessagesCount();
        });
        break;
      case 4:
      // Profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark); // For status bar icons

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            // This will navigate back to the sign-in screen if pressed.
            // In a real app, you might want to handle logout here instead.
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none, color: Colors.black),
                if (_unreadNotificationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$_unreadNotificationsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              ).then((_) {
                // Refresh notification count when returning
                _loadUnreadNotificationsCount();
              });
            },
          ),
          // Role-based menu for staff/admin panel access
          if (userRole == 'staff' || userRole == 'admin')
            PopupMenuButton<String>(
              icon: Icon(
                userRole == 'admin' ? Icons.admin_panel_settings : Icons.support_agent,
                color: userRole == 'admin' ? Colors.red : Colors.blue,
              ),
              onSelected: (String value) {
                if (value == 'staff_panel') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StaffPanelScreen(),
                    ),
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'staff_panel',
                  child: Row(
                    children: [
                      Icon(
                        userRole == 'admin' ? Icons.admin_panel_settings : Icons.support_agent,
                        color: userRole == 'admin' ? Colors.red : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(userRole == 'admin' ? 'Admin Panel' : 'Staff Panel'),
                    ],
                  ),
                ),
              ],
            ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
          const SizedBox(width: 8), // Padding for the right side
        ],
      ),
      endDrawer: _buildMenuDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header with Role Badge
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: userRole == 'admin' 
                        ? [Colors.red[50]!, Colors.red[100]!]
                        : userRole == 'staff'
                        ? [Colors.blue[50]!, Colors.blue[100]!]
                        : [Colors.green[50]!, Colors.green[100]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: userRole == 'admin' 
                        ? Colors.red[200]!
                        : userRole == 'staff'
                        ? Colors.blue[200]!
                        : Colors.green[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: userRole == 'admin' 
                            ? Colors.red[100]
                            : userRole == 'staff'
                            ? Colors.blue[100]
                            : Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        userRole == 'admin' 
                            ? Icons.admin_panel_settings
                            : userRole == 'staff'
                            ? Icons.support_agent
                            : Icons.person,
                        color: userRole == 'admin' 
                            ? Colors.red[600]
                            : userRole == 'staff'
                            ? Colors.blue[600]
                            : Colors.green[600],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userName ?? 'User',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: userRole == 'admin' 
                                  ? Colors.red[800]
                                  : userRole == 'staff'
                                  ? Colors.blue[800]
                                  : Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: userRole == 'admin' 
                                  ? Colors.red[600]
                                  : userRole == 'staff'
                                  ? Colors.blue[600]
                                  : Colors.green[600],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              userRole == 'admin' 
                                  ? 'ADMINISTRATOR'
                                  : userRole == 'staff'
                                  ? 'STAFF MEMBER'
                                  : 'GUEST',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (userRole == 'staff' || userRole == 'admin')
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StaffPanelScreen(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.dashboard,
                          color: userRole == 'admin' ? Colors.red[600] : Colors.blue[600],
                          size: 28,
                        ),
                        tooltip: 'Open Staff Panel',
                      ),
                  ],
                ),
              ),
              
              // Top buttons (moved "View Resort's Information" to menu)
              _buildDashboardButton(context, 'Request for a Service'),
              const SizedBox(height: 15),
              _buildDashboardButton(context, 'View Resort\'s Facilities'),
              const SizedBox(height: 15),
              _buildDashboardButton(context, 'View Resort\'s Activities'),
              const SizedBox(height: 15),
              _buildDashboardButton(context, 'Create a Ticket'),
              const SizedBox(height: 30),

              // Recommended for you section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommended for you',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ActivitiesScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'See All',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Recommended items list
              _buildRecommendedItem(
                context,
                'Banana Boating',
                'Batangas City',
                'P500 /day',
                4.0,
                'BananaBoat.jpg',
              ),
              const SizedBox(height: 15),
              _buildRecommendedItem(
                context,
                'Kayaking',
                'Batangas City',
                'P500 /day',
                4.8,
                'Kayaking.jpg',
              ),
              const SizedBox(height: 15),
              _buildRecommendedItem(
                context,
                'Island Hopping',
                'Batangas City',
                'P1,200 /person',
                4.0,
                'IslandHopping.jpg',
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue[600],
        unselectedItemColor: Colors.grey[500],
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed, // Ensures all labels are shown
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favorites',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.book_online_outlined),
            label: 'My bookings',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.chat_bubble_outline),
                if (_unreadMessagesCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$_unreadMessagesCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Chats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Helper widget for the large blue dashboard buttons
  Widget _buildDashboardButton(BuildContext context, String text) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (text == 'Request for a Service') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ServiceRequestScreen(),
              ),
            );
          } else if (text == 'View Resort\'s Facilities') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FacilitiesScreen(),
              ),
            );
          } else if (text == 'View Resort\'s Activities') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ActivitiesScreen(),
              ),
            );
          } else if (text == 'Create a Ticket') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateTicketScreen(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$text tapped!')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Helper widget for recommended items
  Widget _buildRecommendedItem(
      BuildContext context,
      String title,
      String location,
      String price,
      double rating,
      String imagePath,
      ) {
    final Map<String, dynamic> item = {
      'name': title,
      'image': imagePath,
      'type': 'activity',
      'location': location,
      'price': price,
      'rating': rating,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity image with heart icon
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _toggleFavoriteRecommended(item),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isFavoriteRecommended(item) 
                        ? Icons.favorite 
                        : Icons.favorite_border,
                      size: 16,
                      color: _isFavoriteRecommended(item) 
                        ? Colors.red 
                        : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber[600], size: 18),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper widget for the menu drawer
  Widget _buildMenuDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[600],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userName ?? 'Loading...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userEmail ?? 'Loading...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _buildMenuTile(
                    icon: Icons.info_outline,
                    title: 'View Resort\'s Information',
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResortInformationScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings tapped!')),
                      );
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy and Policy',
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy and Policy tapped!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for menu tiles
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.blue[600],
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    );
  }
}
