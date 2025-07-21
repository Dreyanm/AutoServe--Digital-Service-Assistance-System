import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AvailableStaffScreen extends StatefulWidget {
  const AvailableStaffScreen({Key? key}) : super(key: key);

  @override
  State<AvailableStaffScreen> createState() => _AvailableStaffScreenState();
}

class _AvailableStaffScreenState extends State<AvailableStaffScreen> {
  List<Map<String, dynamic>> _availableStaff = [];
  List<Map<String, dynamic>> _filteredStaff = [];
  String _selectedDepartment = 'All';
  String _searchQuery = '';
  bool _isLoading = true;

  final List<String> _departments = [
    'All',
    'Front Desk',
    'Housekeeping',
    'Restaurant',
    'Maintenance',
    'Security',
    'Management',
    'Activities',
    'Spa & Wellness'
  ];

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? staffDataJson = prefs.getString('available_staff');
      
      if (staffDataJson != null) {
        final List<dynamic> staffList = json.decode(staffDataJson);
        _availableStaff = staffList.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        // Initialize with sample data if no data exists
        _availableStaff = _generateSampleStaff();
        await _saveStaffData();
      }
      
      _filterStaff();
    } catch (e) {
      print('Error loading staff data: $e');
      _availableStaff = _generateSampleStaff();
      await _saveStaffData();
      _filterStaff();
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveStaffData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('available_staff', json.encode(_availableStaff));
    } catch (e) {
      print('Error saving staff data: $e');
    }
  }

  List<Map<String, dynamic>> _generateSampleStaff() {
    return [
      {
        'id': 'STAFF001',
        'name': 'Maria Santos',
        'department': 'Front Desk',
        'position': 'Front Desk Manager',
        'status': 'Available',
        'shift': 'Morning (6AM - 2PM)',
        'contact': '+63 917 123 4567',
        'email': 'maria.santos@resort.com',
        'experience': '5 years',
        'rating': 4.8,
        'lastActive': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      },
      {
        'id': 'STAFF002',
        'name': 'Juan Dela Cruz',
        'department': 'Housekeeping',
        'position': 'Housekeeping Supervisor',
        'status': 'Busy',
        'shift': 'Morning (6AM - 2PM)',
        'contact': '+63 917 234 5678',
        'email': 'juan.delacruz@resort.com',
        'experience': '3 years',
        'rating': 4.6,
        'lastActive': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      },
      {
        'id': 'STAFF003',
        'name': 'Ana Rodriguez',
        'department': 'Restaurant',
        'position': 'Restaurant Manager',
        'status': 'Available',
        'shift': 'Afternoon (2PM - 10PM)',
        'contact': '+63 917 345 6789',
        'email': 'ana.rodriguez@resort.com',
        'experience': '7 years',
        'rating': 4.9,
        'lastActive': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
      },
      {
        'id': 'STAFF004',
        'name': 'Carlos Mendoza',
        'department': 'Maintenance',
        'position': 'Maintenance Technician',
        'status': 'Available',
        'shift': 'Morning (6AM - 2PM)',
        'contact': '+63 917 456 7890',
        'email': 'carlos.mendoza@resort.com',
        'experience': '4 years',
        'rating': 4.7,
        'lastActive': DateTime.now().subtract(const Duration(minutes: 8)).toIso8601String(),
      },
      {
        'id': 'STAFF005',
        'name': 'Isabel Garcia',
        'department': 'Security',
        'position': 'Security Officer',
        'status': 'On Duty',
        'shift': 'Night (10PM - 6AM)',
        'contact': '+63 917 567 8901',
        'email': 'isabel.garcia@resort.com',
        'experience': '2 years',
        'rating': 4.5,
        'lastActive': DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      },
      {
        'id': 'STAFF006',
        'name': 'Miguel Torres',
        'department': 'Activities',
        'position': 'Activities Coordinator',
        'status': 'Available',
        'shift': 'Afternoon (2PM - 10PM)',
        'contact': '+63 917 678 9012',
        'email': 'miguel.torres@resort.com',
        'experience': '6 years',
        'rating': 4.8,
        'lastActive': DateTime.now().subtract(const Duration(minutes: 3)).toIso8601String(),
      },
    ];
  }

  void _filterStaff() {
    _filteredStaff = _availableStaff.where((staff) {
      final matchesDepartment = _selectedDepartment == 'All' || staff['department'] == _selectedDepartment;
      final matchesSearch = _searchQuery.isEmpty || 
          staff['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          staff['position'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          staff['id'].toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDepartment && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Available Staff'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadStaffData,
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
                Expanded(child: _buildStaffList()),
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
                _filterStaff();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search staff by name, position, or ID...',
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
          // Department Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _departments.map((department) {
                final isSelected = _selectedDepartment == department;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(department),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedDepartment = department;
                        _filterStaff();
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
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final availableCount = _availableStaff.where((staff) => staff['status'] == 'Available').length;
    final busyCount = _availableStaff.where((staff) => staff['status'] == 'Busy').length;
    final onDutyCount = _availableStaff.where((staff) => staff['status'] == 'On Duty').length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Available', availableCount, Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Busy', busyCount, Colors.orange)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('On Duty', onDutyCount, Colors.blue)),
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

  Widget _buildStaffList() {
    if (_filteredStaff.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No staff found',
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
      itemCount: _filteredStaff.length,
      itemBuilder: (context, index) {
        final staff = _filteredStaff[index];
        return _buildStaffCard(staff);
      },
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final status = staff['status'];
    Color statusColor;
    Color statusBackgroundColor;

    switch (status) {
      case 'Available':
        statusColor = Colors.green[700]!;
        statusBackgroundColor = Colors.green[50]!;
        break;
      case 'Busy':
        statusColor = Colors.orange[700]!;
        statusBackgroundColor = Colors.orange[50]!;
        break;
      case 'On Duty':
        statusColor = Colors.blue[700]!;
        statusBackgroundColor = Colors.blue[50]!;
        break;
      default:
        statusColor = Colors.grey[700]!;
        statusBackgroundColor = Colors.grey[50]!;
    }

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
                    staff['name'].split(' ').map((n) => n[0]).join().toUpperCase(),
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
                        staff['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${staff['position']} • ${staff['department']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'ID: ${staff['id']}',
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
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  staff['shift'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.star, size: 16, color: Colors.amber[600]),
                const SizedBox(width: 4),
                Text(
                  staff['rating'].toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.work, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  staff['experience'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactStaff(staff),
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
                    onPressed: () => _viewStaffDetails(staff),
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

  void _contactStaff(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contact ${staff['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phone: ${staff['contact']}'),
              const SizedBox(height: 8),
              Text('Email: ${staff['email']}'),
              const SizedBox(height: 8),
              Text('Status: ${staff['status']}'),
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
                  SnackBar(content: Text('Calling ${staff['name']}...')),
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

  void _viewStaffDetails(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${staff['name']} Details'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Staff ID', staff['id']),
                _buildDetailRow('Department', staff['department']),
                _buildDetailRow('Position', staff['position']),
                _buildDetailRow('Status', staff['status']),
                _buildDetailRow('Shift', staff['shift']),
                _buildDetailRow('Experience', staff['experience']),
                _buildDetailRow('Rating', '${staff['rating']}/5.0'),
                _buildDetailRow('Contact', staff['contact']),
                _buildDetailRow('Email', staff['email']),
                _buildDetailRow('Last Active', _formatLastActive(staff['lastActive'])),
              ],
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
            width: 80,
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

  String _formatLastActive(String lastActiveString) {
    try {
      final DateTime lastActive = DateTime.parse(lastActiveString);
      final Duration difference = DateTime.now().difference(lastActive);
      
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
}
