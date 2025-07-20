import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StaffAdminChatScreen extends StatefulWidget {
  final String staffId;
  final String staffName;

  const StaffAdminChatScreen({
    Key? key,
    required this.staffId,
    required this.staffName,
  }) : super(key: key);

  @override
  State<StaffAdminChatScreen> createState() => _StaffAdminChatScreenState();
}

class _StaffAdminChatScreenState extends State<StaffAdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startMessagePolling();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String conversationKey = 'staff_admin_chat_${widget.staffId}';
      final String? messagesJson = prefs.getString(conversationKey);
      
      if (messagesJson != null) {
        final List<dynamic> messagesList = json.decode(messagesJson);
        setState(() {
          _messages = messagesList.map((e) => Map<String, dynamic>.from(e)).toList();
        });
        
        // Mark admin messages as read when staff opens the chat
        await _markAdminMessagesAsRead();
        
        // Scroll to bottom after loading messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _markAdminMessagesAsRead() async {
    try {
      bool hasUnreadAdminMessages = false;
      for (var message in _messages) {
        if (message['senderType'] == 'admin' && message['isRead'] == false) {
          message['isRead'] = true;
          hasUnreadAdminMessages = true;
        }
      }
      
      if (hasUnreadAdminMessages) {
        await _saveMessages();
      }
    } catch (e) {
      print('Error marking admin messages as read: $e');
    }
  }

  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String conversationKey = 'staff_admin_chat_${widget.staffId}';
      await prefs.setString(conversationKey, json.encode(_messages));
      
      // Also save to admin's global conversations for admin panel access
      await _saveToAdminConversations();
    } catch (e) {
      print('Error saving messages: $e');
    }
  }

  Future<void> _saveToAdminConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get or create admin global conversations
      Map<String, dynamic> adminConversations = {};
      final String? adminConversationsJson = prefs.getString('admin_staff_conversations');
      
      if (adminConversationsJson != null) {
        adminConversations = Map<String, dynamic>.from(json.decode(adminConversationsJson));
      }
      
      // Create conversation ID
      final String conversationId = 'staff_${widget.staffId}_admin';
      
      // Update or create this conversation in admin's view
      adminConversations[conversationId] = {
        'conversationId': conversationId,
        'staffId': widget.staffId,
        'staffName': widget.staffName,
        'messages': _messages,
        'lastMessage': _messages.isNotEmpty ? _messages.last : null,
        'lastActivity': DateTime.now().toIso8601String(),
        'unreadCount': _messages.where((m) => m['senderType'] == 'staff' && m['isRead'] == false).length,
      };
      
      // Save updated admin conversations
      await prefs.setString('admin_staff_conversations', json.encode(adminConversations));
    } catch (e) {
      print('Error saving to admin conversations: $e');
    }
  }

  void _startMessagePolling() {
    // Poll for new messages every 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkForNewMessages();
        _startMessagePolling();
      }
    });
  }

  Future<void> _checkForNewMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String conversationKey = 'staff_admin_chat_${widget.staffId}';
      final String? messagesJson = prefs.getString(conversationKey);
      
      if (messagesJson != null) {
        final List<dynamic> messagesList = json.decode(messagesJson);
        final List<Map<String, dynamic>> newMessages = 
            messagesList.map((e) => Map<String, dynamic>.from(e)).toList();
        
        if (newMessages.length != _messages.length) {
          setState(() {
            _messages = newMessages;
          });
          
          // Mark any new admin messages as read since staff is in the chat
          await _markAdminMessagesAsRead();
          
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final String messageText = _messageController.text.trim();
      final String messageId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final Map<String, dynamic> newMessage = {
        'id': messageId,
        'message': messageText,
        'senderType': 'staff',
        'senderName': widget.staffName,
        'senderId': widget.staffId,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'recipientType': 'admin',
      };

      setState(() {
        _messages.add(newMessage);
      });

      _messageController.clear();
      await _saveMessages();
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
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

  String _formatMessageTime(String timestamp) {
    try {
      final DateTime messageTime = DateTime.parse(timestamp);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(messageTime);
      
      if (difference.inMinutes < 1) {
        return 'now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Icon(
                Icons.admin_panel_settings,
                color: Colors.blue[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Staff-Admin Chat',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[100],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                    ),
                    child: _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Start conversation with Admin',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Send a message to get started',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isStaff = message['senderType'] == 'staff';
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: isStaff
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isStaff) ...[
                                      CircleAvatar(
                                        backgroundColor: Colors.red[100],
                                        radius: 16,
                                        child: Icon(
                                          Icons.admin_panel_settings,
                                          color: Colors.red[600],
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Flexible(
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isStaff ? Colors.blue[600] : Colors.white,
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(18),
                                            topRight: const Radius.circular(18),
                                            bottomLeft: Radius.circular(isStaff ? 18 : 4),
                                            bottomRight: Radius.circular(isStaff ? 4 : 18),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message['message'],
                                              style: TextStyle(
                                                color: isStaff ? Colors.white : Colors.black87,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatMessageTime(message['timestamp']),
                                              style: TextStyle(
                                                color: isStaff 
                                                    ? Colors.blue[100] 
                                                    : Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isStaff) ...[
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        backgroundColor: Colors.blue[100],
                                        radius: 16,
                                        child: Icon(
                                          Icons.support_agent,
                                          color: Colors.blue[600],
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
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
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    decoration: const InputDecoration(
                                      hintText: 'Type a message to admin...',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(color: Colors.grey),
                                    ),
                                    maxLines: null,
                                    textCapitalization: TextCapitalization.sentences,
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.emoji_emotions_outlined),
                                  color: Colors.grey[600],
                                  onPressed: () {
                                    // Emoji picker can be implemented here
                                  },
                                ),
                              ],
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
                            icon: const Icon(Icons.send),
                            color: Colors.white,
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
