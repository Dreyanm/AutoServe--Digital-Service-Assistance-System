import 'package:flutter/material.dart';

class AvailableFacilitiesScreen extends StatefulWidget {
  const AvailableFacilitiesScreen({Key? key}) : super(key: key);

  @override
  State<AvailableFacilitiesScreen> createState() => _AvailableFacilitiesScreenState();
}

class _AvailableFacilitiesScreenState extends State<AvailableFacilitiesScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _sortBy = 'Name';

  // Available facilities data (same as from FacilitiesScreen)
  final List<Map<String, dynamic>> _facilities = [
    {
      'name': 'Swimming Pool',
      'icon': Icons.pool,
      'image': 'SwimmingPool.jpeg',
      'description': 'Olympic-size swimming pool with crystal clear water and poolside amenities',
      'price': 'P200/hour',
      'availability': 'Available 6:00 AM - 10:00 PM',
      'status': 'Available',
      'capacity': 50,
      'currentOccupancy': 15,
      'operatingHours': '6:00 AM - 10:00 PM',
      'maintenanceSchedule': 'Daily 5:00 AM - 6:00 AM',
    },
    {
      'name': 'Restaurant',
      'icon': Icons.restaurant,
      'image': 'Restaurant.jpg',
      'description': 'Fine dining restaurant featuring local and international cuisine',
      'price': 'Table reservation free',
      'availability': 'Available 6:00 AM - 12:00 AM',
      'status': 'Available',
      'capacity': 80,
      'currentOccupancy': 45,
      'operatingHours': '6:00 AM - 12:00 AM',
      'maintenanceSchedule': 'Deep cleaning 2:00 AM - 5:00 AM',
    },
    {
      'name': 'Spa',
      'icon': Icons.spa,
      'image': 'Spa.jpg',
      'description': 'Luxurious spa offering relaxing treatments and wellness services',
      'price': 'P800/session',
      'availability': 'Available 9:00 AM - 8:00 PM',
      'status': 'Available',
      'capacity': 12,
      'currentOccupancy': 8,
      'operatingHours': '9:00 AM - 8:00 PM',
      'maintenanceSchedule': 'Weekly deep cleaning Sunday 6:00 AM - 9:00 AM',
    },
    {
      'name': 'Cottages',
      'icon': Icons.cottage,
      'image': 'Cottages.jpg',
      'description': 'Private beach cottages perfect for families and groups',
      'price': 'P1,500/day',
      'availability': 'Available 24/7',
      'status': 'Available',
      'capacity': 20,
      'currentOccupancy': 12,
      'operatingHours': '24/7',
      'maintenanceSchedule': 'Weekly cleaning and repairs',
    },
    {
      'name': 'Conference Room',
      'icon': Icons.meeting_room,
      'image': 'Conference.jpg',
      'description': 'Professional conference room with modern AV equipment for business meetings',
      'price': 'P500/hour',
      'availability': 'Available 8:00 AM - 6:00 PM',
      'status': 'Maintenance',
      'capacity': 30,
      'currentOccupancy': 0,
      'operatingHours': '8:00 AM - 6:00 PM',
      'maintenanceSchedule': 'Equipment upgrade in progress',
    },
    {
      'name': 'Gym & Fitness Center',
      'icon': Icons.fitness_center,
      'image': 'Gym.jpg',
      'description': 'Fully equipped gym with modern fitness equipment and personal trainers',
      'price': 'P300/day',
      'availability': 'Available 5:00 AM - 11:00 PM',
      'status': 'Available',
      'capacity': 25,
      'currentOccupancy': 18,
      'operatingHours': '5:00 AM - 11:00 PM',
      'maintenanceSchedule': 'Equipment maintenance 11:00 PM - 5:00 AM',
    },
  ];

  List<Map<String, dynamic>> get _filteredFacilities {
    var filtered = _facilities.where((facility) {
      final matchesSearch = facility['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           facility['description'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == 'All' || facility['status'] == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    // Sort facilities
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
        case 'Occupancy':
          final occupancyA = (a['currentOccupancy'] as int) / (a['capacity'] as int);
          final occupancyB = (b['currentOccupancy'] as int) / (b['capacity'] as int);
          return occupancyB.compareTo(occupancyA);
        default:
          return a['name'].compareTo(b['name']);
      }
    });

    return filtered;
  }

  double _extractPrice(String priceString) {
    if (priceString.toLowerCase().contains('free')) return 0.0;
    final regex = RegExp(r'P([\d,]+)');
    final match = regex.firstMatch(priceString);
    if (match != null) {
      return double.parse(match.group(1)!.replaceAll(',', ''));
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final filteredFacilities = _filteredFacilities;
    final availableCount = _facilities.where((f) => f['status'] == 'Available').length;
    final maintenanceCount = _facilities.where((f) => f['status'] == 'Maintenance').length;
    final totalCapacity = _facilities.fold<int>(0, (sum, f) => sum + (f['capacity'] as int));
    final totalOccupancy = _facilities.fold<int>(0, (sum, f) => sum + (f['currentOccupancy'] as int));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.purple[600],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Available Facilities',
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
            tooltip: 'Filter Facilities',
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
                colors: [Colors.purple[400]!, Colors.purple[600]!],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Facilities',
                        _facilities.length.toString(),
                        Icons.business,
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
                        'Maintenance',
                        maintenanceCount.toString(),
                        Icons.build,
                        Colors.orange[100]!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Utilization',
                        '${((totalOccupancy / totalCapacity) * 100).toInt()}%',
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
                hintText: 'Search facilities...',
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
                  'Found ${filteredFacilities.length} facilities',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  onChanged: (value) => setState(() => _sortBy = value!),
                  items: ['Name', 'Price', 'Capacity', 'Occupancy']
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

          // Facilities List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredFacilities.length,
              itemBuilder: (context, index) {
                final facility = filteredFacilities[index];
                return _buildFacilityCard(facility);
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
            color: backgroundColor == Colors.white ? Colors.purple[600] : Colors.grey[700],
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: backgroundColor == Colors.white ? Colors.purple[600] : Colors.grey[800],
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: backgroundColor == Colors.white ? Colors.purple[600] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(Map<String, dynamic> facility) {
    final occupancyRate = ((facility['currentOccupancy'] as int) / (facility['capacity'] as int) * 100).round();
    final isMaintenance = facility['status'] == 'Maintenance';
    final isNearCapacity = occupancyRate >= 80;

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
          // Header with facility icon and status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMaintenance 
                  ? Colors.orange[50] 
                  : isNearCapacity 
                    ? Colors.amber[50] 
                    : Colors.green[50],
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
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    facility['icon'],
                    color: Colors.purple[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facility['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        facility['description'],
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
                    color: isMaintenance 
                        ? Colors.orange[600] 
                        : isNearCapacity 
                          ? Colors.amber[600] 
                          : Colors.green[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isMaintenance 
                        ? 'Maintenance' 
                        : isNearCapacity 
                          ? 'Near Capacity' 
                          : 'Available',
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

          // Facility Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Operating Hours and Price
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        Icons.schedule,
                        'Hours',
                        facility['operatingHours'],
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailRow(
                        Icons.attach_money,
                        'Price',
                        facility['price'],
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Capacity and Occupancy
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        Icons.people,
                        'Capacity',
                        '${facility['capacity']} people',
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailRow(
                        Icons.group,
                        'Current',
                        '${facility['currentOccupancy']} ($occupancyRate%)',
                        occupancyRate >= 80 ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Occupancy Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Occupancy Level',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$occupancyRate%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: occupancyRate / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        occupancyRate >= 90 
                            ? Colors.red 
                            : occupancyRate >= 70 
                              ? Colors.orange 
                              : Colors.green,
                      ),
                    ),
                  ],
                ),

                if (facility['maintenanceSchedule'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.build_circle_outlined, color: Colors.blue[600], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Maintenance: ${facility['maintenanceSchedule']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
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
                    onPressed: () => _showFacilityDetails(facility),
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
                    onPressed: () => _showFacilityManagement(facility),
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Manage'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
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
        title: const Text('Filter Facilities'),
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
              items: ['All', 'Available', 'Maintenance']
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
              items: ['Name', 'Price', 'Capacity', 'Occupancy']
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

  void _showFacilityDetails(Map<String, dynamic> facility) {
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
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(facility['icon'], color: Colors.purple[600]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      facility['name'],
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
                facility['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Operating Hours', facility['operatingHours']),
              _buildInfoRow('Price', facility['price']),
              _buildInfoRow('Capacity', '${facility['capacity']} people'),
              _buildInfoRow('Current Occupancy', '${facility['currentOccupancy']} people'),
              _buildInfoRow('Occupancy Rate', '${((facility['currentOccupancy'] as int) / (facility['capacity'] as int) * 100).round()}%'),
              _buildInfoRow('Status', facility['status']),
              _buildInfoRow('Maintenance Schedule', facility['maintenanceSchedule'] ?? 'None'),
              _buildInfoRow('Availability', facility['availability']),
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
            width: 140,
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

  void _showFacilityManagement(Map<String, dynamic> facility) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage ${facility['name']}'),
        content: const Text('Facility management features coming soon!\n\nThis will include:\n• Occupancy adjustments\n• Status updates\n• Maintenance scheduling\n• Price modifications\n• Operating hours changes'),
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
