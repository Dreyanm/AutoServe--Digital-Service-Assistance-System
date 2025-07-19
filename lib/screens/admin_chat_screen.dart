import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminChatScreen extends StatefulWidget {
  final String guestName;
  final String guestEmail;
  final String conversationId;

  const AdminChatScreen({
    Key? key,
    required this.guestName,
    required this.guestEmail,
    required this.conversationId,
  }) : super(key: key);

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  String? _adminName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _loadConversation();
    _startMessagePolling();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminName = prefs.getString('admin_name') ?? 'Admin';
    });
  }

  Future<void> _loadConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? conversationsJson = prefs.getString('global_conversations');
      
      if (conversationsJson != null) {
        final Map<String, dynamic> allConversations = json.decode(conversationsJson);
        
        if (allConversations.containsKey(widget.conversationId)) {
          final conversation = allConversations[widget.conversationId];
          final List<dynamic> messagesList = conversation['messages'] ?? [];
          setState(() {
            _messages = messagesList.map((e) => Map<String, dynamic>.from(e)).toList();
          });
          
          // Mark messages as read by admin
          await _markMessagesAsRead();
        }
      }
    } catch (e) {
      print('Error loading conversation: $e');
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
        // Mark messages from guest as read when admin views them
        if (message['senderType'] == 'user' && message['isRead'] == false) {
          message['isRead'] = true;
          hasUnread = true;
        }
      }
      
      if (hasUnread) {
        await _saveConversation();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _saveConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update global conversations
      final String? conversationsJson = prefs.getString('global_conversations');
      Map<String, dynamic> allConversations = {};
      
      if (conversationsJson != null) {
        allConversations = Map<String, dynamic>.from(json.decode(conversationsJson));
      }
      
      // Update this conversation
      allConversations[widget.conversationId] = {
        'conversationId': widget.conversationId,
        'conversationName': widget.guestName,
        'customerName': widget.guestName,
        'customerEmail': widget.guestEmail,
        'recipientType': 'admin',
        'messages': _messages,
        'lastMessage': _messages.isNotEmpty ? _messages.last : null,
        'lastActivity': DateTime.now().toIso8601String(),
        'unreadCount': _messages.where((m) => m['senderType'] == 'user' && m['isRead'] == false).length,
      };
      
      // Save updated conversations
      await prefs.setString('global_conversations', json.encode(allConversations));
      
      // Also update the guest's individual chat storage
      await prefs.setString('chat_messages_admin', json.encode(_messages));
    } catch (e) {
      print('Error saving conversation: $e');
    }
  }

  void _startMessagePolling() {
    // Poll for new messages every 2 seconds
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
      final String? conversationsJson = prefs.getString('global_conversations');
      
      if (conversationsJson != null) {
        final Map<String, dynamic> allConversations = json.decode(conversationsJson);
        
        if (allConversations.containsKey(widget.conversationId)) {
          final conversation = allConversations[widget.conversationId];
          final List<dynamic> messagesList = conversation['messages'] ?? [];
          final List<Map<String, dynamic>> newMessages = 
              messagesList.map((e) => Map<String, dynamic>.from(e)).toList();
          
          if (newMessages.length != _messages.length) {
            setState(() {
              _messages = newMessages;
            });
            
            // Mark new messages as read
            await _markMessagesAsRead();
            
            // Scroll to bottom if new messages arrived
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollToBottom();
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error checking for new messages: $e');
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final String messageText = _messageController.text.trim();
      final String messageId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final Map<String, dynamic> newMessage = {
        'id': messageId,
        'message': messageText,
        'senderType': 'admin',
        'senderName': _adminName ?? 'Admin',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'recipientType': 'user',
      };

      setState(() {
        _messages.add(newMessage);
      });

      _messageController.clear();
      await _saveConversation();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.red[600],
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
                Icons.person,
                color: Colors.red[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.guestName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Guest',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[100],
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
                      image: DecorationImage(
                        image: AssetImage('assets/chat_background.png'),
                        fit: BoxFit.cover,
                        opacity: 0.1,
                      ),
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
                                  'Start conversation with ${widget.guestName}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
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
                              final isAdmin = message['senderType'] == 'admin';
                              final timestamp = DateTime.parse(message['timestamp']);
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: isAdmin
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isAdmin) ...[
                                      CircleAvatar(
                                        backgroundColor: Colors.red[100],
                                        radius: 16,
                                        child: Icon(
                                          Icons.person,
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
                                          color: isAdmin ? Colors.red[600] : Colors.white,
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(18),
                                            topRight: const Radius.circular(18),
                                            bottomLeft: Radius.circular(isAdmin ? 18 : 4),
                                            bottomRight: Radius.circular(isAdmin ? 4 : 18),
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
                                                color: isAdmin ? Colors.white : Colors.black87,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatMessageTime(timestamp),
                                              style: TextStyle(
                                                color: isAdmin 
                                                    ? Colors.red[100] 
                                                    : Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isAdmin) ...[
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        backgroundColor: Colors.red[600],
                                        radius: 16,
                                        child: const Icon(
                                          Icons.admin_panel_settings,
                                          color: Colors.white,
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
                                      hintText: 'Type a message...',
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
                            color: Colors.red[600],
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

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
