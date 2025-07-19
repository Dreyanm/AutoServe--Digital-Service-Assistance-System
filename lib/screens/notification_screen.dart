import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notificationsList = prefs.getStringList('guest_notifications') ?? [];
    
    try {
      final List<Map<String, dynamic>> loadedNotifications = notificationsList
          .map((str) => Map<String, dynamic>.from(json.decode(str)))
          .toList();
      
      // Sort by timestamp (newest first)
      loadedNotifications.sort((a, b) {
        final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      
      // Count unread notifications
      final unreadCount = loadedNotifications.where((notif) => notif['isRead'] == false).length;
      
      setState(() {
        _notifications = loadedNotifications;
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notificationsList = prefs.getStringList('guest_notifications') ?? [];
    
    try {
      final List<String> updatedList = notificationsList.map((str) {
        final Map<String, dynamic> notification = json.decode(str);
        if (notification['id'] == notificationId) {
          notification['isRead'] = true;
        }
        return json.encode(notification);
      }).toList();
      
      await prefs.setStringList('guest_notifications', updatedList);
      _loadNotifications(); // Refresh the list
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notificationsList = prefs.getStringList('guest_notifications') ?? [];
    
    try {
      final List<String> updatedList = notificationsList.map((str) {
        final Map<String, dynamic> notification = json.decode(str);
        notification['isRead'] = true;
        return json.encode(notification);
      }).toList();
      
      await prefs.setStringList('guest_notifications', updatedList);
      _loadNotifications(); // Refresh the list
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notificationsList = prefs.getStringList('guest_notifications') ?? [];
    
    try {
      final List<String> updatedList = notificationsList.where((str) {
        final Map<String, dynamic> notification = json.decode(str);
        return notification['id'] != notificationId;
      }).toList();
      
      await prefs.setStringList('guest_notifications', updatedList);
      _loadNotifications(); // Refresh the list
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      final Duration difference = DateTime.now().difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'support ticket':
        return Icons.support_agent;
      case 'service request':
        return Icons.room_service;
      case 'facility booking':
        return Icons.business;
      case 'activity booking':
        return Icons.local_activity;
      case 'room booking':
        return Icons.hotel;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green[600]!;
      case 'in progress':
        return Colors.orange[600]!;
      case 'under review':
        return Colors.blue[600]!;
      case 'cancelled':
        return Colors.red[600]!;
      case 'confirmed':
      case 'approved':
        return Colors.green[600]!;
      case 'pending':
        return Colors.orange[600]!;
      case 'declined':
      case 'rejected':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount unread',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all read',
                style: TextStyle(color: Colors.blue[600]),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll receive notifications about your bookings,\ntickets, and other updates here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isRead = notification['isRead'] ?? false;
    final String title = notification['title'] ?? 'Notification';
    final String message = notification['message'] ?? '';
    final String timestamp = notification['timestamp'] ?? '';
    final String status = notification['status'] ?? '';
    final String staffName = notification['staffName'] ?? 'Resort Staff';
    final String type = notification['ticketType'] ?? notification['bookingType'] ?? 'notification';
    final String id = notification['id'] ?? '';
    final String bookingName = notification['bookingName'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: isRead
            ? null
            : Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            if (!isRead) {
              await _markAsRead(id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getNotificationColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getNotificationIcon(type),
                        color: _getNotificationColor(status),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[600],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          if (bookingName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              bookingName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                          ),
                          
                          // Special highlighting for declined notifications with reasons
                          if (notification['action'] == 'declined' && 
                              notification['declineReason'] != null && 
                              notification['declineReason'].toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.red[600],
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Decline Reason',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notification['declineReason'].toString(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.red[800],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                staffName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimestamp(timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onSelected: (value) async {
                        switch (value) {
                          case 'mark_read':
                            await _markAsRead(id);
                            break;
                          case 'delete':
                            await _deleteNotification(id);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (!isRead)
                          const PopupMenuItem(
                            value: 'mark_read',
                            child: Row(
                              children: [
                                Icon(Icons.mark_email_read, size: 20),
                                SizedBox(width: 8),
                                Text('Mark as read'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getNotificationColor(status),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
