import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({Key? key}) : super(key: key);

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Available activities
  final List<Map<String, dynamic>> _activities = [
    {
      'name': 'Island Hopping',
      'icon': Icons.directions_boat,
      'description': 'Explore beautiful nearby islands with crystal clear waters and pristine beaches',
      'schedule': '8:00 AM - 4:00 PM',
      'duration': '8 hours',
      'capacity': 20,
      'price': 'P1,200 per person',
      'status': 'Available',
      'date': 'Daily',
      'requirements': 'Swimming ability required',
    },
    {
      'name': 'Snorkeling Adventure',
      'icon': Icons.scuba_diving,
      'description': 'Discover underwater marine life and colorful coral reefs',
      'schedule': '9:00 AM - 12:00 PM',
      'duration': '3 hours',
      'capacity': 15,
      'price': 'P800 per person',
      'status': 'Available',
      'date': 'Daily',
      'requirements': 'Basic swimming skills',
    },
    {
      'name': 'Banana Boating',
      'icon': Icons.sports_motorsports,
      'description': 'Thrilling banana boat ride through crystal clear waters with friends and family',
      'schedule': '10:00 AM - 4:00 PM',
      'duration': '30 minutes',
      'capacity': 8,
      'price': 'P500 per person',
      'status': 'Available',
      'date': 'Daily',
      'requirements': 'Basic swimming skills',
    },
    {
      'name': 'Beach Volleyball',
      'icon': Icons.sports_volleyball,
      'description': 'Fun beach volleyball tournament with prizes for winners',
      'schedule': '3:00 PM - 5:00 PM',
      'duration': '2 hours',
      'capacity': 12,
      'price': 'Free',
      'status': 'Available',
      'date': 'Weekends',
      'requirements': 'Basic fitness level',
    },
    {
      'name': 'Kayaking',
      'icon': Icons.kayaking,
      'description': 'Paddle through calm waters and explore hidden coves',
      'schedule': '10:00 AM - 12:00 PM',
      'duration': '2 hours',
      'capacity': 10,
      'price': 'P500 per person',
      'status': 'Available',
      'date': 'Daily',
      'requirements': 'Basic swimming skills',
    },
    {
      'name': 'Fishing Trip',
      'icon': Icons.phishing,
      'description': 'Traditional fishing experience with local guides',
      'schedule': '6:00 AM - 10:00 AM',
      'duration': '4 hours',
      'capacity': 8,
      'price': 'P900 per person',
      'status': 'Fully Booked',
      'date': 'Daily',
      'requirements': 'Early morning availability',
    },

  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Resort Activities',
          style: TextStyle(
            color: Colors.blue[800],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue[600],
          labelColor: Colors.blue[600],
          unselectedLabelColor: Colors.grey[600],
          tabs: const [
            Tab(text: 'All Activities'),
            Tab(text: 'My Activities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllActivitiesTab(),
          _buildMyActivitiesTab(),
        ],
      ),
    );
  }

  Widget _buildAllActivitiesTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Activities',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join exciting activities and create unforgettable memories',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                return _buildActivityCard(_activities[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final bool isAvailable = activity['status'] == 'Available';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    activity['icon'],
                    color: Colors.blue[600],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activity['status'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isAvailable ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              activity['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Details grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildDetailItem(Icons.schedule, 'Schedule', activity['schedule']),
                ),
                Expanded(
                  child: _buildDetailItem(Icons.hourglass_empty, 'Duration', activity['duration']),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildDetailItem(Icons.people, 'Capacity', '${activity['capacity']} people'),
                ),
                Expanded(
                  child: _buildDetailItem(Icons.calendar_today, 'When', activity['date']),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildDetailItem(Icons.attach_money, 'Price', activity['price']),
                ),
                Expanded(
                  child: _buildDetailItem(Icons.info_outline, 'Requirements', activity['requirements']),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Join button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isAvailable ? () => _joinActivity(activity) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAvailable ? Colors.blue[600] : Colors.grey[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isAvailable ? 'Join Activity' : 'Fully Booked',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyActivitiesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadJoinedActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final joinedActivities = snapshot.data ?? [];
        
        if (joinedActivities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No activities joined yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join exciting activities to see them here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }
        
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Joined Activities',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Activities you have joined',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: joinedActivities.length,
                  itemBuilder: (context, index) {
                    return _buildJoinedActivityCard(joinedActivities[index]);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJoinedActivityCard(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['activityName'] ?? 'Unknown Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Joined on: ${activity['joinDate'] ?? 'Unknown date'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Booking Details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Number of People
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Number of People:',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${activity['numberOfPeople'] ?? '1'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Total Cost
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Cost:',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      activity['totalCost'] != null && activity['totalCost'] > 0
                          ? '₱${(activity['totalCost'] as double).toStringAsFixed(0)}'
                          : 'Free',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Payment Method
                if (activity['paymentMethod'] != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment Method:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        activity['paymentMethod'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                
                // Reference ID
                if (activity['referenceId'] != null && activity['referenceId'].isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reference ID:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        activity['referenceId'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                
                // Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status:',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        activity['status'] ?? 'Pending',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Instruction text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'You have successfully joined this activity. Please be at the meeting point 15 minutes before the scheduled time.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinActivity(Map<String, dynamic> activity) async {
    // Show enhanced booking dialog
    final Map<String, dynamic>? bookingData = await _showBookingDialog(activity);
    
    if (bookingData != null) {
      // Save joined activity to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final existingActivities = prefs.getStringList('joined_activities') ?? [];
      
      final joinedActivity = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'activityName': activity['name'],
        'schedule': activity['schedule'],
        'price': activity['price'],
        'joinDate': DateTime.now().toString().split(' ')[0],
        'status': 'Pending',
        'numberOfPeople': bookingData['numberOfPeople'],
        'paymentMethod': bookingData['paymentMethod'],
        'referenceId': bookingData['referenceId'],
        'totalCost': bookingData['totalCost'],
        'paymentScreenshot': bookingData['paymentScreenshot'],
      };
      
      existingActivities.add(json.encode(joinedActivity));
      await prefs.setStringList('joined_activities', existingActivities);

      _showSnackBar('Successfully joined ${activity['name']}! Awaiting staff confirmation.', Colors.green);
      
      // Switch to My Activities tab
      _tabController.animateTo(1);
    }
  }

  Future<Map<String, dynamic>?> _showBookingDialog(Map<String, dynamic> activity) async {
    int numberOfPeople = 1;
    String? selectedPaymentMethod;
    final TextEditingController referenceIdController = TextEditingController();
    XFile? paymentScreenshot;
    final ImagePicker picker = ImagePicker();
    
    return await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Book ${activity['name']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Activity Details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Activity Details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Schedule: ${activity['schedule']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            'Duration: ${activity['duration']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            'Price: ${activity['price']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Number of People
                    Text(
                      'Number of People',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: numberOfPeople > 1
                              ? () => setState(() => numberOfPeople--)
                              : null,
                          icon: Icon(Icons.remove_circle_outline),
                          color: Colors.blue[600],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$numberOfPeople',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: numberOfPeople < (activity['capacity'] ?? 20)
                              ? () => setState(() => numberOfPeople++)
                              : null,
                          icon: Icon(Icons.add_circle_outline),
                          color: Colors.blue[600],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Payment Method (only for paid activities)
                    if (activity['price'] != 'Free') ...[
                      Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedPaymentMethod,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'GCash',
                            child: Row(
                              children: [
                                Icon(Icons.phone_android, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('GCash'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Bank Transfer',
                            child: Row(
                              children: [
                                Icon(Icons.account_balance, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Bank Transfer'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedPaymentMethod = value;
                          });
                        },
                        hint: Text('Select Payment Method'),
                      ),
                      const SizedBox(height: 12),
                      
                      // Payment Instructions
                      if (selectedPaymentMethod != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Payment Instructions',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedPaymentMethod == 'GCash'
                                    ? 'Send payment to GCash: 09123456789\nAccount: Resort Management'
                                    : 'Bank Transfer: BDO\nAccount: 1234567890\nName: Resort Management',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Reference ID
                        TextField(
                          controller: referenceIdController,
                          decoration: InputDecoration(
                            labelText: 'Reference ID',
                            hintText: 'Enter payment reference ID',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Payment Screenshot
                        ElevatedButton.icon(
                          onPressed: () async {
                            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              setState(() {
                                paymentScreenshot = image;
                              });
                            }
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            paymentScreenshot != null ? 'Screenshot Selected' : 'Upload Payment Screenshot',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: paymentScreenshot != null ? Colors.green : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                    
                    // Booking Summary
                    _buildDialogBookingSummary(activity, numberOfPeople),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validate required fields
                    if (activity['price'] != 'Free' && 
                        (selectedPaymentMethod == null || referenceIdController.text.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please complete payment information')),
                      );
                      return;
                    }
                    
                    // Calculate total cost
                    double totalCost = 0.0;
                    if (activity['price'] != 'Free') {
                      final priceString = activity['price'].replaceAll(RegExp(r'[^\d]'), '');
                      if (priceString.isNotEmpty) {
                        totalCost = double.parse(priceString) * numberOfPeople;
                      }
                    }
                    
                    Navigator.of(context).pop({
                      'numberOfPeople': numberOfPeople,
                      'paymentMethod': selectedPaymentMethod,
                      'referenceId': referenceIdController.text,
                      'totalCost': totalCost,
                      'paymentScreenshot': paymentScreenshot?.path,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Book Activity'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogBookingSummary(Map<String, dynamic> activity, int numberOfPeople) {
    double totalCost = 0.0;
    
    if (activity['price'] != 'Free') {
      final priceString = activity['price'].replaceAll(RegExp(r'[^\d]'), '');
      if (priceString.isNotEmpty) {
        totalCost = double.parse(priceString) * numberOfPeople;
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt, color: Colors.green[600], size: 16),
              const SizedBox(width: 8),
              Text(
                'Booking Summary',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Activity Name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity:',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
              Expanded(
                child: Text(
                  activity['name'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Number of People
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'People:',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '$numberOfPeople',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Price per person
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price per person:',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                activity['price'],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Divider
          Divider(color: Colors.green[200], height: 12),
          
          // Total Cost
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Cost:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              Text(
                activity['price'] == 'Free' ? 'Free' : '₱${totalCost.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadJoinedActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final activityStrings = prefs.getStringList('joined_activities') ?? [];
    
    return activityStrings.map((str) {
      final activity = json.decode(str) as Map<String, dynamic>;
      return activity;
    }).toList();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
