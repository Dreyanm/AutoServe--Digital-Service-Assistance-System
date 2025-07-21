import 'package:flutter/material.dart';

class AvailableActivitiesScreen extends StatefulWidget {
  const AvailableActivitiesScreen({Key? key}) : super(key: key);

  @override
  State<AvailableActivitiesScreen> createState() => _AvailableActivitiesScreenState();
}

class _AvailableActivitiesScreenState extends State<AvailableActivitiesScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _sortBy = 'Name';

  // Available activities data (same as from ActivitiesScreen)
  final List<Map<String, dynamic>> _activities = [
    {
      'name': 'Island Hopping',
      'icon': Icons.directions_boat,
      'image': 'IslandHopping.jpg',
      'description': 'Explore beautiful nearby islands with crystal clear waters and pristine beaches',
      'schedule': '8:00 AM - 4:00 PM',
      'duration': '8 hours',
      'capacity': 20,
      'price': 'P1,200 per person',
      'status': 'Available',
      'date': 'Daily',
      'requirements': 'Swimming ability required',
      'currentBookings': 8,
    },
    {
      'name': 'Snorkeling Adventure',
      'icon': Icons.scuba_diving,
      'image': 'Snorkeling.jpg',
      'description': 'Discover underwater marine life and colorful coral reefs',
      'schedule': '9:00 AM - 12:00 PM',
      'duration': '3 hours',
      'capacity': 15,
      'price': 'P800 per person',
      'status': 'Available',
      'date': 'Daily',
      'requirements': 'Basic swimming skills',
      'currentBookings': 12,
    },
    {
      'name': 'Banana Boating',
      'icon': Icons.sports_motorsports,
      'image': 'BananaBoat.jpg',
      'description': 'Thrilling banana boat ride through crystal clear waters with friends and family',
      'schedule': '10:00 AM - 4:00 PM',
      'duration': '30 minutes',
      'capacity': 8,
      'price': 'P500 per person',
      'status': 'Available',
      'date': 'Daily',
      'requirements': 'Basic swimming skills',
      'currentBookings': 3,
    },
    {
      'name': 'Beach Volleyball',
      'icon': Icons.sports_volleyball,
      'image': 'BeachVolleyball.jpg',
      'description': 'Fun beach volleyball tournament with prizes for winners',
      'schedule': '3:00 PM - 5:00 PM',
      'duration': '2 hours',
      'capacity': 12,
      'price': 'Free',
      'status': 'Available',
      'date': 'Weekends',
      'requirements': 'Basic fitness level',
      'currentBookings': 6,
    },
    {
      'name': 'Kayaking',
      'icon': Icons.kayaking,
      'image': 'Kayaking.jpg',
      'description': 'Paddle through calm waters and explore hidden coves',
      'schedule': '10:00 AM - 12:00 PM',
      'duration': '2 hours',
      'capacity': 10,
      'price': 'P500 per person',
      'status': 'Available',
      'date': 'Daily',
      'requirements': 'Basic swimming skills',
      'currentBookings': 7,
    },
    {
      'name': 'Fishing Trip',
      'icon': Icons.phishing,
      'image': 'FishingTrip.jpg',
      'description': 'Traditional fishing experience with local guides',
      'schedule': '6:00 AM - 10:00 AM',
      'duration': '4 hours',
      'capacity': 8,
      'price': 'P900 per person',
      'status': 'Fully Booked',
      'date': 'Daily',
      'requirements': 'Early morning availability',
      'currentBookings': 8,
    },
  ];

  List<Map<String, dynamic>> get _filteredActivities {
    var filtered = _activities.where((activity) {
      final matchesSearch = activity['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           activity['description'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == 'All' || activity['status'] == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    // Sort activities
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Name':
          return a['name'].compareTo(b['name']);
        case 'Price':
          final priceA = _extractPrice(a['price']);
          final priceB = _extractPrice(b['price']);
          return priceA.compareTo(priceB);
        case 'Capacity':
          return (b['capacity'] as int).compareTo(a['capacity'] as int);
        case 'Available Slots':
          final slotsA = (a['capacity'] as int) - (a['currentBookings'] as int);
          final slotsB = (b['capacity'] as int) - (b['currentBookings'] as int);
          return slotsB.compareTo(slotsA);
        default:
          return a['name'].compareTo(b['name']);
      }
    });

    return filtered;
  }

  double _extractPrice(String priceString) {
    if (priceString.toLowerCase() == 'free') return 0.0;
    final regex = RegExp(r'P([\d,]+)');
    final match = regex.firstMatch(priceString);
    if (match != null) {
      return double.parse(match.group(1)!.replaceAll(',', ''));
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final filteredActivities = _filteredActivities;
    final availableCount = _activities.where((a) => a['status'] == 'Available').length;
    final fullyBookedCount = _activities.where((a) => a['status'] == 'Fully Booked').length;
    final totalCapacity = _activities.fold<int>(0, (sum, a) => sum + (a['capacity'] as int));
    final totalBookings = _activities.fold<int>(0, (sum, a) => sum + (a['currentBookings'] as int));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.orange[600],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Available Activities',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(),
            icon: const Icon(Icons.filter_list, color: Colors.white),
            tooltip: 'Filter Activities',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Overview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange[400]!, Colors.orange[600]!],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Activities',
                        _activities.length.toString(),
                        Icons.local_activity,
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Available',
                        availableCount.toString(),
                        Icons.check_circle,
                        Colors.green[100]!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Fully Booked',
                        fullyBookedCount.toString(),
                        Icons.event_busy,
                        Colors.red[100]!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Occupancy Rate',
                        '${((totalBookings / totalCapacity) * 100).toInt()}%',
                        Icons.trending_up,
                        Colors.blue[100]!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search activities...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Results Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${filteredActivities.length} activities',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  onChanged: (value) => setState(() => _sortBy = value!),
                  items: ['Name', 'Price', 'Capacity', 'Available Slots']
                      .map((sort) => DropdownMenuItem(
                            value: sort,
                            child: Text('Sort by $sort'),
                          ))
                      .toList(),
                  underline: Container(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Activities List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredActivities.length,
              itemBuilder: (context, index) {
                final activity = filteredActivities[index];
                return _buildActivityCard(activity);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: backgroundColor == Colors.white ? Colors.orange[600] : Colors.grey[700],
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: backgroundColor == Colors.white ? Colors.orange[600] : Colors.grey[800],
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: backgroundColor == Colors.white ? Colors.orange[600] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final availableSlots = (activity['capacity'] as int) - (activity['currentBookings'] as int);
    final isFullyBooked = activity['status'] == 'Fully Booked';
    final occupancyRate = ((activity['currentBookings'] as int) / (activity['capacity'] as int) * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header with activity icon and status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isFullyBooked ? Colors.red[50] : Colors.green[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    activity['icon'],
                    color: Colors.orange[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isFullyBooked ? Colors.red[600] : Colors.green[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activity['status'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Activity Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Schedule and Duration
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        Icons.access_time,
                        'Schedule',
                        activity['schedule'],
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailRow(
                        Icons.timer,
                        'Duration',
                        activity['duration'],
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Capacity and Price
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        Icons.group,
                        'Capacity',
                        '${activity['currentBookings']}/${activity['capacity']} ($occupancyRate%)',
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailRow(
                        Icons.attach_money,
                        'Price',
                        activity['price'],
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Availability and Date
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        Icons.event_available,
                        'Available',
                        activity['date'],
                        Colors.indigo,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailRow(
                        Icons.event_seat,
                        'Slots Left',
                        availableSlots.toString(),
                        availableSlots <= 2 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),

                if (activity['requirements'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[600], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Requirements: ${activity['requirements']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showActivityDetails(activity),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
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
                    onPressed: isFullyBooked ? null : () => _showBookingManagement(activity),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Manage'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFullyBooked ? Colors.grey[400] : Colors.orange[600],
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
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
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
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Activities'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _statusFilter,
              isExpanded: true,
              onChanged: (value) => setState(() => _statusFilter = value!),
              items: ['All', 'Available', 'Fully Booked']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('Sort By:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _sortBy,
              isExpanded: true,
              onChanged: (value) => setState(() => _sortBy = value!),
              items: ['Name', 'Price', 'Capacity', 'Available Slots']
                  .map((sort) => DropdownMenuItem(
                        value: sort,
                        child: Text(sort),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showActivityDetails(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(activity['icon'], color: Colors.orange[600]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      activity['name'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                activity['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Schedule', activity['schedule']),
              _buildInfoRow('Duration', activity['duration']),
              _buildInfoRow('Capacity', '${activity['capacity']} people'),
              _buildInfoRow('Current Bookings', '${activity['currentBookings']} people'),
              _buildInfoRow('Available Slots', '${(activity['capacity'] as int) - (activity['currentBookings'] as int)} slots'),
              _buildInfoRow('Price', activity['price']),
              _buildInfoRow('Available', activity['date']),
              _buildInfoRow('Requirements', activity['requirements'] ?? 'None'),
              _buildInfoRow('Status', activity['status']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingManagement(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage ${activity['name']}'),
        content: const Text('Activity management features coming soon!\n\nThis will include:\n• Booking management\n• Capacity adjustments\n• Schedule modifications\n• Status updates'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
