import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'admin_profile_screen.dart';
import 'admin_chat_screen.dart';
import 'admin_staff_chat_screen.dart';
import 'available_staff_screen.dart';
import 'active_guests_screen.dart';
import 'available_activities_screen.dart';
import 'available_facilities_screen.dart';
import 'tickets_management_screen.dart';

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
        Builder(
          builder: (context) => IconButton(
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
            tooltip: 'Menu',
          ),
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
                // Only clear current session data, preserve registered users and app data
                await prefs.remove('user_name');
                await prefs.remove('user_email');
                await prefs.remove('user_role');
                // Don't clear 'registered_users', 'global_conversations', or other app data
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
      endDrawer: _buildAdminDrawer(),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AvailableStaffScreen(),
                ),
              );
            }),
            _buildActionCard('Active Guests', Icons.people, Colors.green, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActiveGuestsScreen(),
                ),
              );
            }),
            _buildActionCard('Available Activities', Icons.local_activity, Colors.orange, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AvailableActivitiesScreen(),
                ),
              );
            }),
            _buildActionCard('Available Facilities', Icons.business, Colors.purple, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AvailableFacilitiesScreen(),
                ),
              );
            }),
            _buildActionCard('Tickets', Icons.confirmation_number, Colors.indigo, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TicketsManagementScreen(),
                ),
              );
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
                      final isStaffConversation = conversation['isStaffConversation'] == true;
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: isStaffConversation ? Colors.blue[100] : Colors.red[100],
                                child: Icon(
                                  isStaffConversation ? Icons.support_agent : Icons.person,
                                  color: isStaffConversation ? Colors.blue[600] : Colors.red[600],
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
                            isStaffConversation 
                              ? (conversation['staffName'] ?? 'Staff') 
                              : (conversation['customerName'] ?? 'Guest'),
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
      child: SingleChildScrollView(
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
            
            // Key Metrics Cards
            _buildMetricsSection(),
            const SizedBox(height: 24),
            
            // Charts Section
            _buildChartsSection(),
            const SizedBox(height: 24),
            
            // Detailed Reports
            _buildDetailedReports(),
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
      List<Map<String, dynamic>> adminConversations = [];
      
      // Load guest conversations
      final String? conversationsJson = prefs.getString('global_conversations');
      if (conversationsJson != null) {
        final Map<String, dynamic> allConversations = json.decode(conversationsJson);
        
        allConversations.forEach((key, value) {
          if (value is Map<String, dynamic> && value['recipientType'] == 'admin') {
            adminConversations.add(value);
          }
        });
      }
      
      // Load staff-admin conversations
      final String? staffConversationsJson = prefs.getString('admin_staff_conversations');
      if (staffConversationsJson != null) {
        final Map<String, dynamic> staffConversations = json.decode(staffConversationsJson);
        
        staffConversations.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            // Mark as staff conversation for UI differentiation
            value['isStaffConversation'] = true;
            adminConversations.add(value);
          }
        });
      }
      
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
    final isStaffConversation = conversation['isStaffConversation'] == true;
    
    if (isStaffConversation) {
      // Navigate to staff-admin chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminStaffChatScreen(
            staffId: conversation['staffId'] ?? '',
            staffName: conversation['staffName'] ?? 'Staff',
            conversationId: conversation['conversationId'] ?? '',
          ),
        ),
      ).then((_) {
        // Refresh the conversations when returning
        setState(() {});
      });
    } else {
      // Navigate to guest-admin chat
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

  Widget _buildAdminDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.red[400]!, Colors.red[600]!],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Admin Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                adminName ?? 'Administrator',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                adminEmail ?? 'admin@resort.com',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Drawer Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Guests Management',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('Guests Management');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.badge,
                  title: 'Staff Management',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('Staff Management');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.local_activity,
                  title: 'Activities Management',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('Activities Management');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.business,
                  title: 'Facilities Management',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('Facilities Management');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.support_agent,
                  title: 'Service Requests',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('Service Requests');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.book_online,
                  title: 'Bookings Management',
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('Bookings Management');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info,
                  title: 'Resort Information',
                  color: Colors.amber,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('Resort Information');
                  },
                ),
                const Divider(color: Colors.grey),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  color: Colors.grey,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 2);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help,
                  title: 'Help & Support',
                  color: Colors.grey,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('Help');
                  },
                ),
              ],
            ),
          ),
          
          // Logout Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _signOut();
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  // Reports & Analytics Helper Methods
  Widget _buildMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            _buildMetricCard('Total Guests', '156', Icons.people, Colors.blue, '+12% from last month'),
            const SizedBox(height: 12),
            _buildMetricCard('Occupancy Rate', '78%', Icons.hotel, Colors.green, '+5% from last month'),
            const SizedBox(height: 12),
            _buildMetricCard('Revenue', '₱2.4M', Icons.attach_money, Colors.orange, '+18% from last month'),
            const SizedBox(height: 12),
            _buildMetricCard('Avg. Rating', '4.7', Icons.star, Colors.purple, '+0.2 from last month'),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, MaterialColor color, String trend) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color[600], size: 20),
              ),
              const Spacer(),
              Icon(Icons.trending_up, color: Colors.green[600], size: 16),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            trend,
            style: TextStyle(
              fontSize: 10,
              color: Colors.green[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analytics Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(
            minHeight: 200,
            maxHeight: 250,
          ),
          width: double.infinity,
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Revenue Trend',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: [
                          // Y-axis labels
                          SizedBox(
                            width: 30,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('₱3M', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                Text('₱2M', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                Text('₱1M', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                Text('₱0', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Chart bars
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildChartBar('Jan', 60, Colors.blue),
                                _buildChartBar('Feb', 75, Colors.green),
                                _buildChartBar('Mar', 85, Colors.orange),
                                _buildChartBar('Apr', 70, Colors.purple),
                                _buildChartBar('May', 90, Colors.red),
                                _buildChartBar('Jun', 95, Colors.teal),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartBar(String month, double height, MaterialColor color) {
    return Flexible(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 20,
            height: height,
            decoration: BoxDecoration(
              color: color[400],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            month,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Reports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final reports = [
              {
                'title': 'Guest Analytics Report',
                'description': 'Comprehensive guest behavior and satisfaction metrics',
                'icon': Icons.people_alt,
                'color': Colors.blue,
                'type': 'Guest Analytics',
              },
              {
                'title': 'Revenue & Financial Report',
                'description': 'Financial performance, revenue streams, and profit analysis',
                'icon': Icons.trending_up,
                'color': Colors.green,
                'type': 'Financial Report',
              },
              {
                'title': 'Occupancy & Booking Report',
                'description': 'Room occupancy rates, booking patterns, and availability trends',
                'icon': Icons.hotel,
                'color': Colors.orange,
                'type': 'Occupancy Report',
              },
              {
                'title': 'Activities & Facilities Report',
                'description': 'Usage statistics for resort activities and facilities',
                'icon': Icons.local_activity,
                'color': Colors.purple,
                'type': 'Activities Report',
              },
              {
                'title': 'Staff Performance Report',
                'description': 'Staff productivity, service quality, and operational efficiency',
                'icon': Icons.badge,
                'color': Colors.teal,
                'type': 'Staff Performance',
              },
            ];
            
            final report = reports[index];
            return _buildReportCard(
              report['title'] as String,
              report['description'] as String,
              report['icon'] as IconData,
              report['color'] as MaterialColor,
              () => _showReportDetails(report['type'] as String),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReportCard(String title, String description, IconData icon, MaterialColor color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 80,
        ),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color[600], size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  void _showReportDetails(String reportType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.analytics, color: Colors.red[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reportType,
                  style: const TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
              maxWidth: 400,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReportSection(reportType),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _exportReport(reportType);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Export PDF'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportSection(String reportType) {
    switch (reportType) {
      case 'Guest Analytics':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportItem('Total Guests This Month', '156 guests'),
            _buildReportItem('New Guests', '89 guests (57%)'),
            _buildReportItem('Returning Guests', '67 guests (43%)'),
            _buildReportItem('Average Stay Duration', '3.2 nights'),
            _buildReportItem('Guest Satisfaction Score', '4.7/5.0'),
            _buildReportItem('Most Popular Room Type', 'Deluxe Room (45%)'),
            _buildReportItem('Peak Check-in Day', 'Friday'),
            _buildReportItem('Average Group Size', '2.3 people'),
          ],
        );
      case 'Financial Report':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportItem('Total Revenue', '₱2,450,000'),
            _buildReportItem('Room Revenue', '₱1,800,000 (73%)'),
            _buildReportItem('Activity Revenue', '₱420,000 (17%)'),
            _buildReportItem('Facility Revenue', '₱230,000 (10%)'),
            _buildReportItem('Average Daily Rate', '₱4,200'),
            _buildReportItem('Revenue Per Guest', '₱15,700'),
            _buildReportItem('Operating Costs', '₱1,200,000'),
            _buildReportItem('Net Profit Margin', '51%'),
          ],
        );
      case 'Occupancy Report':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportItem('Current Occupancy Rate', '78%'),
            _buildReportItem('Average Occupancy (Month)', '74%'),
            _buildReportItem('Peak Occupancy Day', 'Saturday (95%)'),
            _buildReportItem('Lowest Occupancy Day', 'Tuesday (52%)'),
            _buildReportItem('Total Bookings', '234 bookings'),
            _buildReportItem('Cancelled Bookings', '12 bookings (5%)'),
            _buildReportItem('No-show Rate', '2%'),
            _buildReportItem('Average Booking Lead Time', '14 days'),
          ],
        );
      case 'Activities Report':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportItem('Most Popular Activity', 'Island Hopping (78%)'),
            _buildReportItem('Activity Participation Rate', '65%'),
            _buildReportItem('Swimming Pool Usage', '89%'),
            _buildReportItem('Restaurant Capacity', '82%'),
            _buildReportItem('Spa Bookings', '45 bookings'),
            _buildReportItem('Beach Volleyball Games', '23 games'),
            _buildReportItem('Kayaking Sessions', '67 sessions'),
            _buildReportItem('Facility Satisfaction', '4.6/5.0'),
          ],
        );
      case 'Staff Performance':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportItem('Total Staff Members', '45 staff'),
            _buildReportItem('Staff-to-Guest Ratio', '1:3.5'),
            _buildReportItem('Average Response Time', '12 minutes'),
            _buildReportItem('Service Quality Score', '4.5/5.0'),
            _buildReportItem('Front Desk Efficiency', '92%'),
            _buildReportItem('Housekeeping Score', '4.8/5.0'),
            _buildReportItem('Restaurant Service', '4.4/5.0'),
            _buildReportItem('Staff Attendance Rate', '96%'),
          ],
        );
      default:
        return const Text('Report data not available');
    }
  }

  Widget _buildReportItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
        ],
      ),
    );
  }

  void _exportReport(String reportType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Report'),
          content: Text('$reportType has been exported to PDF successfully!'),
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
}
