import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TicketsManagementScreen extends StatefulWidget {
  const TicketsManagementScreen({Key? key}) : super(key: key);

  @override
  State<TicketsManagementScreen> createState() => _TicketsManagementScreenState();
}

class _TicketsManagementScreenState extends State<TicketsManagementScreen> {
  List<Map<String, dynamic>> _allTickets = [];
  List<Map<String, dynamic>> _filteredTickets = [];
  String _selectedFilter = 'All';
  String _searchQuery = '';
  String _selectedPriority = 'All';
  String _selectedSort = 'Newest First';
  bool _isLoading = true;
  String? _staffName;

  @override
  void initState() {
    super.initState();
    _loadStaffData();
    _loadTickets();
  }

  Future<void> _loadStaffData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _staffName = prefs.getString('user_name') ?? 'Admin';
    });
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final ticketStrings = prefs.getStringList('support_tickets') ?? [];
      
      final tickets = ticketStrings.map((str) {
        final ticket = json.decode(str) as Map<String, dynamic>;
        // Ensure consistent field names
        ticket['ticketType'] = 'Support Ticket';
        ticket['serviceType'] = ticket['subject'] ?? 'Support Request';
        ticket['guestName'] = ticket['email'] ?? 'Guest';
        ticket['details'] = ticket['issue'] ?? 'No details provided';
        ticket['dateSubmitted'] = ticket['submissionDate'] ?? DateTime.now().toString().split(' ')[0];
        
        // Set priority if not set
        if (ticket['priority'] == null) {
          ticket['priority'] = _determinePriority(ticket);
        }
        
        return ticket;
      }).toList();

      setState(() {
        _allTickets = tickets;
        _filteredTickets = tickets;
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading tickets: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _determinePriority(Map<String, dynamic> ticket) {
    final subject = ticket['subject'] ?? '';
    final issue = ticket['issue'] ?? '';
    
    if (subject.toLowerCase().contains('urgent') || 
        subject.toLowerCase().contains('emergency') ||
        issue.toLowerCase().contains('urgent') ||
        issue.toLowerCase().contains('emergency')) {
      return 'High';
    }
    
    return 'Medium';
  }

  void _applyFilters() {
    setState(() {
      _filteredTickets = _allTickets.where((ticket) {
        // Filter by status
        bool statusMatch = _selectedFilter == 'All' || 
                          ticket['status'] == _selectedFilter;
        
        // Filter by priority
        bool priorityMatch = _selectedPriority == 'All' || 
                            ticket['priority'] == _selectedPriority;
        
        // Filter by search query
        bool searchMatch = _searchQuery.isEmpty ||
                          ticket['subject'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          ticket['issue'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          ticket['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
        
        return statusMatch && priorityMatch && searchMatch;
      }).toList();
      
      // Apply sorting
      _filteredTickets.sort((a, b) {
        switch (_selectedSort) {
          case 'Newest First':
            return _parseDate(b['dateSubmitted']).compareTo(_parseDate(a['dateSubmitted']));
          case 'Oldest First':
            return _parseDate(a['dateSubmitted']).compareTo(_parseDate(b['dateSubmitted']));
          case 'High Priority':
            return _priorityValue(b['priority']).compareTo(_priorityValue(a['priority']));
          case 'Low Priority':
            return _priorityValue(a['priority']).compareTo(_priorityValue(b['priority']));
          default:
            return 0;
        }
      });
    });
  }

  DateTime _parseDate(dynamic dateValue) {
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  int _priorityValue(String? priority) {
    switch (priority) {
      case 'High': return 3;
      case 'Medium': return 2;
      case 'Low': return 1;
      default: return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.red[600],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tickets Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadTickets,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeaderStats(),
                _buildFiltersAndSearch(),
                Expanded(
                  child: _filteredTickets.isEmpty
                      ? _buildEmptyState()
                      : _buildTicketsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderStats() {
    final totalTickets = _allTickets.length;
    final pendingTickets = _allTickets.where((t) => t['status'] != 'Completed').length;
    final completedTickets = _allTickets.where((t) => t['status'] == 'Completed').length;
    final highPriorityTickets = _allTickets.where((t) => t['priority'] == 'High').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
                  Icons.confirmation_number,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Support Tickets Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage and track all guest support requests',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Tickets',
                  totalTickets.toString(),
                  Icons.inbox,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  pendingTickets.toString(),
                  Icons.pending_actions,
                  Colors.orange[100]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  completedTickets.toString(),
                  Icons.check_circle,
                  Colors.green[100]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'High Priority',
                  highPriorityTickets.toString(),
                  Icons.priority_high,
                  Colors.red[100]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersAndSearch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Search tickets by subject, issue, or email...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red[400]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          
          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterDropdown(
                  'Status',
                  _selectedFilter,
                  ['All', 'Pending', 'In Progress', 'Completed'],
                  (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown(
                  'Priority',
                  _selectedPriority,
                  ['All', 'High', 'Medium', 'Low'],
                  (value) {
                    setState(() {
                      _selectedPriority = value!;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown(
                  'Sort By',
                  _selectedSort,
                  ['Newest First', 'Oldest First', 'High Priority', 'Low Priority'],
                  (value) {
                    setState(() {
                      _selectedSort = value!;
                    });
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),
          
          // Results Counter
          if (_filteredTickets.length != _allTickets.length) ...[
            const SizedBox(height: 12),
            Text(
              'Showing ${_filteredTickets.length} of ${_allTickets.length} tickets',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No tickets match your search' : 'No support tickets found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Try adjusting your search criteria or filters'
                : 'Guest support tickets will appear here when submitted',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'All';
                  _selectedPriority = 'All';
                });
                _applyFilters();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTicketsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTickets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildTicketCard(_filteredTickets[index]);
      },
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final ticketId = ticket['id'] ?? 'Unknown ID';
    final subject = ticket['subject'] ?? 'No Subject';
    final issue = ticket['issue'] ?? 'No details provided';
    final email = ticket['email'] ?? 'No email';
    final contactNumber = ticket['contactNumber'] ?? 'Not provided';
    final status = ticket['status'] ?? 'Pending';
    final priority = ticket['priority'] ?? 'Medium';
    final submissionDate = ticket['submissionDate'] ?? ticket['dateSubmitted'] ?? 'Unknown date';
    
    final isPending = status != 'Completed';
    
    // Status color
    Color statusColor;
    switch (status) {
      case 'Completed':
        statusColor = Colors.green;
        break;
      case 'In Progress':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }
    
    // Priority color
    Color priorityColor;
    switch (priority) {
      case 'High':
        priorityColor = Colors.red;
        break;
      case 'Medium':
        priorityColor = Colors.orange;
        break;
      case 'Low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priorityColor.withOpacity(0.3),
          width: priority == 'High' ? 2 : 1,
        ),
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
          // Header Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: priorityColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Issue Description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Issue Description:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  issue,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Details Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket ID',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '#${ticketId.substring(ticketId.length > 8 ? ticketId.length - 8 : 0)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submitted',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _formatDate(submissionDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              if (contactNumber != 'Not provided')
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        contactNumber,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          if (isPending) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateTicketStatus(ticket, 'In Progress'),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Start Progress'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateTicketStatus(ticket, 'Completed'),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Mark Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showNotificationDialog(ticket),
                icon: const Icon(Icons.notifications, size: 18),
                label: const Text('Notify Guest'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[600],
                  side: BorderSide(color: Colors.red[600]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Completed ticket actions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Ticket Completed',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showNotificationDialog(ticket),
                    child: Text(
                      'Send Update',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _updateTicketStatus(Map<String, dynamic> ticket, String newStatus) async {
    try {
      final ticketId = ticket['id'];
      
      // Update ticket status in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final ticketStrings = prefs.getStringList('support_tickets') ?? [];
      
      final updatedTickets = ticketStrings.map((str) {
        final t = json.decode(str) as Map<String, dynamic>;
        if (t['id'] == ticketId) {
          t['status'] = newStatus;
          if (newStatus == 'Completed') {
            t['dateCompleted'] = DateTime.now().toString().split(' ')[0];
            t['resolvedBy'] = _staffName ?? 'Admin';
          }
        }
        return json.encode(t);
      }).toList();
      
      await prefs.setStringList('support_tickets', updatedTickets);
      
      // Send notification to guest
      await _sendGuestNotification(ticket, newStatus);
      
      // Reload tickets
      await _loadTickets();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'Completed' 
                ? 'Ticket marked as completed and guest notified!'
                : 'Ticket status updated to $newStatus',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating ticket: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendGuestNotification(Map<String, dynamic> ticket, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('guest_notifications') ?? [];
      
      String message;
      switch (status) {
        case 'In Progress':
          message = 'Your support ticket is now being processed by our team.';
          break;
        case 'Completed':
          message = 'Your support ticket has been completed successfully!';
          break;
        default:
          message = 'Your support ticket status has been updated.';
      }
      
      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': 'Support Ticket Update - $status',
        'message': '${ticket['subject']}: $message',
        'ticketId': ticket['id'],
        'ticketType': 'Support Ticket',
        'status': status,
        'timestamp': DateTime.now().toString(),
        'isRead': false,
        'staffName': _staffName ?? 'Admin',
      };
      
      notifications.add(json.encode(notification));
      await prefs.setStringList('guest_notifications', notifications);
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  void _showNotificationDialog(Map<String, dynamic> ticket) {
    final subject = ticket['subject'] ?? 'Support Request';
    final email = ticket['email'] ?? 'Guest';
    final ticketId = ticket['id'] ?? 'Unknown ID';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text('Notify Guest'),
            ],
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Send status notification to $email about their support ticket:',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket: $subject',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('ID: #${ticketId.substring(ticketId.length > 8 ? ticketId.length - 8 : 0)}'),
                    const Text('Type: Support Ticket'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select notification type:'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendCustomNotification(ticket, 'In Progress', 'Your ticket is being processed by our staff.');
              },
              child: const Text('In Progress'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendCustomNotification(ticket, 'Under Review', 'Your ticket is under review and will be processed soon.');
              },
              child: const Text('Under Review'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateTicketStatus(ticket, 'Completed');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendCustomNotification(Map<String, dynamic> ticket, String status, String message) async {
    await _sendGuestNotification(ticket, status);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification sent: $status - ${ticket['subject']}'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
