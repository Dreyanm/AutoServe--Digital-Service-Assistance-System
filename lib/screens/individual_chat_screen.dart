import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class IndividualChatScreen extends StatefulWidget {
  final String recipientType; // 'staff' or 'admin'
  final String recipientName;
  final String recipientRole;

  const IndividualChatScreen({
    Key? key,
    required this.recipientType,
    required this.recipientName,
    required this.recipientRole,
  }) : super(key: key);

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  String? _userName;
  String? _userEmail;
  bool _isLoading = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMessages();
    _startMessagePolling();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh messages when screen becomes active
    _checkForNewMessages();
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
      _userName = prefs.getString('user_name') ?? 'Guest';
      _userEmail = prefs.getString('user_email') ?? 'guest@resort.com';
    });
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String messageKey = 'chat_messages_${widget.recipientType}';
    final String? messagesJson = prefs.getString(messageKey);
    
    if (messagesJson != null) {
      final List<dynamic> messagesList = json.decode(messagesJson);
      setState(() {
        _messages = messagesList.map((e) => Map<String, dynamic>.from(e)).toList();
      });

      // Mark messages as read
      await _markMessagesAsRead();
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

  Future<void> _markMessagesAsRead() async {
    try {
      bool hasUnread = false;
      for (var message in _messages) {
        // Mark messages from staff/admin as read when guest views them
        if (message['senderType'] == widget.recipientType && message['isRead'] == false) {
          message['isRead'] = true;
          hasUnread = true;
        }
      }
      
      if (hasUnread) {
        await _saveMessages();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String messageKey = 'chat_messages_${widget.recipientType}';
      final String messagesJson = json.encode(_messages);
      await prefs.setString(messageKey, messagesJson);
      
      // Also save to global message queue for staff/admin access
      await _saveToGlobalQueue();
    } catch (e) {
      print('Error saving messages: $e');
    }
  }

  Future<void> _saveToGlobalQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get conversation ID based on user and recipient type
      String conversationId = '${_userEmail}_${widget.recipientType}';
      
      // Load existing global conversations
      Map<String, dynamic> globalConversations = {};
      final String? conversationsJson = prefs.getString('global_conversations');
      
      if (conversationsJson != null) {
        globalConversations = Map<String, dynamic>.from(json.decode(conversationsJson));
      }
      
      // Update this conversation
      globalConversations[conversationId] = {
        'conversationId': conversationId,
        'conversationName': _userName ?? 'Guest',
        'customerName': _userName ?? 'Guest',
        'customerEmail': _userEmail ?? 'guest@resort.com',
        'recipientType': widget.recipientType,
        'messages': _messages,
        'lastMessage': _messages.isNotEmpty ? _messages.last : null,
        'lastActivity': DateTime.now().toIso8601String(),
        'unreadCount': _messages.where((m) => m['senderType'] == 'user' && m['isRead'] == false).length,
      };
      
      // Save updated conversations
      final String updatedConversationsJson = json.encode(globalConversations);
      await prefs.setString('global_conversations', updatedConversationsJson);
    } catch (e) {
      print('Error saving to global queue: $e');
    }
  }

  void _startMessagePolling() {
    // Poll for new messages every 2 seconds for more responsive chat
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkForNewMessages();
        _startMessagePolling();
      }
    });
  }

  Future<void> _checkForNewMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String messageKey = 'chat_messages_${widget.recipientType}';
      final String? messagesJson = prefs.getString(messageKey);
      
      if (messagesJson != null) {
        final List<dynamic> messagesList = json.decode(messagesJson);
        final List<Map<String, dynamic>> newMessages = 
            messagesList.map((e) => Map<String, dynamic>.from(e)).toList();
        
        // Sort messages by timestamp to ensure proper order
        newMessages.sort((a, b) {
          final aTime = DateTime.parse(a['timestamp']);
          final bTime = DateTime.parse(b['timestamp']);
          return aTime.compareTo(bTime);
        });
        
        if (newMessages.length != _messages.length || 
            !_messagesAreEqual(newMessages, _messages)) {
          setState(() {
            _messages = newMessages;
          });
          
          // Mark new messages from staff/admin as read
          await _markMessagesAsRead();
          
          // Scroll to bottom if new messages arrived
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollToBottom();
            }
          });
        }
      }
    } catch (e) {
      print('Error checking for new messages: $e');
    }
  }

  bool _messagesAreEqual(List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i]['id'] != list2[i]['id']) {
        return false;
      }
    }
    return true;
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final String messageText = _messageController.text.trim();
      final String messageId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final Map<String, dynamic> newMessage = {
        'id': messageId,
        'message': messageText,
        'senderType': 'user',
        'senderName': _userName ?? 'Guest',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'recipientType': widget.recipientType,
      };

      setState(() {
        _messages.add(newMessage);
      });

      _messageController.clear();
      await _saveMessages();
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      // Show error to user if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final MaterialColor primaryColor = widget.recipientType == 'admin' ? Colors.red : Colors.blue;
    
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                widget.recipientType == 'admin' ? Icons.admin_panel_settings : Icons.support_agent,
                color: primaryColor[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipientName,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isOnline ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: primaryColor[600]),
            onPressed: () {
              _showInfoDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
          ),
          
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: primaryColor[600]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: primaryColor[600],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final MaterialColor primaryColor = widget.recipientType == 'admin' ? Colors.red : Colors.blue;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor[100],
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              widget.recipientType == 'admin' ? Icons.admin_panel_settings : Icons.support_agent,
              color: primaryColor[600],
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to ${widget.recipientName}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isUser = message['senderType'] == 'user';
    final MaterialColor primaryColor = widget.recipientType == 'admin' ? Colors.red : Colors.blue;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                widget.recipientType == 'admin' ? Icons.admin_panel_settings : Icons.support_agent,
                color: primaryColor[600],
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? primaryColor[600] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Text(
                      widget.recipientName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor[600],
                      ),
                    ),
                  if (!isUser) const SizedBox(height: 4),
                  Text(
                    message['message'],
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message['timestamp']),
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    final DateTime dateTime = DateTime.parse(timestamp);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

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

  void _showInfoDialog() {
    final MaterialColor primaryColor = widget.recipientType == 'admin' ? Colors.red : Colors.blue;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                widget.recipientType == 'admin' ? Icons.admin_panel_settings : Icons.support_agent,
                color: primaryColor[600],
              ),
              const SizedBox(width: 8),
              Text(widget.recipientName),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Role: ${widget.recipientRole}'),
              const SizedBox(height: 8),
              Text(
                widget.recipientType == 'admin'
                    ? 'Contact the administrator for urgent issues, complaints, or special requests.'
                    : 'Contact staff for help with bookings, facilities, and general inquiries.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: primaryColor[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Messages are monitored and stored for quality assurance.',
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor[700],
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
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
