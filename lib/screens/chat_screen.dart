import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  String? _userName;
  String? _userId;
  bool _isLoading = true;
  bool _isOnline = true;
  List<Map<String, dynamic>> _staffMembers = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMessages();
    _loadStaffMembers();
    _startMessagePolling();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      _userId = prefs.getString('user_email') ?? DateTime.now().millisecondsSinceEpoch.toString();
    });
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? messagesJson = prefs.getString('chat_messages');
    
    if (messagesJson != null) {
      final List<dynamic> messagesList = json.decode(messagesJson);
      setState(() {
        _messages = messagesList.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
    
    setState(() {
      _isLoading = false;
    });
    
    // Scroll to bottom after loading messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollToBottom();
      }
    });
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String messagesJson = json.encode(_messages);
    await prefs.setString('chat_messages', messagesJson);
    
    // Also save to a global message queue for staff/admin access
    await _saveToGlobalQueue();
  }

  Future<void> _loadStaffMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? staffJson = prefs.getString('staff_members');
    
    if (staffJson != null) {
      final List<dynamic> staffList = json.decode(staffJson);
      setState(() {
        _staffMembers = staffList.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } else {
      // Initialize default staff members
      _staffMembers = [
        {
          'id': 'staff_001',
          'name': 'Sarah Johnson',
          'role': 'Customer Service',
          'isOnline': true,
          'lastSeen': DateTime.now().toIso8601String(),
        },
        {
          'id': 'staff_002', 
          'name': 'Mark Rodriguez',
          'role': 'Resort Manager',
          'isOnline': true,
          'lastSeen': DateTime.now().toIso8601String(),
        },
        {
          'id': 'admin_001',
          'name': 'Admin Panel',
          'role': 'Administrator',
          'isOnline': true,
          'lastSeen': DateTime.now().toIso8601String(),
        },
      ];
      await _saveStaffMembers();
    }
  }

  Future<void> _saveStaffMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final String staffJson = json.encode(_staffMembers);
    await prefs.setString('staff_members', staffJson);
  }

  Future<void> _saveToGlobalQueue() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save user messages to a global queue that staff can access
    List<Map<String, dynamic>> globalQueue = [];
    final String? queueJson = prefs.getString('global_message_queue');
    
    if (queueJson != null) {
      final List<dynamic> queueList = json.decode(queueJson);
      globalQueue = queueList.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    
    // Add new user messages to global queue
    for (var message in _messages) {
      if (message['senderType'] == 'user' && !globalQueue.any((m) => m['id'] == message['id'])) {
        globalQueue.add({
          ...message,
          'conversationId': _userId,
          'conversationName': _userName,
          'needsResponse': true,
          'assignedTo': null,
        });
      }
    }
    
    final String updatedQueueJson = json.encode(globalQueue);
    await prefs.setString('global_message_queue', updatedQueueJson);
  }

  Future<void> _startMessagePolling() async {
    // Initialize staff workflow
    await _createStaffInterface();
    
    // Poll for new messages from staff/admin every 5 seconds
    while (mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        await _checkForNewMessages();
        // Trigger staff workflow simulation
        _simulateStaffWorkflow();
      }
    }
  }

  Future<void> _checkForNewMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? responseJson = prefs.getString('staff_responses_${_userId}');
    
    if (responseJson != null) {
      final List<dynamic> responseList = json.decode(responseJson);
      final List<Map<String, dynamic>> newResponses = 
          responseList.map((e) => Map<String, dynamic>.from(e)).toList();
      
      // Add new responses to messages if not already present
      bool hasNewMessages = false;
      for (var response in newResponses) {
        if (!_messages.any((m) => m['id'] == response['id'])) {
          setState(() {
            _messages.add(response);
          });
          hasNewMessages = true;
        }
      }
      
      if (hasNewMessages) {
        await _saveMessages();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
        
        // Show notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New message from ${newResponses.last['sender']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        // Clear the responses to avoid duplicates
        await prefs.remove('staff_responses_${_userId}');
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final String messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final Map<String, dynamic> newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': messageText,
      'sender': _userName ?? 'User',
      'senderId': _userId,
      'senderType': 'user',
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
      'status': 'sent', // sent, delivered, read
      'priority': _determinePriority(messageText),
    };

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    await _saveMessages();
    
    // Scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Message sent to support team'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Notify staff about new message
    await _notifyStaff(newMessage);
  }

  String _determinePriority(String message) {
    final String lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('urgent') || lowerMessage.contains('emergency') || 
        lowerMessage.contains('help') || lowerMessage.contains('problem')) {
      return 'high';
    } else if (lowerMessage.contains('question') || lowerMessage.contains('info')) {
      return 'medium';
    }
    return 'normal';
  }

  Future<void> _notifyStaff(Map<String, dynamic> message) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Add to staff notification queue
    List<Map<String, dynamic>> notifications = [];
    final String? notifJson = prefs.getString('staff_notifications');
    
    if (notifJson != null) {
      final List<dynamic> notifList = json.decode(notifJson);
      notifications = notifList.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    
    notifications.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'messageId': message['id'],
      'fromUser': message['sender'],
      'fromUserId': message['senderId'],
      'preview': message['text'].length > 50 
          ? '${message['text'].substring(0, 50)}...' 
          : message['text'],
      'priority': message['priority'],
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    });
    
    final String updatedNotifJson = json.encode(notifications);
    await prefs.setString('staff_notifications', updatedNotifJson);
    
    // Update message status to delivered
    message['status'] = 'delivered';
    await _saveMessages();
  }

  // Staff Interface Management - This simulates staff responses but in a more realistic way
  Future<void> _createStaffInterface() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Create a simple staff dashboard data structure
    final Map<String, dynamic> staffDashboard = {
      'activeConversations': [],
      'staffMembers': _staffMembers,
      'messageQueue': [],
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString('staff_dashboard', json.encode(staffDashboard));
  }

  Future<void> _simulateStaffWorkflow() async {
    // This represents a real staff member responding to messages
    // In a real app, this would be replaced by actual staff using a separate interface
    
    await Future.delayed(Duration(seconds: 10 + (DateTime.now().millisecond % 20)));
    
    final prefs = await SharedPreferences.getInstance();
    final String? queueJson = prefs.getString('staff_notifications');
    
    if (queueJson != null && mounted) {
      final List<dynamic> notifications = json.decode(queueJson);
      
      if (notifications.isNotEmpty) {
        // Get the latest unread notification for this user
        final userNotifications = notifications.where((n) => 
            n['fromUserId'] == _userId && !n['isRead']).toList();
        
        if (userNotifications.isNotEmpty) {
          final notification = userNotifications.last;
          
          // Simulate staff member picking up the message
          final staffMember = _getAvailableStaffMember();
          
          // Create staff response
          final Map<String, dynamic> staffResponse = {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'text': _generateRealStaffResponse(notification['preview'], staffMember),
            'sender': staffMember['name'],
            'senderId': staffMember['id'],
            'senderType': staffMember['role'] == 'Administrator' ? 'admin' : 'staff',
            'timestamp': DateTime.now().toIso8601String(),
            'isRead': false,
            'status': 'sent',
            'replyTo': notification['messageId'],
          };
          
          // Save response for user to receive
          List<Map<String, dynamic>> responses = [];
          final String? responseJson = prefs.getString('staff_responses_${_userId}');
          
          if (responseJson != null) {
            final List<dynamic> responseList = json.decode(responseJson);
            responses = responseList.map((e) => Map<String, dynamic>.from(e)).toList();
          }
          
          responses.add(staffResponse);
          await prefs.setString('staff_responses_${_userId}', json.encode(responses));
          
          // Mark notification as handled
          notification['isRead'] = true;
          notification['handledBy'] = staffMember['id'];
          notification['handledAt'] = DateTime.now().toIso8601String();
          
          await prefs.setString('staff_notifications', json.encode(notifications));
        }
      }
    }
  }

  Map<String, dynamic> _getAvailableStaffMember() {
    final availableStaff = _staffMembers.where((staff) => staff['isOnline']).toList();
    if (availableStaff.isEmpty) return _staffMembers.first;
    
    // Distribute workload - pick staff member with least recent activity
    return availableStaff.first;
  }

  String _generateRealStaffResponse(String userMessagePreview, Map<String, dynamic> staffMember) {
    final String lowerMessage = userMessagePreview.toLowerCase();
    final String staffName = staffMember['name'];
    final String role = staffMember['role'];
    
    // More realistic staff responses based on role
    if (role == 'Administrator') {
      if (lowerMessage.contains('problem') || lowerMessage.contains('complaint')) {
        return "Hello! This is $staffName from the Admin team. I've received your concern and I'm personally looking into this matter. Could you please provide more details so I can resolve this quickly for you?";
      } else if (lowerMessage.contains('cancel') || lowerMessage.contains('refund')) {
        return "Hi! $staffName here from Administration. I can help you with cancellations and refunds. Please provide your booking reference number and I'll process this immediately.";
      } else {
        return "Hello! This is $staffName from the Resort Administration. I'm here to personally assist you with any questions or concerns. How can I help you today?";
      }
    } else if (role == 'Resort Manager') {
      if (lowerMessage.contains('room') || lowerMessage.contains('accommodation')) {
        return "Hello! $staffName, Resort Manager here. I'd be happy to help you with room-related inquiries. What specific information do you need about our accommodations?";
      } else if (lowerMessage.contains('facility') || lowerMessage.contains('amenity')) {
        return "Hi! This is $staffName, your Resort Manager. I can provide detailed information about all our facilities and help coordinate your resort experience. What would you like to know?";
      } else {
        return "Hello! $staffName, Resort Manager speaking. I'm here to ensure you have the best possible experience at our resort. How may I assist you today?";
      }
    } else { // Customer Service
      if (lowerMessage.contains('book') || lowerMessage.contains('reservation')) {
        return "Hello! This is $staffName from Customer Service. I'd be delighted to help you with your booking. Let me know what you'd like to reserve and I'll guide you through the process.";
      } else if (lowerMessage.contains('question') || lowerMessage.contains('info')) {
        return "Hi there! $staffName from Customer Service here. I'm ready to answer any questions you have about our resort, facilities, or services. What would you like to know?";
      } else {
        return "Hello! This is $staffName from Customer Service. Thank you for reaching out! I'm here to help make your resort experience wonderful. What can I assist you with?";
      }
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isUser = message['senderType'] == 'user';
    final DateTime timestamp = DateTime.parse(message['timestamp']);
    final String status = message['status'] ?? 'sent';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: message['senderType'] == 'admin' 
                  ? Colors.red[100] 
                  : Colors.blue[100],
              child: Icon(
                message['senderType'] == 'admin' 
                    ? Icons.admin_panel_settings 
                    : Icons.support_agent,
                size: 20,
                color: message['senderType'] == 'admin' 
                    ? Colors.red[600] 
                    : Colors.blue[600],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[600] : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Row(
                      children: [
                        Text(
                          message['sender'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: message['senderType'] == 'admin' 
                                ? Colors.red[600] 
                                : Colors.blue[600],
                          ),
                        ),
                        if (message['senderType'] == 'admin') ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        if (_isOnline && !isUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message['text'],
                    style: TextStyle(
                      fontSize: 16,
                      color: isUser ? Colors.white : Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isUser ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 6),
                        Icon(
                          status == 'sent' ? Icons.check 
                              : status == 'delivered' ? Icons.done_all 
                              : Icons.done_all,
                          size: 14,
                          color: status == 'read' ? Colors.blue[200] : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue[100],
              child: Icon(
                Icons.person,
                size: 20,
                color: Colors.blue[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildWelcomeMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[50]!, Colors.blue[100]!],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.support_agent,
                  size: 64,
                  color: Colors.blue[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome to Live Resort Support',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Connect directly with our live support team! Our staff and administrators are here to assist you with any questions, bookings, or concerns.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.circle, color: Colors.white, size: 12),
                            const SizedBox(width: 8),
                            Text(
                              'Staff Online',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.schedule, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Quick Response',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our Support Team:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                ..._staffMembers.take(3).map((staff) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: staff['role'] == 'Administrator' 
                            ? Colors.red[100] 
                            : Colors.blue[100],
                        child: Icon(
                          staff['role'] == 'Administrator' 
                              ? Icons.admin_panel_settings 
                              : Icons.support_agent,
                          size: 16,
                          color: staff['role'] == 'Administrator' 
                              ? Colors.red[600] 
                              : Colors.blue[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              staff['role'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: staff['isOnline'] ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
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
        title: Row(
          children: [
            Stack(
              children: [
                Icon(Icons.support_agent, color: Colors.blue[600], size: 28),
                if (_isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Support Chat',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_staffMembers.where((s) => s['isOnline']).length} staff members online',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.people_outline, color: Colors.blue[600]),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support Team',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._staffMembers.map((staff) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: staff['role'] == 'Administrator' 
                                  ? Colors.red[100] 
                                  : Colors.blue[100],
                              child: Icon(
                                staff['role'] == 'Administrator' 
                                    ? Icons.admin_panel_settings 
                                    : Icons.support_agent,
                                color: staff['role'] == 'Administrator' 
                                    ? Colors.red[600] 
                                    : Colors.blue[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    staff['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    staff['role'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: staff['isOnline'] ? Colors.green[100] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                staff['isOnline'] ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: staff['isOnline'] ? Colors.green[700] : Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Messages are routed to available staff members automatically. All team members can see and respond to your queries.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.blue[600]),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Live Chat Information'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Connect directly with live staff and administrators'),
                      const SizedBox(height: 8),
                      Text('• Real-time messaging with read receipts'),
                      const SizedBox(height: 8),
                      Text('• Priority routing for urgent requests'),
                      const SizedBox(height: 8),
                      Text('• All conversations are saved securely'),
                      const SizedBox(height: 8),
                      Text('• Staff typically respond within minutes'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.blue[600]),
            )
          : Column(
              children: [
                // Chat messages
                Expanded(
                  child: _messages.isEmpty
                      ? SingleChildScrollView(
                          child: _buildWelcomeMessage(),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageBubble(_messages[index]);
                          },
                        ),
                ),

                // Message input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: TextField(
                              controller: _messageController,
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
