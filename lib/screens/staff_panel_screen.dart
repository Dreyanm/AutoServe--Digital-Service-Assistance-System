import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StaffPanelScreen extends StatefulWidget {
  const StaffPanelScreen({Key? key}) : super(key: key);

  @override
  State<StaffPanelScreen> createState() => _StaffPanelScreenState();
}

class _StaffPanelScreenState extends State<StaffPanelScreen> {
  final TextEditingController _responseController = TextEditingController();
  List<Map<String, dynamic>> _conversations = [];
  Map<String, dynamic>? _selectedConversation;
  List<Map<String, dynamic>> _staffMembers = [];
  String? _currentStaffId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaffData();
    _loadConversations();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _loadStaffData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? staffJson = prefs.getString('staff_members');
    
    if (staffJson != null) {
      final List<dynamic> staffList = json.decode(staffJson);
      setState(() {
        _staffMembers = staffList.map((e) => Map<String, dynamic>.from(e)).toList();
        _currentStaffId = _staffMembers.isNotEmpty ? _staffMembers.first['id'] : null;
        _isLoading = false;
      });
    } else {
      // Initialize default staff members if none exist
      _staffMembers = [
        {
          'id': 'staff_001',
          'name': 'Staff1',
          'role': 'Customer Service',
          'isOnline': true,
          'lastSeen': DateTime.now().toIso8601String(),
        },
        {
          'id': 'staff_002', 
          'name': 'Staff2',
          'role': 'Resort Manager',
          'isOnline': true,
          'lastSeen': DateTime.now().toIso8601String(),
        },
      ];
      
      // Save default staff members
      final String staffJsonToSave = json.encode(_staffMembers);
      await prefs.setString('staff_members', staffJsonToSave);
      
      setState(() {
        _currentStaffId = _staffMembers.isNotEmpty ? _staffMembers.first['id'] : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? conversationsJson = prefs.getString('global_conversations');
    
    if (conversationsJson != null) {
      final Map<String, dynamic> conversationsMap = json.decode(conversationsJson);
      
      List<Map<String, dynamic>> conversations = [];
      conversationsMap.forEach((conversationId, conversationData) {
        // Only include staff conversations, filter out admin conversations
        if (conversationId.contains('staff')) {
          final conversationCopy = Map<String, dynamic>.from(conversationData);
          
          // Ensure messages list exists
          if (conversationCopy['messages'] == null) {
            conversationCopy['messages'] = [];
          }
          
          // Update the selected conversation if it matches
          if (_selectedConversation != null && 
              _selectedConversation!['conversationId'] == conversationId) {
            setState(() {
              _selectedConversation = conversationCopy;
            });
          }
          
          conversations.add(conversationCopy);
        }
      });
      
      // Sort by last activity
      conversations.sort((a, b) {
        final aTime = DateTime.parse(a['lastActivity'] ?? DateTime.now().toIso8601String());
        final bTime = DateTime.parse(b['lastActivity'] ?? DateTime.now().toIso8601String());
        return bTime.compareTo(aTime);
      });
      
      setState(() {
        _conversations = conversations;
      });
    }
  }

  Future<void> _sendResponse() async {
    // Debug logging
    print('Send response called');
    print('Selected conversation: $_selectedConversation');
    print('Response text: "${_responseController.text.trim()}"');
    print('Current staff ID: $_currentStaffId');
    print('Staff members: $_staffMembers');
    
    if (_selectedConversation == null) {
      print('Error: No conversation selected');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a conversation first'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    if (_responseController.text.trim().isEmpty) {
      print('Error: Empty message');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a message'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    if (_currentStaffId == null || _staffMembers.isEmpty) {
      print('Error: No staff data available');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Staff data not loaded. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final String responseText = _responseController.text.trim();
      final String conversationId = _selectedConversation!['conversationId'];
      final currentStaff = _staffMembers.firstWhere(
        (s) => s['id'] == _currentStaffId,
        orElse: () => _staffMembers.first,
      );

      print('Sending response from: ${currentStaff['name']} (${currentStaff['role']})');

      final Map<String, dynamic> response = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'message': responseText,
        'senderName': currentStaff['name'],
        'senderId': currentStaff['id'],
        'senderType': 'staff',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'recipientType': 'user',
      };

      print('Response object created: $response');

      final prefs = await SharedPreferences.getInstance();
      
      // Update the selected conversation immediately to show the new message
      if (_selectedConversation != null) {
        setState(() {
          (_selectedConversation!['messages'] as List).add(response);
        });
        print('Updated UI with new message');
      }

      // Update the global conversations with the new message
      final String? conversationsJson = prefs.getString('global_conversations');
      if (conversationsJson != null) {
        final Map<String, dynamic> conversationsMap = json.decode(conversationsJson);
        
        // Update the specific conversation
        if (conversationsMap.containsKey(conversationId)) {
          conversationsMap[conversationId]['needsResponse'] = false;
          conversationsMap[conversationId]['handledBy'] = _currentStaffId;
          conversationsMap[conversationId]['handledAt'] = DateTime.now().toIso8601String();
          conversationsMap[conversationId]['lastActivity'] = DateTime.now().toIso8601String();
          conversationsMap[conversationId]['lastMessage'] = response;
          
          // Add the new message to the conversation messages
          if (conversationsMap[conversationId]['messages'] != null) {
            (conversationsMap[conversationId]['messages'] as List).add(response);
          } else {
            conversationsMap[conversationId]['messages'] = [response];
          }
          
          // Reset unread count since staff responded
          conversationsMap[conversationId]['unreadCount'] = 0;
          
          print('Updated global conversation: $conversationId');
        } else {
          print('Warning: Conversation $conversationId not found in global conversations');
        }
        
        await prefs.setString('global_conversations', json.encode(conversationsMap));
      } else {
        print('Warning: No global conversations found');
      }

      // Also save to staff-specific conversation storage for backup
      final String conversationKey = 'chat_messages_$conversationId';
      List<Map<String, dynamic>> messages = [];
      final String? messagesJson = prefs.getString(conversationKey);
      
      if (messagesJson != null) {
        final List<dynamic> messageList = json.decode(messagesJson);
        messages = messageList.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      
      messages.add(response);
      await prefs.setString(conversationKey, json.encode(messages));
      print('Saved message to conversation-specific storage: $conversationKey');

      // CRITICAL: Save response to user-specific storage for guest to receive
      String? guestUserId;
      // Extract guest user ID from conversation ID or conversation data
      if (conversationId.contains('_')) {
        guestUserId = conversationId.split('_').last;
      } else {
        // Fallback: get from conversation data
        guestUserId = _selectedConversation!['userId'] ?? _selectedConversation!['guestId'];
      }
      
      if (guestUserId != null) {
        final String userResponseKey = 'staff_responses_$guestUserId';
        List<Map<String, dynamic>> userResponses = [];
        final String? userResponsesJson = prefs.getString(userResponseKey);
        
        if (userResponsesJson != null) {
          final List<dynamic> responsesList = json.decode(userResponsesJson);
          userResponses = responsesList.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        
        // Add the staff response with guest-compatible format
        final guestCompatibleResponse = {
          'id': response['id'],
          'text': response['message'], // Guest expects 'text' field
          'message': response['message'], // Keep both for compatibility
          'sender': response['senderName'],
          'senderName': response['senderName'],
          'senderId': response['senderId'],
          'senderType': 'staff',
          'timestamp': response['timestamp'],
          'isRead': false,
          'recipientType': 'user',
        };
        
        userResponses.add(guestCompatibleResponse);
        await prefs.setString(userResponseKey, json.encode(userResponses));
        print('Saved staff response to user-specific storage: $userResponseKey');
        
        // Also update the guest's main chat messages
        final String guestMessagesKey = 'chat_messages';
        List<Map<String, dynamic>> guestMessages = [];
        final String? guestMessagesJson = prefs.getString(guestMessagesKey);
        
        if (guestMessagesJson != null) {
          final List<dynamic> messagesList = json.decode(guestMessagesJson);
          guestMessages = messagesList.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        
        // Only add if not already present
        if (!guestMessages.any((m) => m['id'] == guestCompatibleResponse['id'])) {
          guestMessages.add(guestCompatibleResponse);
          await prefs.setString(guestMessagesKey, json.encode(guestMessages));
          print('Added staff response to guest main chat messages');
        }
        
        // CRITICAL: Also save to the specific chat key that individual chat screen uses
        final String individualChatKey = 'chat_messages_staff'; // This is what IndividualChatScreen looks for
        List<Map<String, dynamic>> individualChatMessages = [];
        final String? individualChatJson = prefs.getString(individualChatKey);
        
        if (individualChatJson != null) {
          final List<dynamic> messagesList = json.decode(individualChatJson);
          individualChatMessages = messagesList.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        
        // Add the staff response if not already present
        if (!individualChatMessages.any((m) => m['id'] == guestCompatibleResponse['id'])) {
          individualChatMessages.add(guestCompatibleResponse);
          
          // Sort messages by timestamp to maintain proper order
          individualChatMessages.sort((a, b) {
            final aTime = DateTime.parse(a['timestamp']);
            final bTime = DateTime.parse(b['timestamp']);
            return aTime.compareTo(bTime);
          });
          
          await prefs.setString(individualChatKey, json.encode(individualChatMessages));
          print('Added staff response to individual chat messages: $individualChatKey');
        }
      } else {
        print('Warning: Could not determine guest user ID for response delivery');
      }

      setState(() {
        _responseController.clear();
      });

      // Reload conversations to update UI
      await _loadConversations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Response sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      print('Response sent successfully!');
    } catch (e) {
      print('Error sending response: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send response. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: isMobile
            ? Text(
                'Staff Panel',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Row(
                children: [
                  Icon(Icons.support_agent, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Staff Panel',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_conversations.length} active conversations',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          if (!isMobile)
            DropdownButton<String>(
              value: _currentStaffId,
              icon: Icon(Icons.person, color: Colors.blue[600]),
              underline: Container(),
              onChanged: (String? newValue) {
                setState(() {
                  _currentStaffId = newValue;
                });
              },
              items: _staffMembers.map<DropdownMenuItem<String>>((staff) {
                return DropdownMenuItem<String>(
                  value: staff['id'],
                  child: Text(
                    staff['name'],
                    style: TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
            ),
          if (isMobile)
            PopupMenuButton<String>(
              icon: Icon(Icons.person, color: Colors.blue[600]),
              onSelected: (String value) {
                setState(() {
                  _currentStaffId = value;
                });
              },
              itemBuilder: (BuildContext context) {
                return _staffMembers.map<PopupMenuItem<String>>((staff) {
                  return PopupMenuItem<String>(
                    value: staff['id'],
                    child: Text(staff['name']),
                  );
                }).toList();
              },
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : isMobile
              ? _buildMobileLayout()
              : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    if (_selectedConversation == null) {
      return _buildConversationsList(true);
    } else {
      return _buildChatInterface(true);
    }
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildConversationsList(false),
        ),
        Expanded(
          flex: 2,
          child: _buildChatInterface(false),
        ),
      ],
    );
  }

  Widget _buildConversationsList(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: isMobile ? null : Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                if (isMobile && _selectedConversation != null)
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.grey[600]),
                    onPressed: () {
                      setState(() {
                        _selectedConversation = null;
                      });
                    },
                  ),
                Icon(Icons.chat_bubble_outline, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conversations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                if (isMobile)
                  DropdownButton<String>(
                    value: _currentStaffId,
                    icon: Icon(Icons.person, color: Colors.blue[600], size: 20),
                    underline: Container(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _currentStaffId = newValue;
                      });
                    },
                    items: _staffMembers.map<DropdownMenuItem<String>>((staff) {
                      return DropdownMenuItem<String>(
                        value: staff['id'],
                        child: Text(
                          staff['name'],
                          style: TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _conversations.isEmpty
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
                          'No active conversations',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      final isSelected = _selectedConversation?['conversationId'] == conversation['conversationId'];
                      final hasUnread = (conversation['unreadCount'] ?? 0) > 0;
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[50] : Colors.white,
                          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                        ),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.blue[600],
                                ),
                              ),
                              if (hasUnread)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            conversation['conversationName'],
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          subtitle: Text(
                            conversation['lastMessage']?['message'] ?? 'No messages',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                conversation['lastMessage'] != null
                                    ? _formatTimestamp(conversation['lastMessage']['timestamp'])
                                    : '',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedConversation = conversation;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInterface(bool isMobile) {
    if (_selectedConversation == null && !isMobile) {
      return Center(
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
              'Select a conversation to start responding',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedConversation == null) {
      return Container();
    }

    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              if (isMobile)
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.grey[600]),
                  onPressed: () {
                    setState(() {
                      _selectedConversation = null;
                    });
                  },
                ),
              CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Icon(
                  Icons.person,
                  color: Colors.blue[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedConversation!['conversationName'],
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Customer Support Chat',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            itemCount: (_selectedConversation!['messages'] as List).length,
            itemBuilder: (context, index) {
              final message = (_selectedConversation!['messages'] as List)[index];
              final isUserMessage = message['senderType'] == 'user';
              final isStaffMessage = message['senderType'] == 'staff';
              
              return Container(
                margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                child: Row(
                  mainAxisAlignment: isStaffMessage 
                      ? MainAxisAlignment.end 
                      : MainAxisAlignment.start,
                  children: [
                    if (isUserMessage) ...[
                      CircleAvatar(
                        radius: isMobile ? 12 : 16,
                        backgroundColor: Colors.blue[100],
                        child: Icon(
                          Icons.person,
                          size: isMobile ? 12 : 16,
                          color: Colors.blue[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * (isMobile ? 0.75 : 0.4),
                        ),
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          color: isStaffMessage 
                              ? Colors.blue[600]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isStaffMessage)
                              Text(
                                message['senderName'] ?? message['sender'] ?? 'Staff',
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                            if (isUserMessage)
                              Text(
                                'Guest',
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[600],
                                ),
                              ),
                            if (isStaffMessage || isUserMessage) const SizedBox(height: 4),
                            Text(
                              message['message'] ?? message['text'] ?? '',
                              style: TextStyle(
                                color: isStaffMessage ? Colors.white : Colors.black87,
                                fontSize: isMobile ? 12 : 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(message['timestamp']),
                              style: TextStyle(
                                fontSize: isMobile ? 9 : 11,
                                color: isStaffMessage ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isStaffMessage) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: isMobile ? 12 : 16,
                        backgroundColor: Colors.blue[100],
                        child: Icon(
                          Icons.support_agent,
                          size: isMobile ? 12 : 16,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),

        // Response Input
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _responseController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Type your response...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.blue[600]!),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 20,
                      vertical: isMobile ? 10 : 12,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.blue[600],
                onPressed: _sendResponse,
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: isMobile ? 16 : 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
