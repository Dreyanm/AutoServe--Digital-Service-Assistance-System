import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _facilityBookings = [];
  List<Map<String, dynamic>> _activityBookings = [];
  List<Map<String, dynamic>> _roomBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllBookings() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _loadFacilityBookings(),
      _loadActivityBookings(),
      _loadRoomBookings(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadFacilityBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getStringList('facility_bookings') ?? [];
    
    setState(() {
      _facilityBookings = bookingsJson.map((str) {
        final booking = json.decode(str) as Map<String, dynamic>;
        // Ensure status field exists
        if (!booking.containsKey('status')) {
          booking['status'] = 'Pending';
        }
        return booking;
      }).toList();
    });
  }

  Future<void> _loadActivityBookings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // First, try to migrate old activity bookings if they exist
    await _migrateOldActivityBookings(prefs);
    
    final bookingsJson = prefs.getStringList('activity_bookings') ?? [];
    
    setState(() {
      _activityBookings = bookingsJson.map((str) {
        final booking = json.decode(str) as Map<String, dynamic>;
        // Ensure status field exists
        if (!booking.containsKey('status')) {
          booking['status'] = 'Pending';
        }
        return booking;
      }).toList();
    });
  }

  Future<void> _migrateOldActivityBookings(SharedPreferences prefs) async {
    final oldActivityBookings = prefs.getStringList('joined_activities') ?? [];
    if (oldActivityBookings.isNotEmpty) {
      final currentBookings = prefs.getStringList('activity_bookings') ?? [];
      
      // Convert old format to new format
      for (String oldBookingStr in oldActivityBookings) {
        final oldBooking = json.decode(oldBookingStr) as Map<String, dynamic>;
        
        // Create new booking format
        final newBooking = {
          'id': oldBooking['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'activityName': oldBooking['activityName'] ?? 'Unknown Activity',
          'selectedDate': oldBooking['schedule'] ?? oldBooking['joinDate'] ?? oldBooking['date'],
          'selectedTime': oldBooking['time'] ?? oldBooking['selectedTime'],
          'numberOfPax': oldBooking['numberOfPax'] ?? 1,
          'totalAmount': oldBooking['totalAmount'] ?? '0',
          'bookingDate': oldBooking['joinDate'] ?? oldBooking['bookingDate'] ?? DateTime.now().toString().split(' ')[0],
          'specialRequests': oldBooking['specialRequests'] ?? '',
          'status': oldBooking['status'] ?? 'Pending',
        };
        
        currentBookings.add(json.encode(newBooking));
      }
      
      // Save migrated bookings and remove old ones
      await prefs.setStringList('activity_bookings', currentBookings);
      await prefs.remove('joined_activities');
    }
  }

  Future<void> _loadRoomBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getStringList('room_bookings') ?? [];
    
    setState(() {
      _roomBookings = bookingsJson.map((str) {
        final booking = json.decode(str) as Map<String, dynamic>;
        // Ensure status field exists
        if (!booking.containsKey('status')) {
          booking['status'] = 'Pending';
        }
        return booking;
      }).toList();
    });
  }

  List<Map<String, dynamic>> get _allBookings {
    final List<Map<String, dynamic>> all = [];
    
    // Add facility bookings with type identifier
    for (var booking in _facilityBookings) {
      all.add({...booking, 'bookingType': 'Facility'});
    }
    
    // Add activity bookings with type identifier
    for (var booking in _activityBookings) {
      all.add({...booking, 'bookingType': 'Activity'});
    }
    
    // Add room bookings with type identifier
    for (var booking in _roomBookings) {
      all.add({...booking, 'bookingType': 'Room'});
    }
    
    // Sort by booking date (newest first)
    all.sort((a, b) => (b['bookingDate'] ?? '').compareTo(a['bookingDate'] ?? ''));
    
    return all;
  }

  // Check if booking can be rated (completed and not already rated)
  bool _canBookingBeRated(Map<String, dynamic> booking) {
    final String status = booking['status']?.toString().toLowerCase() ?? '';
    final bool isCompleted = status == 'completed' || status == 'confirmed';
    final bool notRated = booking['rating'] == null || booking['rating'] == 0;
    return isCompleted && notRated;
  }

  // Handle booking card tap
  void _handleBookingTap(Map<String, dynamic> booking) {
    if (_canBookingBeRated(booking)) {
      _showRatingDialog(booking);
    } else {
      _showBookingDetails(booking);
    }
  }

  // Show rating dialog for completed bookings
  void _showRatingDialog(Map<String, dynamic> booking) {
    int selectedRating = 0;
    final TextEditingController feedbackController = TextEditingController();
    final String bookingType = booking['bookingType'] ?? 'Unknown';
    final String bookingName = _getBookingName(booking);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star_rate,
                        color: Colors.orange[600],
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rate Your Experience',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bookingName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How would you rate your experience?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Star Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              index < selectedRating ? Icons.star : Icons.star_border,
                              color: Colors.orange[600],
                              size: 32,
                            ),
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Rating description
                    if (selectedRating > 0) ...[
                      Center(
                        child: Text(
                          _getRatingDescription(selectedRating),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Feedback text field
                    TextField(
                      controller: feedbackController,
                      decoration: InputDecoration(
                        hintText: 'Share your feedback (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedRating > 0
                      ? () => _submitRating(booking, selectedRating, feedbackController.text)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit Rating'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Submit rating for booking
  Future<void> _submitRating(Map<String, dynamic> booking, int rating, String feedback) async {
    final prefs = await SharedPreferences.getInstance();
    final String bookingType = booking['bookingType'] ?? 'Unknown';
    final String bookingId = booking['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    // Update booking with rating
    booking['rating'] = rating;
    booking['feedback'] = feedback.trim().isEmpty ? 'No feedback provided' : feedback.trim();
    booking['ratingDate'] = DateTime.now().toIso8601String();
    
    // Save to appropriate list
    String listKey = '';
    List<Map<String, dynamic>> bookingList = [];
    
    switch (bookingType) {
      case 'Facility':
        listKey = 'facility_bookings';
        bookingList = _facilityBookings;
        break;
      case 'Activity':
        listKey = 'activity_bookings';
        bookingList = _activityBookings;
        break;
      case 'Room':
        listKey = 'room_bookings';
        bookingList = _roomBookings;
        break;
    }
    
    // Update the booking in the list
    final bookingIndex = bookingList.indexWhere((b) => b['id'] == bookingId);
    if (bookingIndex != -1) {
      bookingList[bookingIndex] = booking;
      
      // Save to SharedPreferences
      final List<String> bookingStrings = bookingList.map((b) => json.encode(b)).toList();
      await prefs.setStringList(listKey, bookingStrings);
    }
    
    // Close dialog
    Navigator.of(context).pop();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thank you for your rating! ⭐'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Refresh bookings
    await _loadAllBookings();
  }

  // Get rating description
  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  // Get booking name for display
  String _getBookingName(Map<String, dynamic> booking) {
    final String bookingType = booking['bookingType'] ?? 'Unknown';
    switch (bookingType) {
      case 'Facility':
        return booking['facilityName'] ?? booking['facilityType'] ?? 'Facility Booking';
      case 'Activity':
        return booking['activityName'] ?? 'Activity Booking';
      case 'Room':
        return booking['roomType'] ?? 'Room Booking';
      default:
        return 'Unknown Booking';
    }
  }

  // Show booking details dialog
  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Booking Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getBookingName(booking),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Status: ${booking['status'] ?? 'Unknown'}'),
                const SizedBox(height: 8),
                Text('Booking ID: ${booking['id'] ?? 'N/A'}'),
                if (booking['bookingDate'] != null) ...[
                  const SizedBox(height: 8),
                  Text('Booked on: ${booking['bookingDate']}'),
                ],
                if (booking['rating'] != null && booking['rating'] > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Your Rating:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < booking['rating'] ? Icons.star : Icons.star_border,
                          color: Colors.orange[600],
                          size: 20,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text('${booking['rating']}/5'),
                    ],
                  ),
                  if (booking['feedback'] != null && booking['feedback'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Feedback: ${booking['feedback']}',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ],
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Bookings',
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
          tabs: [
            Tab(text: 'All (${_allBookings.length})'),
            Tab(text: 'Facilities (${_facilityBookings.length})'),
            Tab(text: 'Activities (${_activityBookings.length})'),
            Tab(text: 'Rooms (${_roomBookings.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllBookingsTab(),
                _buildFacilityBookingsTab(),
                _buildActivityBookingsTab(),
                _buildRoomBookingsTab(),
              ],
            ),
    );
  }

  Widget _buildAllBookingsTab() {
    if (_allBookings.isEmpty) {
      return _buildEmptyState('No bookings found', 'Start exploring and make your first booking!');
    }

    return RefreshIndicator(
      onRefresh: _loadAllBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allBookings.length,
        itemBuilder: (context, index) {
          final booking = _allBookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildFacilityBookingsTab() {
    if (_facilityBookings.isEmpty) {
      return _buildEmptyState('No facility bookings', 'Book a facility to see it here!');
    }

    return RefreshIndicator(
      onRefresh: _loadFacilityBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _facilityBookings.length,
        itemBuilder: (context, index) {
          final booking = {..._facilityBookings[index], 'bookingType': 'Facility'};
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildActivityBookingsTab() {
    if (_activityBookings.isEmpty) {
      return _buildEmptyState('No activity bookings', 'Join an activity to see it here!');
    }

    return RefreshIndicator(
      onRefresh: _loadActivityBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activityBookings.length,
        itemBuilder: (context, index) {
          final booking = {..._activityBookings[index], 'bookingType': 'Activity'};
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildRoomBookingsTab() {
    if (_roomBookings.isEmpty) {
      return _buildEmptyState('No room bookings', 'Book a room to see it here!');
    }

    return RefreshIndicator(
      onRefresh: _loadRoomBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _roomBookings.length,
        itemBuilder: (context, index) {
          final booking = {..._roomBookings[index], 'bookingType': 'Room'};
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_online_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final String bookingType = booking['bookingType'] ?? 'Unknown';
    final String status = booking['status'] ?? 'Pending';
    final bool canBeRated = _canBookingBeRated(booking);
    
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
        // Add border for clickable completed bookings
        border: canBeRated
            ? Border.all(color: Colors.orange[300]!, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleBookingTap(booking),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with booking type and status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getBookingTypeColor(bookingType).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getBookingTypeIcon(bookingType),
                          color: _getBookingTypeColor(bookingType),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$bookingType Booking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getBookingTypeColor(bookingType),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildStatusChip(status),
                        if (canBeRated) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.orange[600],
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Rate',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Booking details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBookingDetails(booking, bookingType),
                    const SizedBox(height: 12),
                    
                    // Booking date
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Booked on: ${booking['bookingDate'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    // Status-specific messages
                    if (status == 'Pending') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.orange[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Awaiting staff approval. You will be notified once confirmed.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (status == 'Confirmed' || status == 'Approved') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Booking confirmed! Enjoy your ${bookingType.toLowerCase()}.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (status == 'Completed') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: canBeRated ? Colors.orange[50] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: canBeRated ? Colors.orange[200]! : Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              canBeRated ? Icons.star_rate : Icons.check_circle_outline,
                              size: 16,
                              color: canBeRated ? Colors.orange[600] : Colors.blue[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                canBeRated
                                    ? 'Tap to rate your experience! Your feedback helps us improve.'
                                    : 'Booking completed successfully. Thank you for your rating!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: canBeRated ? Colors.orange[700] : Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (status == 'Declined' || status == 'Rejected' || status == 'Cancelled') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cancel, size: 16, color: Colors.red[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                status == 'Declined' 
                                    ? 'Your booking has been declined by staff. Please contact our staff or admin for more information.'
                                    : status == 'Rejected'
                                        ? 'Your booking has been rejected. Please contact our staff or admin for more information.'
                                        : 'Your booking has been cancelled. Please contact our staff or admin if you need assistance.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Show existing rating if available
                    if (booking['rating'] != null && booking['rating'] > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.orange[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Your Rating:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < booking['rating'] ? Icons.star : Icons.star_border,
                                    color: Colors.orange[600],
                                    size: 16,
                                  );
                                }),
                                const SizedBox(width: 8),
                                Text(
                                  '${booking['rating']}/5',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (booking['feedback'] != null && 
                                booking['feedback'].toString().isNotEmpty && 
                                booking['feedback'] != 'No feedback provided') ...[
                              const SizedBox(height: 4),
                              Text(
                                'Feedback: ${booking['feedback']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingDetails(Map<String, dynamic> booking, String bookingType) {
    switch (bookingType) {
      case 'Facility':
        return _buildFacilityDetails(booking);
      case 'Activity':
        return _buildActivityDetails(booking);
      case 'Room':
        return _buildRoomDetails(booking);
      default:
        return const Text('Unknown booking type');
    }
  }

  Widget _buildFacilityDetails(Map<String, dynamic> booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          booking['facilityName'] ?? booking['facilityType'] ?? 'Unknown Facility',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 8),
        if (booking['checkInDate'] != null)
          _buildDetailRow('Check-in', booking['checkInDate']),
        if (booking['checkOutDate'] != null)
          _buildDetailRow('Check-out', booking['checkOutDate']),
        if (booking['time'] != null)
          _buildDetailRow('Time', booking['time']),
        if (booking['checkInTime'] != null)
          _buildDetailRow('Check-in Time', booking['checkInTime']),
        if (booking['checkOutTime'] != null)
          _buildDetailRow('Check-out Time', booking['checkOutTime']),
        if (booking['numberOfDays'] != null)
          _buildDetailRow('Duration', '${booking['numberOfDays']} day(s)'),
        if (booking['numberOfGuests'] != null)
          _buildDetailRow('Guests', '${booking['numberOfGuests']}'),
        if (booking['participants'] != null)
          _buildDetailRow('Participants', '${booking['participants']}'),
        if (booking['totalAmount'] != null)
          _buildDetailRow('Total Amount', booking['totalAmount']),
        if (booking['notes'] != null && booking['notes'].toString().isNotEmpty)
          _buildDetailRow('Notes', booking['notes']),
      ],
    );
  }

  Widget _buildActivityDetails(Map<String, dynamic> booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          booking['activityName'] ?? 'Unknown Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 8),
        if (booking['selectedDate'] != null)
          _buildDetailRow('Date', booking['selectedDate']),
        if (booking['selectedTime'] != null && booking['selectedTime'] != 'Not specified')
          _buildDetailRow('Time', booking['selectedTime']),
        if (booking['numberOfPax'] != null)
          _buildDetailRow('Participants', '${booking['numberOfPax']} pax'),
        if (booking['price'] != null)
          _buildDetailRow('Price per Person', booking['price']),
        if (booking['totalAmount'] != null)
          _buildDetailRow('Total Amount', 'P${booking['totalAmount']}'),
        if (booking['specialRequests'] != null && booking['specialRequests'].toString().isNotEmpty)
          _buildDetailRow('Special Requests', booking['specialRequests']),
      ],
    );
  }

  Widget _buildRoomDetails(Map<String, dynamic> booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          booking['roomType'] ?? 'Unknown Room',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 8),
        if (booking['checkInDate'] != null && booking['checkInTime'] != null)
          _buildDetailRow('Check-in', '${booking['checkInDate']} at ${booking['checkInTime']}'),
        if (booking['checkOutDate'] != null && booking['checkOutTime'] != null)
          _buildDetailRow('Check-out', '${booking['checkOutDate']} at ${booking['checkOutTime']}'),
        if (booking['numberOfNights'] != null)
          _buildDetailRow('Nights', '${booking['numberOfNights']}'),
        if (booking['numberOfGuests'] != null)
          _buildDetailRow('Guests', '${booking['numberOfGuests']}'),
        if (booking['pricePerNight'] != null)
          _buildDetailRow('Price per Night', 'P${booking['pricePerNight']}'),
        if (booking['totalAmount'] != null)
          _buildDetailRow('Total Amount', 'P${booking['totalAmount']}'),
        if (booking['specialRequests'] != null && booking['specialRequests'].toString().isNotEmpty)
          _buildDetailRow('Special Requests', booking['specialRequests']),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        icon = Icons.schedule;
        break;
      case 'confirmed':
      case 'approved':
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        break;
      case 'cancelled':
      case 'rejected':
      case 'declined':
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
        break;
      case 'completed':
        backgroundColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        icon = Icons.check_circle_outline;
        break;
      default:
        backgroundColor = Colors.grey[50]!;
        textColor = Colors.grey[700]!;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBookingTypeColor(String bookingType) {
    switch (bookingType) {
      case 'Facility':
        return Colors.blue[600]!;
      case 'Activity':
        return Colors.green[600]!;
      case 'Room':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getBookingTypeIcon(String bookingType) {
    switch (bookingType) {
      case 'Facility':
        return Icons.villa;
      case 'Activity':
        return Icons.sports_esports;
      case 'Room':
        return Icons.hotel;
      default:
        return Icons.book;
    }
  }
}
