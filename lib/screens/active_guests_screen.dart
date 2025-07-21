import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ActiveGuestsScreen extends StatefulWidget {
  const ActiveGuestsScreen({Key? key}) : super(key: key);

  @override
  State<ActiveGuestsScreen> createState() => _ActiveGuestsScreenState();
}

class _ActiveGuestsScreenState extends State<ActiveGuestsScreen> {
  List<Map<String, dynamic>> _activeGuests = [];
  List<Map<String, dynamic>> _filteredGuests = [];
  String _selectedStatus = 'All';
  String _selectedRoomType = 'All';
  String _searchQuery = '';
  bool _isLoading = true;

  final List<String> _guestStatuses = ['All', 'Checked In', 'In Resort', 'Checked Out'];
  final List<String> _roomTypes = ['All', 'Standard Room', 'Deluxe Room', 'Suite', 'Presidential Suite', 'Family Room'];

  @override
  void initState() {
    super.initState();
    _loadGuestsData();
  }

  Future<void> _loadGuestsData() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? guestsDataJson = prefs.getString('active_guests');
      
      if (guestsDataJson != null) {
        final List<dynamic> guestsList = json.decode(guestsDataJson);
        _activeGuests = guestsList.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        // Initialize with sample data if no data exists
        _activeGuests = _generateSampleGuests();
        await _saveGuestsData();
      }
      
