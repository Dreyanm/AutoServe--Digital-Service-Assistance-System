import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'admin_profile_screen.dart';
import 'admin_chat_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  String? adminName;
  String? adminEmail;
  String? adminRole;
  int _selectedIndex = 0;
  
  Timer? _autoRefreshTimer;
  DateTime _lastRefreshTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          _lastRefreshTime = DateTime.now();
        });
      }
    });
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      adminName = prefs.getString('user_name') ?? 'Admin';
      adminEmail = prefs.getString('user_email') ?? '';
      adminRole = prefs.getString('user_role') ?? 'admin';
    });
  }

  PreferredSizeWidget _buildTopNavigationBar() {
    return AppBar(
      backgroundColor: Colors.red[600],
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Admin Panel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            _showComingSoonDialog('Search');
          },
          icon: const Icon(Icons.search, color: Colors.white, size: 24),
          tooltip: 'Search',
        ),
        IconButton(
          onPressed: () {
            _showComingSoonDialog('Notifications');
          },
          icon: const Icon(Icons.notifications, color: Colors.white, size: 24),
          tooltip: 'Notifications',
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminProfileScreen(),
              ),
            );
          },
          icon: const Icon(Icons.account_circle, color: Colors.white, size: 24),
          tooltip: 'Profile',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'guests':
                _showComingSoonDialog('Guests Management');
                break;
              case 'staffs':
                _showComingSoonDialog('Staff Management');
                break;
              case 'activities':
                _showComingSoonDialog('Activities Management');
                break;
              case 'facilities':
                _showComingSoonDialog('Facilities Management');
                break;
              case 'service_requests':
                _showComingSoonDialog('Service Requests');
                break;
              case 'bookings':
                _showComingSoonDialog('Bookings Management');
                break;
              case 'resort_info':
                _showComingSoonDialog('Resort Information');
                break;
              case 'settings':
                setState(() => _selectedIndex = 2);
                break;
              case 'logout':
                _signOut();
                break;
              case 'help':
                _showComingSoonDialog('Help');
                break;
            }
          },
          icon: const Icon(Icons.menu, color: Colors.white, size: 24),
          tooltip: 'Menu',
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'guests',
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Guests'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'staffs',
              child: Row(
                children: [
                  Icon(Icons.badge, color: Colors.green),
                  SizedBox(width: 12),
                  Text('Staffs'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'activities',
              child: Row(
                children: [
                  Icon(Icons.local_activity, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Activities'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'facilities',
              child: Row(
                children: [
                  Icon(Icons.business, color: Colors.purple),
                  SizedBox(width: 12),
                  Text('Facilities'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'service_requests',
              child: Row(
                children: [
                  Icon(Icons.support_agent, color: Colors.teal),
                  SizedBox(width: 12),
                  Text('Service Requests'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'bookings',
              child: Row(
                children: [
                  Icon(Icons.book_online, color: Colors.indigo),
                  SizedBox(width: 12),
                  Text('Bookings'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'resort_info',
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.amber),
                  SizedBox(width: 12),
                  Text('Resort Information'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              height: 1,
              child: Divider(),
            ),
            const PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'help',
              child: Row(
                children: [
                  Icon(Icons.help, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('Help'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Sign Out', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _signOut() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/signIn',
                  (route) => false,
                );
              },
              child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildTopNavigationBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardView(),
          _buildMessagesView(),
          _buildSystemSettingsView(),
          _buildReportsView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.red[600],
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 24),
            
            // Admin Management
            _buildAdminManagement(),
            const SizedBox(height: 24),
            
            // Recent Activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red[400]!, Colors.red[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.waving_hand,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${adminName ?? 'Admin'}!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your resort system efficiently',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Last updated: ${_formatTime(_lastRefreshTime)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
          children: [
            _buildActionCard('Available Staff', Icons.badge, Colors.blue, () {
              _showComingSoonDialog('Available Staff');
            }),
            _buildActionCard('Active Guests', Icons.people, Colors.green, () {
              _showComingSoonDialog('Active Guests');
            }),
            _buildActionCard('Available Activities', Icons.local_activity, Colors.orange, () {
              _showComingSoonDialog('Available Activities');
            }),
            _buildActionCard('Available Facilities', Icons.business, Colors.purple, () {
              _showComingSoonDialog('Available Facilities');
            }),
            _buildActionCard('Pending Service Request', Icons.pending_actions, Colors.amber, () {
              _showComingSoonDialog('Pending Service Request');
            }),
            _buildActionCard('Ongoing Service Request', Icons.sync, Colors.teal, () {
              _showComingSoonDialog('Ongoing Service Request');
            }),
            _buildActionCard('Pending Activity Booking', Icons.event_busy, Colors.red, () {
              _showComingSoonDialog('Pending Activity Booking');
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, MaterialColor color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color[600], size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => Divider(color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final activities = [
                {'title': 'New staff member registered', 'time': '2 minutes ago', 'icon': Icons.person_add, 'color': Colors.green},
                {'title': 'Service ticket resolved', 'time': '15 minutes ago', 'icon': Icons.check_circle, 'color': Colors.blue},
                {'title': 'System backup completed', 'time': '1 hour ago', 'icon': Icons.backup, 'color': Colors.orange},
                {'title': 'Admin settings updated', 'time': '2 hours ago', 'icon': Icons.settings, 'color': Colors.red},
                {'title': 'Daily report generated', 'time': '3 hours ago', 'icon': Icons.assessment, 'color': Colors.purple},
              ];
              
              final activity = activities[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (activity['color'] as MaterialColor)[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    activity['icon'] as IconData,
                    color: (activity['color'] as MaterialColor)[600],
                    size: 20,
                  ),
                ),
                title: Text(
                  activity['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  activity['time'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadAdminConversations(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.message, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No Messages',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Guest messages will appear here',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final conversations = snapshot.data!;
                  return ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final lastMessage = conversation['lastMessage'];
                      final unreadCount = conversation['unreadCount'] ?? 0;
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.red[100],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.red[600],
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 12,
                                      minHeight: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            conversation['customerName'] ?? 'Guest',
                            style: TextStyle(
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            lastMessage != null 
                              ? (lastMessage['message'] ?? 'No message')
                              : 'No messages',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                              color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatMessageTime(conversation['lastActivity']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              if (unreadCount > 0)
                                Container(
                                  margin: EdgeInsets.only(top: 4),
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => _openAdminChatScreen(conversation),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSettingsView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'System Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coming Soon',
                      style: TextStyle(color: Colors.grey[500]),
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

  Widget _buildReportsView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports & Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Reports & Analytics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coming Soon',
                      style: TextStyle(color: Colors.grey[500]),
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

  Widget _buildAdminManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
          children: [
            _buildManagementCard('Add New Guest', Icons.person_add, Colors.blue, () {
              _showGuestManagementDialog();
            }),
            _buildManagementCard('Add New Staff', Icons.badge, Colors.green, () {
              _showStaffManagementDialog();
            }),
            _buildManagementCard('Add Resort Facility', Icons.business, Colors.purple, () {
              _showFacilityManagementDialog();
            }),
            _buildManagementCard('Add Resort Activity', Icons.local_activity, Colors.orange, () {
              _showActivityManagementDialog();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementCard(String title, IconData icon, MaterialColor color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color[600], size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showGuestManagementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Colors.blue),
              SizedBox(width: 8),
              Text('Add New Guest'),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select guest type:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildOptionTile('Individual Guest', Icons.person, 'Single guest reservation'),
                _buildOptionTile('Family Package', Icons.family_restroom, 'Family accommodation with special rates'),
                _buildOptionTile('Group Booking', Icons.groups, 'Multiple guests booking together'),
                _buildOptionTile('Corporate Guest', Icons.business_center, 'Business traveler with corporate rates'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showStaffManagementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.badge, color: Colors.green),
              SizedBox(width: 8),
              Text('Add New Staff'),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select staff department:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildOptionTile('Front Desk Staff', Icons.desk, 'Reception and guest services'),
                _buildOptionTile('Housekeeping', Icons.cleaning_services, 'Room maintenance and cleaning'),
                _buildOptionTile('Restaurant Staff', Icons.restaurant, 'Food and beverage service'),
                _buildOptionTile('Maintenance', Icons.build, 'Facility maintenance and repairs'),
                _buildOptionTile('Security', Icons.security, 'Resort security and safety'),
                _buildOptionTile('Management', Icons.supervisor_account, 'Department heads and supervisors'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showFacilityManagementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.business, color: Colors.purple),
              SizedBox(width: 8),
              Text('Add Resort Facility'),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select facility type:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildOptionTile('Swimming Pool', Icons.pool, 'Pool facilities and amenities'),
                _buildOptionTile('Restaurant', Icons.restaurant_menu, 'Dining establishments'),
                _buildOptionTile('Spa & Wellness', Icons.spa, 'Health and wellness facilities'),
                _buildOptionTile('Conference Room', Icons.meeting_room, 'Business and event spaces'),
                _buildOptionTile('Gym & Fitness', Icons.fitness_center, 'Exercise and fitness facilities'),
                _buildOptionTile('Beach Access', Icons.beach_access, 'Beach and water access points'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showActivityManagementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.local_activity, color: Colors.orange),
              SizedBox(width: 8),
              Text('Add Resort Activity'),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select activity type:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildOptionTile('Water Sports', Icons.surfing, 'Swimming, surfing, kayaking'),
                _buildOptionTile('Island Hopping', Icons.directions_boat, 'Boat tours and island visits'),
                _buildOptionTile('Cultural Tours', Icons.temple_buddhist, 'Local culture and heritage tours'),
                _buildOptionTile('Adventure Activities', Icons.hiking, 'Hiking, climbing, zip-lining'),
                _buildOptionTile('Wellness Programs', Icons.self_improvement, 'Yoga, meditation, spa treatments'),
                _buildOptionTile('Entertainment', Icons.music_note, 'Shows, live music, dancing'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptionTile(String title, IconData icon, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _showComingSoonDialog('$title Management');
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(feature),
          content: Text('$feature functionality is coming soon!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<List<Map<String, dynamic>>> _loadAdminConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? conversationsJson = prefs.getString('global_conversations');
      
      if (conversationsJson == null) return [];
      
      final Map<String, dynamic> allConversations = json.decode(conversationsJson);
      
      // Filter only admin conversations and sort by last activity
      List<Map<String, dynamic>> adminConversations = [];
      
      allConversations.forEach((key, value) {
        if (value is Map<String, dynamic> && value['recipientType'] == 'admin') {
          adminConversations.add(value);
        }
      });
      
      // Sort by last activity (most recent first)
      adminConversations.sort((a, b) {
        DateTime timeA = DateTime.tryParse(a['lastActivity'] ?? '') ?? DateTime(1970);
        DateTime timeB = DateTime.tryParse(b['lastActivity'] ?? '') ?? DateTime(1970);
        return timeB.compareTo(timeA);
      });
      
      return adminConversations;
    } catch (e) {
      print('Error loading admin conversations: $e');
      return [];
    }
  }

  String _formatMessageTime(String? timeString) {
    if (timeString == null) return '';
    
    try {
      final DateTime messageTime = DateTime.parse(timeString);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(messageTime);
      
      if (difference.inMinutes < 1) {
        return 'Now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
      }
    } catch (e) {
      return '';
    }
  }

  void _openAdminChatScreen(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminChatScreen(
          guestName: conversation['customerName'] ?? 'Guest',
          guestEmail: conversation['customerEmail'] ?? 'guest@resort.com',
          conversationId: conversation['conversationId'] ?? '',
        ),
      ),
    ).then((_) {
      // Refresh the conversations when returning
      setState(() {});
    });
  }
}
