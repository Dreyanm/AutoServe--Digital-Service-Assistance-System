import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'individual_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String? userName;
  String? userEmail;
  Map<String, int> unreadCounts = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUnreadCounts();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'Guest';
      userEmail = prefs.getString('user_email') ?? 'guest@resort.com';
    });
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load unread counts for staff and admin conversations
      for (String recipientType in ['staff', 'admin']) {
        final String? messagesJson = prefs.getString('chat_messages_$recipientType');
        if (messagesJson != null) {
          final List<dynamic> messagesList = json.decode(messagesJson);
          final List<Map<String, dynamic>> messages = 
              messagesList.map((e) => Map<String, dynamic>.from(e)).toList();
          
          // Count unread messages from recipient (staff/admin messages to user)
          int unreadCount = messages.where((message) => 
              message['senderType'] == recipientType && 
              message['isRead'] == false
          ).length;
          
          setState(() {
            unreadCounts[recipientType] = unreadCount;
          });
        } else {
          setState(() {
            unreadCounts[recipientType] = 0;
          });
        }
      }
    } catch (e) {
      print('Error loading unread counts: $e');
      // Set defaults if there's an error
      setState(() {
        unreadCounts['staff'] = 0;
        unreadCounts['admin'] = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Resort Support',
          style: TextStyle(
            color: Colors.black,
            fontSize: MediaQuery.of(context).size.width > 600 ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width > 600 ? 24.0 : 16.0,
            vertical: 16.0,
          ),
          child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width > 600 ? 20.0 : 16.0,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue[50]!, Colors.blue[100]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.support_agent,
                              color: Colors.blue[600],
                              size: MediaQuery.of(context).size.width > 600 ? 28 : 24,
                            ),
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width > 600 ? 16 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need Help?',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Chat with our staff and administrators for assistance',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width > 600 ? 14 : 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).size.width > 600 ? 24 : 20),

                    Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width > 600 ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),

                    // Staff Chat Option
                    _buildChatOption(
                      title: 'Chat with Staff',
                      subtitle: 'Staff - Customer Service\nGet help with bookings, facilities, and general inquiries',
                      icon: Icons.support_agent,
                      color: Colors.blue,
                      unreadCount: unreadCounts['staff'] ?? 0,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IndividualChatScreen(
                              recipientType: 'staff',
                              recipientName: 'Resort Staff',
                              recipientRole: 'Customer Support',
                            ),
                          ),
                        ).then((_) {
                          // Refresh unread counts when returning
                          _loadUnreadCounts();
                        });
                      },
                    ),

                    SizedBox(height: MediaQuery.of(context).size.width > 600 ? 16 : 12),

                    // Admin Chat Option
                    _buildChatOption(
                      title: 'Chat with Administrator',
                      subtitle: 'Admin - Resort Manager\nFor urgent issues, complaints, or special requests',
                      icon: Icons.admin_panel_settings,
                      color: Colors.red,
                      unreadCount: unreadCounts['admin'] ?? 0,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IndividualChatScreen(
                              recipientType: 'admin',
                              recipientName: 'Resort Administrator',
                              recipientRole: 'Administrator',
                            ),
                          ),
                        ).then((_) {
                          // Refresh unread counts when returning
                          _loadUnreadCounts();
                        });
                      },
                    ),

                    SizedBox(height: MediaQuery.of(context).size.width > 600 ? 32 : 24),

                    // Information Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width > 600 ? 16.0 : 14.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline, 
                            color: Colors.green[600], 
                            size: MediaQuery.of(context).size.width > 600 ? 20 : 18,
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width > 600 ? 12 : 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Response Times',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width > 600 ? 14 : 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Staff: Usually responds within 15 minutes\nAdmin: Usually responds within 30 minutes',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width > 600 ? 12 : 11,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
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

  Widget _buildChatOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required MaterialColor color,
    required int unreadCount,
    required VoidCallback onTap,
  }) {
    final bool isTablet = MediaQuery.of(context).size.width > 600;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
                  decoration: BoxDecoration(
                    color: color[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color[600],
                    size: isTablet ? 28 : 24,
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                // Text content - Expanded to prevent overflow
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 12,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                // Trailing content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (unreadCount > 0) ...[
                      Container(
                        constraints: BoxConstraints(
                          minWidth: isTablet ? 24 : 20,
                          minHeight: isTablet ? 24 : 20,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 8 : 6, 
                          vertical: isTablet ? 4 : 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '$unreadCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 12 : 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                    Icon(
                      Icons.arrow_forward_ios,
                      color: color[400],
                      size: isTablet ? 16 : 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