      _filterGuests();
    } catch (e) {
      print('Error loading guests data: $e');
      _activeGuests = _generateSampleGuests();
      await _saveGuestsData();
      _filterGuests();
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveGuestsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_guests', json.encode(_activeGuests));
    } catch (e) {
      print('Error saving guests data: $e');
    }
  }

  List<Map<String, dynamic>> _generateSampleGuests() {
    return [
      {
        'id': 'GUEST001',
        'name': 'John Smith',
        'email': 'john.smith@email.com',
        'phone': '+1 555 123 4567',
        'roomNumber': '101',
        'roomType': 'Deluxe Room',
        'status': 'Checked In',
        'checkInDate': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'checkOutDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'guests': 2,
        'nationality': 'American',
        'specialRequests': 'Ocean view, Late checkout',
        'totalBill': 15000.0,
        'paidAmount': 7500.0,
        'lastActivity': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      },
      {
        'id': 'GUEST002',
        'name': 'Maria Garcia',
        'email': 'maria.garcia@email.com',
        'phone': '+34 666 789 012',
        'roomNumber': '205',
        'roomType': 'Suite',
        'status': 'In Resort',
        'checkInDate': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'checkOutDate': DateTime.now().add(const Duration(days: 4)).toIso8601String(),
        'guests': 3,
        'nationality': 'Spanish',
        'specialRequests': 'Extra bed, Vegetarian meals',
        'totalBill': 25000.0,
        'paidAmount': 25000.0,
        'lastActivity': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      },
      {
        'id': 'GUEST003',
        'name': 'Tanaka Hiroshi',
        'email': 'tanaka.hiroshi@email.com',
        'phone': '+81 90 1234 5678',
        'roomNumber': '301',
        'roomType': 'Presidential Suite',
        'status': 'Checked In',
        'checkInDate': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        'checkOutDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'guests': 2,
        'nationality': 'Japanese',
        'specialRequests': 'Airport transfer, Spa appointments',
        'totalBill': 50000.0,
        'paidAmount': 30000.0,
        'lastActivity': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
      },
      {
        'id': 'GUEST004',
        'name': 'Sarah Johnson',
        'email': 'sarah.johnson@email.com',
        'phone': '+44 7700 900 123',
        'roomNumber': '150',
        'roomType': 'Family Room',
        'status': 'In Resort',
        'checkInDate': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'checkOutDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'guests': 4,
        'nationality': 'British',
        'specialRequests': 'Baby cot, High chair',
        'totalBill': 20000.0,
        'paidAmount': 15000.0,
        'lastActivity': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
      },
      {
        'id': 'GUEST005',
        'name': 'Pierre Dubois',
        'email': 'pierre.dubois@email.com',
        'phone': '+33 6 12 34 56 78',
        'roomNumber': '75',
        'roomType': 'Standard Room',
        'status': 'Checked Out',
        'checkInDate': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'checkOutDate': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'guests': 1,
        'nationality': 'French',
        'specialRequests': 'None',
        'totalBill': 8000.0,
        'paidAmount': 8000.0,
        'lastActivity': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 'GUEST006',
        'name': 'Chen Wei',
        'email': 'chen.wei@email.com',
        'phone': '+86 138 0013 8000',
        'roomNumber': '180',
        'roomType': 'Deluxe Room',
        'status': 'Checked In',
        'checkInDate': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
        'checkOutDate': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        'guests': 2,
        'nationality': 'Chinese',
        'specialRequests': 'Chinese newspaper, Early breakfast',
        'totalBill': 18000.0,
        'paidAmount': 9000.0,
        'lastActivity': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
      },
    ];
  }

  void _filterGuests() {
    _filteredGuests = _activeGuests.where((guest) {
      final matchesStatus = _selectedStatus == 'All' || guest['status'] == _selectedStatus;
      final matchesRoomType = _selectedRoomType == 'All' || guest['roomType'] == _selectedRoomType;
      final matchesSearch = _searchQuery.isEmpty || 
          guest['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          guest['roomNumber'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          guest['id'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          guest['email'].toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesRoomType && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Active Guests'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadGuestsData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterSection(),
                _buildStatsSection(),
                Expanded(child: _buildGuestsList()),
              ],
            ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _filterGuests();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search guests by name, room, ID, or email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          // Status Filter
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _guestStatuses.map((status) {
                      final isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = status;
                              _filterGuests();
                            });
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Colors.red[100],
                          checkmarkColor: Colors.red[600],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Room Type Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _roomTypes.map((roomType) {
                final isSelected = _selectedRoomType == roomType;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(roomType),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRoomType = roomType;
                        _filterGuests();
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue[600],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final checkedInCount = _activeGuests.where((guest) => guest['status'] == 'Checked In').length;
    final inResortCount = _activeGuests.where((guest) => guest['status'] == 'In Resort').length;
    final checkedOutCount = _activeGuests.where((guest) => guest['status'] == 'Checked Out').length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Checked In', checkedInCount, Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('In Resort', inResortCount, Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Checked Out', checkedOutCount, Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color[700],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestsList() {
    if (_filteredGuests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No guests found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter criteria',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredGuests.length,
      itemBuilder: (context, index) {
        final guest = _filteredGuests[index];
        return _buildGuestCard(guest);
      },
    );
  }

  Widget _buildGuestCard(Map<String, dynamic> guest) {
    final status = guest['status'];
    Color statusColor;
    Color statusBackgroundColor;

    switch (status) {
      case 'Checked In':
        statusColor = Colors.green[700]!;
        statusBackgroundColor = Colors.green[50]!;
        break;
      case 'In Resort':
        statusColor = Colors.blue[700]!;
        statusBackgroundColor = Colors.blue[50]!;
        break;
      case 'Checked Out':
        statusColor = Colors.orange[700]!;
        statusBackgroundColor = Colors.orange[50]!;
        break;
      default:
        statusColor = Colors.grey[700]!;
        statusBackgroundColor = Colors.grey[50]!;
    }

    final double paidPercentage = (guest['paidAmount'] / guest['totalBill']).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.red[100],
                  child: Text(
                    guest['name'].split(' ').map((n) => n[0]).join().toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guest['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Room ${guest['roomNumber']} • ${guest['roomType']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'ID: ${guest['id']} • ${guest['nationality']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${guest['guests']} guest${guest['guests'] > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(guest['checkInDate'])} - ${_formatDate(guest['checkOutDate'])}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '₱${guest['paidAmount'].toStringAsFixed(0)} / ₱${guest['totalBill'].toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: paidPercentage,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      paidPercentage >= 1.0 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(paidPercentage * 100).toInt()}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (guest['specialRequests'] != 'None') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        guest['specialRequests'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactGuest(guest),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Contact'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      side: BorderSide(color: Colors.red[600]!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewGuestDetails(guest),
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatLastActivity(String lastActivityString) {
    try {
      final DateTime lastActivity = DateTime.parse(lastActivityString);
      final Duration difference = DateTime.now().difference(lastActivity);
      
      if (difference.inMinutes < 1) {
        return 'Active now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void _contactGuest(Map<String, dynamic> guest) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contact ${guest['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phone: ${guest['phone']}'),
              const SizedBox(height: 8),
              Text('Email: ${guest['email']}'),
              const SizedBox(height: 8),
              Text('Room: ${guest['roomNumber']}'),
              const SizedBox(height: 8),
              Text('Status: ${guest['status']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling ${guest['name']}...')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
              child: const Text('Call Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _viewGuestDetails(Map<String, dynamic> guest) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${guest['name']} Details'),
          content: SizedBox(
            width: 350,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Guest ID', guest['id']),
                  _buildDetailRow('Name', guest['name']),
                  _buildDetailRow('Email', guest['email']),
                  _buildDetailRow('Phone', guest['phone']),
                  _buildDetailRow('Nationality', guest['nationality']),
                  _buildDetailRow('Room Number', guest['roomNumber']),
                  _buildDetailRow('Room Type', guest['roomType']),
                  _buildDetailRow('Status', guest['status']),
                  _buildDetailRow('Number of Guests', guest['guests'].toString()),
                  _buildDetailRow('Check-in Date', _formatDate(guest['checkInDate'])),
                  _buildDetailRow('Check-out Date', _formatDate(guest['checkOutDate'])),
                  _buildDetailRow('Total Bill', '₱${guest['totalBill'].toStringAsFixed(2)}'),
                  _buildDetailRow('Paid Amount', '₱${guest['paidAmount'].toStringAsFixed(2)}'),
                  _buildDetailRow('Outstanding', '₱${(guest['totalBill'] - guest['paidAmount']).toStringAsFixed(2)}'),
                  _buildDetailRow('Special Requests', guest['specialRequests']),
                  _buildDetailRow('Last Activity', _formatLastActivity(guest['lastActivity'])),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
