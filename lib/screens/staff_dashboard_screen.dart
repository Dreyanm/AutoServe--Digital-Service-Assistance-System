import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'staff_panel_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  String? staffName;
  String? staffEmail;
  String? staffRole;
  int _selectedIndex = 0;
  
  // Add refresh key to force FutureBuilder to rebuild
  GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  DateTime _lastRefreshTime = DateTime.now();
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadStaffData();
    _startAutoRefresh();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh when user returns to this screen, not on every rebuild
    // Check if more than 5 seconds have passed since last refresh
    final now = DateTime.now();
    final timeSinceLastRefresh = now.difference(_lastRefreshTime);
    
    if (timeSinceLastRefresh.inSeconds > 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _lastRefreshTime = now;
          });
        }
      });
    }
  }
  
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
  
  // Auto-refresh every 30 seconds to catch new bookings
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshDashboard();
      }
    });
  }

  Future<void> _loadStaffData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      staffName = prefs.getString('user_name') ?? 'Staff Member';
      staffEmail = prefs.getString('user_email') ?? 'staff@resort.com';
      staffRole = prefs.getString('user_role') ?? 'staff';
    });
  }

  // Add refresh method to force rebuild of FutureBuilders
  Future<void> _refreshDashboard() async {
    if (!mounted) return;
    
    setState(() {
      _lastRefreshTime = DateTime.now();
    });
    
    // Wait a bit to ensure data is loaded
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Show refresh feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dashboard refreshed! ✓'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Public method to trigger refresh from external sources
  void refreshDashboard() {
    _refreshDashboard();
  }

  // Helper method to format last refresh time
  String _formatLastRefreshTime() {
    final now = DateTime.now();
    final diff = now.difference(_lastRefreshTime);
    
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // No navigation needed - we'll show different content based on _selectedIndex
  }

  // Load actual completed service requests from SharedPreferences
  Future<List<Map<String, dynamic>>> _getCompletedServiceRequests() async {
    final prefs = await SharedPreferences.getInstance();
    
    List<Map<String, dynamic>> completedRequests = [];
    Set<String> processedIds = {}; // Track processed IDs to avoid duplicates
    
    // Load service requests (including moved bookings)
    final requestStrings = prefs.getStringList('service_requests') ?? [];
    final serviceRequests = requestStrings.map((str) {
      final request = json.decode(str) as Map<String, dynamic>;
      request['type'] = 'Service Request'; // Ensure type is set
      return request;
    }).where((request) {
      return request['status'] == 'Completed' || 
             (request['rated'] == true && request['rating'] != null) ||
             (request['originalBookingType'] != null); // Include moved bookings
    }).toList();
    
    // Add service requests and track their IDs
    for (var request in serviceRequests) {
      final id = request['id'] ?? '';
      if (id.isNotEmpty && !processedIds.contains(id)) {
        processedIds.add(id);
        completedRequests.add(request);
      }
    }
    
    // Load completed facility bookings with ratings (only if not already processed)
    final facilityBookingStrings = prefs.getStringList('facility_bookings') ?? [];
    final completedFacilityBookings = facilityBookingStrings.map((str) {
      final booking = json.decode(str) as Map<String, dynamic>;
      booking['type'] = 'Facility Booking';
      booking['serviceType'] = booking['facilityName'] ?? 'Facility Booking'; // For display consistency
      return booking;
    }).where((booking) {
      final id = booking['id'] ?? '';
      return (booking['status'] == 'Confirmed' || booking['status'] == 'Completed') &&
             (booking['rating'] != null || booking['confirmedBy'] != null) &&
             !processedIds.contains(id); // Avoid duplicates
    }).toList();
    
    // Add facility bookings and track their IDs
    for (var booking in completedFacilityBookings) {
      final id = booking['id'] ?? '';
      if (id.isNotEmpty) {
        processedIds.add(id);
        completedRequests.add(booking);
      }
    }
    
    // Load completed activity bookings with ratings (only if not already processed)
    final activityBookingStrings = prefs.getStringList('activity_bookings') ?? [];
    final completedActivityBookings = activityBookingStrings.map((str) {
      final booking = json.decode(str) as Map<String, dynamic>;
      booking['type'] = 'Activity Booking';
      booking['serviceType'] = booking['activityName'] ?? 'Activity Booking'; // For display consistency
      return booking;
    }).where((booking) {
      final id = booking['id'] ?? '';
      return (booking['status'] == 'Confirmed' || booking['status'] == 'Completed') &&
             (booking['rating'] != null || booking['confirmedBy'] != null) &&
             !processedIds.contains(id); // Avoid duplicates
    }).toList();
    
    // Add activity bookings and track their IDs
    for (var booking in completedActivityBookings) {
      final id = booking['id'] ?? '';
      if (id.isNotEmpty) {
        processedIds.add(id);
        completedRequests.add(booking);
      }
    }
    
    // Load completed room bookings with ratings (only if not already processed)
    final roomBookingStrings = prefs.getStringList('room_bookings') ?? [];
    final completedRoomBookings = roomBookingStrings.map((str) {
      final booking = json.decode(str) as Map<String, dynamic>;
      booking['type'] = 'Room Booking';
      booking['serviceType'] = booking['roomType'] ?? 'Room Booking'; // For display consistency
      return booking;
    }).where((booking) {
      final id = booking['id'] ?? '';
      return (booking['status'] == 'Confirmed' || booking['status'] == 'Completed') &&
             (booking['rating'] != null || booking['confirmedBy'] != null) &&
             !processedIds.contains(id); // Avoid duplicates
    }).toList();
    
    // Add room bookings and track their IDs
    for (var booking in completedRoomBookings) {
      final id = booking['id'] ?? '';
      if (id.isNotEmpty) {
        processedIds.add(id);
        completedRequests.add(booking);
      }
    }
    
    // Sort by submitted date (newest first) - when the booking was actually made
    completedRequests.sort((a, b) {
      try {
        // Use submitted date for sorting (when the booking was made)
        String dateStringA = a['dateSubmitted'] ?? a['bookingDate'] ?? a['date'] ?? DateTime.now().toString();
        String dateStringB = b['dateSubmitted'] ?? b['bookingDate'] ?? b['date'] ?? DateTime.now().toString();
        
        // Handle various date formats
        DateTime dateA;
        DateTime dateB;
        
        // Try parsing different date formats
        try {
          dateA = DateTime.parse(dateStringA);
        } catch (e) {
          // If parsing fails, use current date
          dateA = DateTime.now();
        }
        
        try {
          dateB = DateTime.parse(dateStringB);
        } catch (e) {
          // If parsing fails, use current date
          dateB = DateTime.now();
        }
        
        return dateB.compareTo(dateA);
      } catch (e) {
        // If any error occurs, treat as equal
        return 0;
      }
    });
    
    return completedRequests;
  }

  // Load all guest ratings from different booking types
  Future<List<Map<String, dynamic>>> _getAllGuestRatings() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> allRatings = [];
    Set<String> processedIds = {}; // Track processed IDs to avoid duplicates
    
    // Load service requests with ratings
    final serviceRequestStrings = prefs.getStringList('service_requests') ?? [];
    final serviceRatings = serviceRequestStrings.map((str) {
      final request = json.decode(str) as Map<String, dynamic>;
      request['type'] = 'Service Request';
      return request;
    }).where((request) {
      final id = request['id'] ?? '';
      final hasRating = request['rating'] != null && request['rating'] > 0;
      return hasRating && !processedIds.contains(id);
    }).toList();
    
    // Add service ratings and track IDs
    for (var rating in serviceRatings) {
      final id = rating['id'] ?? '';
      if (id.isNotEmpty) {
        processedIds.add(id);
        allRatings.add(rating);
      }
    }
    
    // Load facility bookings with ratings
    final facilityBookingStrings = prefs.getStringList('facility_bookings') ?? [];
    final facilityRatings = facilityBookingStrings.map((str) {
      final booking = json.decode(str) as Map<String, dynamic>;
      booking['type'] = 'Facility Booking';
      booking['serviceType'] = booking['facilityName'] ?? 'Facility Booking';
      return booking;
    }).where((booking) {
      final id = booking['id'] ?? '';
      final hasRating = booking['rating'] != null && booking['rating'] > 0;
      return hasRating && !processedIds.contains(id);
    }).toList();
    
    // Add facility ratings and track IDs
    for (var rating in facilityRatings) {
      final id = rating['id'] ?? '';
      if (id.isNotEmpty) {
        processedIds.add(id);
        allRatings.add(rating);
      }
    }
    
    // Load activity bookings with ratings
    final activityBookingStrings = prefs.getStringList('activity_bookings') ?? [];
    final activityRatings = activityBookingStrings.map((str) {
      final booking = json.decode(str) as Map<String, dynamic>;
      booking['type'] = 'Activity Booking';
      booking['serviceType'] = booking['activityName'] ?? 'Activity Booking';
      return booking;
    }).where((booking) {
      final id = booking['id'] ?? '';
      final hasRating = booking['rating'] != null && booking['rating'] > 0;
      return hasRating && !processedIds.contains(id);
    }).toList();
    
    // Add activity ratings and track IDs
    for (var rating in activityRatings) {
      final id = rating['id'] ?? '';
      if (id.isNotEmpty) {
        processedIds.add(id);
        allRatings.add(rating);
      }
    }
    
    // Load room bookings with ratings
    final roomBookingStrings = prefs.getStringList('room_bookings') ?? [];
    final roomRatings = roomBookingStrings.map((str) {
      final booking = json.decode(str) as Map<String, dynamic>;
      booking['type'] = 'Room Booking';
      booking['serviceType'] = booking['roomType'] ?? 'Room Booking';
      return booking;
    }).where((booking) {
      final id = booking['id'] ?? '';
      final hasRating = booking['rating'] != null && booking['rating'] > 0;
      return hasRating && !processedIds.contains(id);
    }).toList();
    
    // Add room ratings and track IDs
    for (var rating in roomRatings) {
      final id = rating['id'] ?? '';
      if (id.isNotEmpty) {
        processedIds.add(id);
        allRatings.add(rating);
      }
    }
    
    // Sort by rating date/submitted date (newest first)
    allRatings.sort((a, b) {
      try {
        String dateStringA = a['ratingDate'] ?? a['dateSubmitted'] ?? a['bookingDate'] ?? a['date'] ?? DateTime.now().toString();
        String dateStringB = b['ratingDate'] ?? b['dateSubmitted'] ?? b['bookingDate'] ?? b['date'] ?? DateTime.now().toString();
        
        DateTime dateA;
        DateTime dateB;
        
        try {
          dateA = DateTime.parse(dateStringA);
        } catch (e) {
          dateA = DateTime.now();
        }
        
        try {
          dateB = DateTime.parse(dateStringB);
        } catch (e) {
          dateB = DateTime.now();
        }
        
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });
    
    return allRatings;
  }

  // Calculate average ratings by category
  Map<String, dynamic> _calculateRatingStatistics(List<Map<String, dynamic>> ratings) {
    if (ratings.isEmpty) {
      return {
        'overall': 0.0,
        'count': 0,
        'serviceRequests': 0.0,
        'facilityBookings': 0.0,
        'activityBookings': 0.0,
        'roomBookings': 0.0,
        'distribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      };
    }

    double totalRating = 0.0;
    int totalCount = 0;
    Map<String, List<double>> categoryRatings = {
      'Service Request': [],
      'Facility Booking': [],
      'Activity Booking': [],
      'Room Booking': [],
    };
    Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (var rating in ratings) {
      final ratingValue = (rating['rating'] ?? 0).toDouble();
      if (ratingValue > 0) {
        totalRating += ratingValue;
        totalCount++;
        
        final type = rating['type'] ?? 'Service Request';
        categoryRatings[type]?.add(ratingValue);
        
        // Count rating distribution
        final ratingInt = ratingValue.round();
        if (distribution.containsKey(ratingInt)) {
          distribution[ratingInt] = distribution[ratingInt]! + 1;
        }
      }
    }

    return {
      'overall': totalCount > 0 ? totalRating / totalCount : 0.0,
      'count': totalCount,
      'serviceRequests': categoryRatings['Service Request']!.isEmpty 
          ? 0.0 
          : categoryRatings['Service Request']!.reduce((a, b) => a + b) / categoryRatings['Service Request']!.length,
      'facilityBookings': categoryRatings['Facility Booking']!.isEmpty 
          ? 0.0 
          : categoryRatings['Facility Booking']!.reduce((a, b) => a + b) / categoryRatings['Facility Booking']!.length,
      'activityBookings': categoryRatings['Activity Booking']!.isEmpty 
          ? 0.0 
          : categoryRatings['Activity Booking']!.reduce((a, b) => a + b) / categoryRatings['Activity Booking']!.length,
      'roomBookings': categoryRatings['Room Booking']!.isEmpty 
          ? 0.0 
          : categoryRatings['Room Booking']!.reduce((a, b) => a + b) / categoryRatings['Room Booking']!.length,
      'distribution': distribution,
    };
  }

  // Load all ongoing requests from different booking types
  Future<List<Map<String, dynamic>>> _getOngoingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> allRequests = [];
    
    // Debug: Print when we're loading requests
    print('🔍 Loading ongoing requests at ${DateTime.now()}');
    
    // Load service requests
    final serviceRequestStrings = prefs.getStringList('service_requests') ?? [];
    final serviceRequests = serviceRequestStrings.map((str) {
      final request = json.decode(str) as Map<String, dynamic>;
      request['type'] = 'Service Request';
      request['route'] = '/serviceRequest';
      return request;
    }).where((request) => 
      request['status'] != 'Completed' && 
      (request['rated'] != true || request['rating'] == null)
    ).toList();
    
    print('📝 Found ${serviceRequests.length} service requests');
    
    // Load facility bookings - show all except explicitly finished ones
    final facilityBookingStrings = prefs.getStringList('facility_bookings') ?? [];
    final facilityBookings = facilityBookingStrings.map((str) {
      final booking = json.decode(str) as Map<String, dynamic>;
      booking['type'] = 'Facility Booking';
      booking['route'] = '/dashboard'; // Navigate to main dashboard to access facilities
      return booking;
    }).where((booking) {
      final status = booking['status']?.toString().toLowerCase() ?? '';
      // Show all bookings except those that are explicitly completed, confirmed, or declined
      return status != 'confirmed' && 
             status != 'completed' && 
             status != 'declined';
    }).toList();
    
    print('🏢 Found ${facilityBookings.length} facility bookings');
    
    // Load activity bookings - show all except explicitly finished ones
    final activityBookingStrings = prefs.getStringList('activity_bookings') ?? [];
    print('🎯 Raw activity bookings count: ${activityBookingStrings.length}');
    
    final activityBookings = activityBookingStrings.map((str) {
      final booking = json.decode(str) as Map<String, dynamic>;
      booking['type'] = 'Activity Booking';
      booking['route'] = '/dashboard'; // Navigate to main dashboard to access activities
      
      // Debug: Print each booking's status
      print('📋 Activity booking: ${booking['activityName']} - Status: ${booking['status']} - ID: ${booking['id']}');
      
      return booking;
    }).where((booking) {
      final status = booking['status']?.toString().toLowerCase() ?? '';
      final shouldShow = status != 'confirmed' && 
                        status != 'completed' && 
                        status != 'declined';
      
      print('  ➡️ Should show: $shouldShow (status: "$status")');
      return shouldShow;
    }).toList();
    
    print('🎾 Found ${activityBookings.length} activity bookings to show');
    
    // Load room bookings - show all except explicitly finished ones
    final roomBookingStrings = prefs.getStringList('room_bookings') ?? [];
    final roomBookings = roomBookingStrings.map((str) {
      final booking = json.decode(str) as Map<String, dynamic>;
      booking['type'] = 'Room Booking';
      booking['route'] = '/dashboard'; // Navigate to main dashboard to access rooms
      return booking;
    }).where((booking) {
      final status = booking['status']?.toString().toLowerCase() ?? '';
      // Show all bookings except those that are explicitly completed, confirmed, or declined
      return status != 'confirmed' && 
             status != 'completed' && 
             status != 'declined';
    }).toList();
    
    print('🏨 Found ${roomBookings.length} room bookings');
    
    // Combine all requests
    allRequests.addAll(serviceRequests);
    allRequests.addAll(facilityBookings);
    allRequests.addAll(activityBookings);
    allRequests.addAll(roomBookings);
    
    print('📊 Total ongoing requests to show: ${allRequests.length}');
    
    // Sort by submitted date (newest first) - when the booking was actually made
    allRequests.sort((a, b) {
      try {
        // Use submitted date for sorting (when the booking was made)
        String dateStringA = a['dateSubmitted'] ?? a['bookingDate'] ?? a['date'] ?? DateTime.now().toString();
        String dateStringB = b['dateSubmitted'] ?? b['bookingDate'] ?? b['date'] ?? DateTime.now().toString();
        
        // Handle cases where the date might be a time format (e.g., "8:00 AM - 4:00 PM")
        if (!dateStringA.contains('-') || dateStringA.contains('AM') || dateStringA.contains('PM')) {
          dateStringA = DateTime.now().toString();
        }
        if (!dateStringB.contains('-') || dateStringB.contains('AM') || dateStringB.contains('PM')) {
          dateStringB = DateTime.now().toString();
        }
        
        DateTime dateA = DateTime.parse(dateStringA);
        DateTime dateB = DateTime.parse(dateStringB);
        return dateB.compareTo(dateA);
      } catch (e) {
        // If parsing fails, treat as current time
        return 0;
      }
    });
    
    print('✅ Returning ${allRequests.length} sorted requests');
    return allRequests;
  }

  // Load all declined requests from different booking types
  Future<List<Map<String, dynamic>>> _getDeclinedRequests() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> allDeclinedRequests = [];
    
    // Debug: Print when we're loading declined requests
    print('🔍 Loading declined requests at ${DateTime.now()}');
    
    // Load declined service requests
    final serviceRequestStrings = prefs.getStringList('service_requests') ?? [];
    final declinedServiceRequests = serviceRequestStrings.map((str) {
      final request = json.decode(str) as Map<String, dynamic>;
      request['type'] = 'Service Request';
      request['route'] = '/serviceRequest';
      return request;
    }).where((request) => 
      request['status']?.toString().toLowerCase() == 'declined'
    ).toList();
    
    print('📝 Found ${declinedServiceRequests.length} declined service requests');
    
    // Load declined facility bookings
    final facilityBookingStrings = prefs.getStringList('facility_bookings') ?? [];
    final declinedFacilityBookings = facilityBookingStrings.map((str) {
      final booking = json.decode(str) as Map<String, dynamic>;
      booking['type'] = 'Facility Booking';
      booking['route'] = '/dashboard';
      return booking;
    }).where((booking) {
      final status = booking['status']?.toString().toLowerCase() ?? '';
      return status == 'declined';
    }).toList();
    
    print('🏢 Found ${declinedFacilityBookings.length} declined facility bookings');
    
    // Load declined activity bookings
    final activityBookingStrings = prefs.getStringList('activity_bookings') ?? [];
    final declinedActivityBookings = activityBookingStrings.map((str) {
      final booking = json.decode(str) as Map<String, dynamic>;
      booking['type'] = 'Activity Booking';
      booking['route'] = '/dashboard';
      return booking;
    }).where((booking) {
      final status = booking['status']?.toString().toLowerCase() ?? '';
      return status == 'declined';
    }).toList();
    
    print('🎾 Found ${declinedActivityBookings.length} declined activity bookings');
    
    // Load declined room bookings
    final roomBookingStrings = prefs.getStringList('room_bookings') ?? [];
    final declinedRoomBookings = roomBookingStrings.map((str) {
      final booking = json.decode(str) as Map<String, dynamic>;
      booking['type'] = 'Room Booking';
      booking['route'] = '/dashboard';
      return booking;
    }).where((booking) {
      final status = booking['status']?.toString().toLowerCase() ?? '';
      return status == 'declined';
    }).toList();
    
    print('🏨 Found ${declinedRoomBookings.length} declined room bookings');
    
    // Combine all declined requests
    allDeclinedRequests.addAll(declinedServiceRequests);
    allDeclinedRequests.addAll(declinedFacilityBookings);
    allDeclinedRequests.addAll(declinedActivityBookings);
    allDeclinedRequests.addAll(declinedRoomBookings);
    
    print('📊 Total declined requests to show: ${allDeclinedRequests.length}');
    
    // Sort by declined date (newest first) - when the request was declined
    allDeclinedRequests.sort((a, b) {
      try {
        // Use declined date for sorting (when the request was declined)
        String dateStringA = a['dateDeclined'] ?? a['dateSubmitted'] ?? a['bookingDate'] ?? a['date'] ?? DateTime.now().toString();
        String dateStringB = b['dateDeclined'] ?? b['dateSubmitted'] ?? b['bookingDate'] ?? b['date'] ?? DateTime.now().toString();
        
        // Handle cases where the date might be a time format (e.g., "8:00 AM - 4:00 PM")
        if (!dateStringA.contains('-') || dateStringA.contains('AM') || dateStringA.contains('PM')) {
          dateStringA = DateTime.now().toString();
        }
        if (!dateStringB.contains('-') || dateStringB.contains('AM') || dateStringB.contains('PM')) {
          dateStringB = DateTime.now().toString();
        }
        
        DateTime dateA = DateTime.parse(dateStringA);
        DateTime dateB = DateTime.parse(dateStringB);
        return dateB.compareTo(dateA);
      } catch (e) {
        // If parsing fails, treat as current time
        return 0;
      }
    });
    
    print('✅ Returning ${allDeclinedRequests.length} sorted declined requests');
    return allDeclinedRequests;
  }

  Widget _buildGuestRatingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange[50]!, Colors.orange[100]!],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.star_rate,
                  color: Colors.orange[600],
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guest Ratings & Reviews',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View all guest feedback and ratings for your services',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Ratings Statistics Section
        FutureBuilder<List<Map<String, dynamic>>>(
          key: ValueKey('guest_ratings_${_lastRefreshTime.millisecondsSinceEpoch}'),
          future: _getAllGuestRatings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Center(
                  child: Text(
                    'Error loading ratings: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                ),
              );
            }
            
            final ratings = snapshot.data ?? [];
            final stats = _calculateRatingStatistics(ratings);
            
            if (ratings.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.star_border,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Guest Ratings Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Guest ratings and reviews will appear here once services are completed and rated.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Overall Statistics Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Rating Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Overall Rating
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${stats['overall'].toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[600],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < stats['overall'].round()
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.orange[600],
                                        size: 20,
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Overall Rating',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${stats['count']} reviews',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _buildCategoryRating('Service Requests', stats['serviceRequests'], Icons.room_service, Colors.blue),
                                const SizedBox(height: 8),
                                _buildCategoryRating('Facility Bookings', stats['facilityBookings'], Icons.event_seat, Colors.green),
                                const SizedBox(height: 8),
                                _buildCategoryRating('Activity Bookings', stats['activityBookings'], Icons.sports, Colors.purple),
                                const SizedBox(height: 8),
                                _buildCategoryRating('Room Bookings', stats['roomBookings'], Icons.hotel, Colors.orange),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Individual Ratings List
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.rate_review, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Individual Guest Reviews',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ratings.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return _buildRatingCard(ratings[index]);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryRating(String title, double rating, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: color[600], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color[700],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      rating > 0 ? rating.toStringAsFixed(1) : 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color[600],
                      ),
                    ),
                    if (rating > 0) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.star, color: color[600], size: 12),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    final ratingType = rating['type'] ?? 'Service Request';
    final serviceType = rating['serviceType'] ?? rating['facilityName'] ?? rating['activityName'] ?? rating['roomType'] ?? 'Unknown Service';
    final ratingValue = (rating['rating'] ?? 0).toDouble();
    final feedback = rating['feedback'] ?? rating['comment'] ?? '';
    final requestId = rating['id'] ?? 'Unknown ID';
    final guestName = rating['guestName'] ?? rating['userName'] ?? 'Guest';
    
    // Format date
    String formatDate(dynamic dateValue) {
      if (dateValue == null) return 'Date not available';
      try {
        final date = DateTime.parse(dateValue.toString());
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return dateValue.toString();
      }
    }
    
    final ratingDate = formatDate(rating['ratingDate'] ?? rating['dateSubmitted'] ?? rating['bookingDate'] ?? rating['date']);
    
    // Get color based on rating type
    MaterialColor typeColor = Colors.blue;
    IconData typeIcon = Icons.room_service;
    
    switch (ratingType) {
      case 'Facility Booking':
        typeColor = Colors.green;
        typeIcon = Icons.event_seat;
        break;
      case 'Activity Booking':
        typeColor = Colors.purple;
        typeIcon = Icons.sports;
        break;
      case 'Room Booking':
        typeColor = Colors.orange;
        typeIcon = Icons.hotel;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: typeColor[600], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            serviceType,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeColor[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: typeColor[200]!),
                          ),
                          child: Text(
                            ratingType,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: typeColor[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          guestName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          ratingDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Rating Stars and Value
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < ratingValue.round() ? Icons.star : Icons.star_border,
                      color: Colors.orange[600],
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  '${ratingValue.toStringAsFixed(1)}/5.0',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          
          if (feedback.isNotEmpty && feedback.toLowerCase() != 'null' && feedback != 'No feedback provided') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Guest Feedback',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    feedback,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          
          // Request ID
          Text(
            'Request ID: #${requestId.substring(requestId.length > 8 ? requestId.length - 8 : 0)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: staffRole == 'admin' 
                  ? [Colors.red[50]!, Colors.red[100]!]
                  : [Colors.blue[50]!, Colors.blue[100]!],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: staffRole == 'admin' ? Colors.red[200]! : Colors.blue[200]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: staffRole == 'admin' ? Colors.red[100] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  staffRole == 'admin' ? Icons.admin_panel_settings : Icons.support_agent,
                  color: staffRole == 'admin' ? Colors.red[600] : Colors.blue[600],
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      staffName ?? 'Staff Member',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: staffRole == 'admin' ? Colors.red[800] : Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: staffRole == 'admin' ? Colors.red[600] : Colors.blue[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        staffRole == 'admin' ? 'ADMINISTRATOR' : 'STAFF MEMBER',
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
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Last refresh indicator
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Last updated: ${_formatLastRefreshTime()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // View Completed Service Requests Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.assignment_turned_in,
                color: Colors.green[600],
                size: 24,
              ),
            ),
            title: Text(
              'View Completed Service Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            subtitle: Text(
              'Review completed services and guest ratings',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/serviceRequest');
                  },
                  icon: Icon(
                    Icons.open_in_new,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  tooltip: 'View Full Service Request Page',
                ),
                const Icon(Icons.expand_more),
              ],
            ),
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                key: ValueKey('completed_requests_${_lastRefreshTime.millisecondsSinceEpoch}'),
                future: _getCompletedServiceRequests(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'Error loading service requests: ${snapshot.error}',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ),
                    );
                  }
                  
                  final requests = snapshot.data ?? [];
                  
                  if (requests.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No completed service requests yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Completed requests with guest ratings will appear here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: requests.map((request) => 
                      _buildServiceRequestCard(request)
                    ).toList(),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // View Ongoing Service Requests Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.pending_actions,
                color: Colors.orange[600],
                size: 24,
              ),
            ),
            title: Text(
              'Ongoing Service Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            subtitle: Text(
              'View and manage pending requests from guests',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                key: ValueKey('ongoing_requests_${_lastRefreshTime.millisecondsSinceEpoch}'),
                future: _getOngoingRequests(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'Error loading ongoing requests: ${snapshot.error}',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ),
                    );
                  }
                  
                  final requests = snapshot.data ?? [];
                  
                  if (requests.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.pending_actions_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No pending requests at the moment',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All guest requests are up to date!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: requests.map((request) => 
                      _buildOngoingRequestCard(request)
                    ).toList(),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // View Declined Service Requests Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.cancel,
                color: Colors.red[600],
                size: 24,
              ),
            ),
            title: Text(
              'Declined Service Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            subtitle: Text(
              'View all declined guest requests and bookings',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                key: ValueKey('declined_requests_${_lastRefreshTime.millisecondsSinceEpoch}'),
                future: _getDeclinedRequests(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'Error loading declined requests: ${snapshot.error}',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ),
                    );
                  }
                  
                  final requests = snapshot.data ?? [];
                  
                  if (requests.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.cancel_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No declined requests at the moment',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Declined guest requests will appear here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: requests.map((request) => 
                      _buildDeclinedRequestCard(request)
                    ).toList(),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildServiceRequestCard(Map<String, dynamic> request) {
    // Extract data with fallbacks for missing fields
    final requestType = request['type'] ?? 'Service Request';
    final serviceType = request['serviceType'] ?? request['facilityName'] ?? request['activityName'] ?? request['roomType'] ?? 'Unknown Service';
    final requestId = request['id'] ?? 'Unknown ID';
    
    // Helper function to safely format data with fallbacks
    String safeString(dynamic value, [String fallback = 'Available upon request']) {
      if (value == null) return fallback;
      final str = value.toString().trim();
      if (str.isEmpty || str.toLowerCase() == 'not specified' || str.toLowerCase() == 'null') {
        return fallback;
      }
      return str;
    }
    
    // Helper function to format date properly
    String formatDate(dynamic dateValue) {
      if (dateValue == null) return 'Contact resort for details';
      final dateStr = dateValue.toString();
      if (dateStr.isEmpty || dateStr.toLowerCase() == 'not specified') {
        return 'Contact resort for details';
      }
      try {
        final date = DateTime.parse(dateStr);
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return dateStr; // Return as-is if not parseable
      }
    }
    
    // Get details based on request type
    String details = '';
    switch (requestType) {
      case 'Service Request':
        details = safeString(request['details'], 'Service details available upon request');
        break;
      case 'Facility Booking':
        final facilityName = safeString(request['facilityName'], 'Resort Facility');
        final selectedDate = formatDate(request['selectedDate']);
        final selectedTime = safeString(request['selectedTime'], 'Flexible timing');
        final participants = safeString(request['participants'], 'As per booking');
        details = 'Facility: $facilityName\n'
                 'Date: $selectedDate\n'
                 'Time: $selectedTime\n'
                 'Participants: $participants';
        break;
      case 'Activity Booking':
        final activityName = safeString(request['activityName'], 'Resort Activity');
        final selectedDate = formatDate(request['selectedDate']);
        final selectedTime = safeString(request['selectedTime'], 'Flexible timing');
        final participants = safeString(request['participants'], 'As per booking');
        details = 'Activity: $activityName\n'
                 'Date: $selectedDate\n'
                 'Time: $selectedTime\n'
                 'Participants: $participants';
        break;
      case 'Room Booking':
        final roomType = safeString(request['roomType'], 'Resort Room');
        final checkInDate = formatDate(request['checkInDate']);
        final checkOutDate = formatDate(request['checkOutDate']);
        final guests = safeString(request['guests'], 'As per reservation');
        details = 'Room Type: $roomType\n'
                 'Check-in: $checkInDate\n'
                 'Check-out: $checkOutDate\n'
                 'Guests: $guests';
        break;
      default:
        details = safeString(request['details'], 'Service details available upon request');
        break;
    }
    
    // Format the display dates properly
    String displayDate = '';
    String submittedDate = '';
    
    // Get service/booking date (when the service is scheduled)
    final dateValue = request['selectedDate'] ?? request['checkInDate'] ?? request['date'] ?? request['dateCompleted'];
    if (dateValue != null) {
      displayDate = formatDate(dateValue);
    } else {
      displayDate = 'Contact resort for details';
    }
    
    // Get submitted date (when the request was made)
    final submittedDateValue = request['bookingDate'] ?? request['date'] ?? request['dateSubmitted'];
    if (submittedDateValue != null) {
      submittedDate = formatDate(submittedDateValue);
    } else {
      submittedDate = 'Contact resort for details';
    }
    
    final rating = request['rating']?.toDouble() ?? 0.0;
    final feedback = request['feedback'] ?? request['comment'] ?? '';
    final isOriginalBooking = request['originalBookingType'] != null;
    final confirmedBy = safeString(request['confirmedBy'], 'Resort Staff');
    
    // Determine status and color based on request type
    Color statusColor = Colors.green;
    String statusText = 'COMPLETED';
    
    if (isOriginalBooking) {
      statusColor = Colors.blue;
      statusText = 'APPROVED & CONFIRMED';
    } else if (requestType != 'Service Request') {
      statusColor = Colors.blue;
      statusText = 'CONFIRMED';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOriginalBooking ? 'Booking Type' : requestType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      serviceType,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Service/Booking Details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOriginalBooking ? Colors.blue[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isOriginalBooking ? Colors.blue[100]! : Colors.green[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOriginalBooking ? 'Booking Details' : '${requestType} Details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOriginalBooking ? Colors.blue[700] : Colors.green[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 14,
                    color: isOriginalBooking ? Colors.blue[800] : Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request ID',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '#${requestId.substring(requestId.length > 8 ? requestId.length - 8 : 0)}',
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
                      'Date Submitted',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      submittedDate,
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

          const SizedBox(height: 12),

          // Service/Booking date (when the service is scheduled)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requestType == 'Service Request' 
                          ? (isOriginalBooking ? 'Service Date' : 'Service Date')
                          : requestType == 'Room Booking' 
                            ? 'Check-in Date'
                            : 'Service Date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      displayDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 12),

          // Payment Details Section (for bookings with payment info)
          if (requestType != 'Service Request' && _hasPaymentInfo(request)) ...[
            Container(
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
                      Icon(
                        Icons.payment,
                        color: Colors.green[600],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Method:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              request['paymentMethod'] ?? 'Not specified',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
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
                              'Reference ID:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              request['referenceId'] ?? 'Not provided',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Amount:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _formatAmount(request['totalAmount']),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
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
                              'Payment Screenshot:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _viewPaymentScreenshot(request),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 12,
                                      color: Colors.blue[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'View Screenshot',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Show confirmed by staff info for bookings
          if (isOriginalBooking || requestType != 'Service Request') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: Colors.indigo[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Confirmed by: $confirmedBy',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.indigo[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Guest Rating Section (show for all booking types if rating exists)
          if (rating > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Guest Rating',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < rating.floor() 
                                ? Icons.star 
                                : (index < rating ? Icons.star_half : Icons.star_border),
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${rating.toStringAsFixed(1)}/5.0',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  if (feedback.isNotEmpty && feedback != 'No feedback provided' && feedback.toLowerCase() != 'null') ...[
                    const SizedBox(height: 8),
                    Text(
                      'Feedback: $feedback',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pending_actions,
                    color: Colors.orange[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    requestType == 'Service Request' 
                        ? 'Awaiting guest rating for service'
                        : 'Awaiting guest rating for booking',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
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

  Widget _buildOngoingRequestCard(Map<String, dynamic> request) {
    final requestType = request['type'] ?? 'Unknown Request';
    
    // Extract common data with fallbacks
    String title = '';
    String subtitle = '';
    String requestId = '';
    String submittedDate = '';
    Color typeColor = Colors.blue;
    IconData typeIcon = Icons.pending_actions;
    
    // Set data based on request type
    switch (requestType) {
      case 'Service Request':
        title = request['serviceType'] ?? 'Service Request';
        subtitle = request['details'] ?? 'No details provided';
        requestId = request['id'] ?? 'Unknown ID';
        submittedDate = request['dateSubmitted'] ?? request['date'] ?? DateTime.now().toString().split(' ')[0];
        typeColor = Colors.blue;
        typeIcon = Icons.room_service;
        break;
      case 'Facility Booking':
        title = request['facilityName'] ?? 'Facility Booking';
        subtitle = 'Time: ${request['selectedTime'] ?? 'Not specified'}';
        requestId = request['id'] ?? 'Unknown ID';
        submittedDate = request['dateSubmitted'] ?? request['bookingDate'] ?? DateTime.now().toString().split(' ')[0];
        typeColor = Colors.green;
        typeIcon = Icons.event_seat;
        break;
      case 'Activity Booking':
        title = request['activityName'] ?? 'Activity Booking';
        subtitle = 'Participants: ${request['participants'] ?? 'Not specified'}';
        requestId = request['id'] ?? 'Unknown ID';
        submittedDate = request['dateSubmitted'] ?? request['bookingDate'] ?? DateTime.now().toString().split(' ')[0];
        typeColor = Colors.purple;
        typeIcon = Icons.sports;
        break;
      case 'Room Booking':
        title = request['roomType'] ?? 'Room Booking';
        subtitle = 'Check-in: ${request['checkInDate'] ?? 'Not specified'}';
        requestId = request['id'] ?? 'Unknown ID';
        submittedDate = request['dateSubmitted'] ?? request['bookingDate'] ?? DateTime.now().toString().split(' ')[0];
        typeColor = Colors.orange;
        typeIcon = Icons.hotel;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            typeIcon,
                            color: typeColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            requestType,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PENDING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (subtitle.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: typeColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: typeColor.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request ID',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '#${requestId.length > 8 ? requestId.substring(requestId.length - 8) : requestId}',
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
                      'Date Submitted',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      submittedDate.split(' ')[0],
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
          
          // Payment Details Section (for ongoing bookings with payment info)
          if (requestType != 'Service Request' && _hasPaymentInfo(request)) ...[
            Container(
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
                      Icon(
                        Icons.payment,
                        color: Colors.green[600],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Payment Information',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Method: ${request['paymentMethod'] ?? 'Not specified'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green[700],
                              ),
                            ),
                            Text(
                              'Amount: ${_formatAmount(request['totalAmount'])}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _viewPaymentScreenshot(request),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.image,
                                size: 12,
                                color: Colors.blue[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Payment',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showServiceRequestDetails(request);
                  },
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: typeColor,
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
                child: OutlinedButton.icon(
                  onPressed: () {
                    _handleRequestAction(request);
                  },
                  icon: Icon(Icons.check_circle, size: 16),
                  label: Text('Quick Action'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: typeColor,
                    side: BorderSide(color: typeColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeclinedRequestCard(Map<String, dynamic> request) {
    final requestType = request['type'] ?? 'Unknown Request';
    
    // Extract common data with fallbacks
    String title = '';
    String subtitle = '';
    String requestId = '';
    String submittedDate = '';
    String declinedDate = '';
    String declinedBy = '';
    IconData typeIcon = Icons.cancel;
    
    // Set data based on request type
    switch (requestType) {
      case 'Service Request':
        title = request['serviceType'] ?? 'Service Request';
        subtitle = request['details'] ?? 'No details provided';
        requestId = request['id'] ?? 'Unknown ID';
        submittedDate = request['dateSubmitted'] ?? request['date'] ?? DateTime.now().toString().split(' ')[0];
        declinedDate = request['dateDeclined'] ?? DateTime.now().toString().split(' ')[0];
        declinedBy = request['declinedBy'] ?? 'Staff Member';
        typeIcon = Icons.room_service;
        break;
      case 'Facility Booking':
        title = request['facilityName'] ?? 'Facility Booking';
        subtitle = 'Time: ${request['selectedTime'] ?? 'Not specified'}';
        requestId = request['id'] ?? 'Unknown ID';
        submittedDate = request['dateSubmitted'] ?? request['bookingDate'] ?? DateTime.now().toString().split(' ')[0];
        declinedDate = request['dateDeclined'] ?? DateTime.now().toString().split(' ')[0];
        declinedBy = request['declinedBy'] ?? 'Staff Member';
        typeIcon = Icons.event_seat;
        break;
      case 'Activity Booking':
        title = request['activityName'] ?? 'Activity Booking';
        subtitle = 'Participants: ${request['participants'] ?? 'Not specified'}';
        requestId = request['id'] ?? 'Unknown ID';
        submittedDate = request['dateSubmitted'] ?? request['bookingDate'] ?? DateTime.now().toString().split(' ')[0];
        declinedDate = request['dateDeclined'] ?? DateTime.now().toString().split(' ')[0];
        declinedBy = request['declinedBy'] ?? 'Staff Member';
        typeIcon = Icons.sports;
        break;
      case 'Room Booking':
        title = request['roomType'] ?? 'Room Booking';
        subtitle = 'Check-in: ${request['checkInDate'] ?? 'Not specified'}';
        requestId = request['id'] ?? 'Unknown ID';
        submittedDate = request['dateSubmitted'] ?? request['bookingDate'] ?? DateTime.now().toString().split(' ')[0];
        declinedDate = request['dateDeclined'] ?? DateTime.now().toString().split(' ')[0];
        declinedBy = request['declinedBy'] ?? 'Staff Member';
        typeIcon = Icons.hotel;
        break;
    }
    
    // Helper function to format date
    String formatDate(String dateString) {
      try {
        final date = DateTime.parse(dateString);
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return dateString.split(' ')[0];
      }
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: Colors.red[600], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cancel,
                          color: Colors.red[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            requestType,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DECLINED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (subtitle.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[600],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request ID',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '#${requestId.length > 8 ? requestId.substring(requestId.length - 8) : requestId}',
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
                      'Date Submitted',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      formatDate(submittedDate),
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
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Declined',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[600],
                      ),
                    ),
                    Text(
                      formatDate(declinedDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
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
                      'Declined By',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[600],
                      ),
                    ),
                    Text(
                      declinedBy,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showServiceRequestDetails(request);
                  },
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
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
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showDeclineReasonDialog(request);
                  },
                  icon: Icon(Icons.info_outline, size: 16),
                  label: Text('Decline Reason'),
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
            ],
          ),
        ],
      ),
    );
  }

  void _showDeclineReasonDialog(Map<String, dynamic> request) {
    final requestType = request['type'] ?? 'Unknown Request';
    final declineReason = request['declineReason'] ?? 'No specific reason provided';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.red[600],
              ),
              const SizedBox(width: 8),
              Text('Decline Reason'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This $requestType was declined for the following reason:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  declineReason,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _handleRequestAction(Map<String, dynamic> request) {
    final requestType = request['type'] ?? 'Unknown Request';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green[600],
              ),
              const SizedBox(width: 8),
              Text('Quick Action'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What would you like to do with this $requestType?'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _approveRequest(request);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _declineRequest(request);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[600],
                        side: BorderSide(color: Colors.red[600]!),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _approveRequest(Map<String, dynamic> request) async {
    final requestType = request['type'] ?? 'Unknown Request';
    final requestId = request['id'] ?? 'Unknown ID';
    
    try {
      // Update the status based on request type
      if (requestType == 'Service Request') {
        await _updateServiceRequestStatus(requestId, 'Completed');
      } else if (requestType == 'Facility Booking') {
        await _updateBookingStatus('facility_bookings', requestId, 'Confirmed');
        await _moveBookingToCompleted(request, 'Facility Booking');
      } else if (requestType == 'Activity Booking') {
        await _updateBookingStatus('activity_bookings', requestId, 'Confirmed');
        await _moveBookingToCompleted(request, 'Activity Booking');
      } else if (requestType == 'Room Booking') {
        await _updateBookingStatus('room_bookings', requestId, 'Confirmed');
        await _moveBookingToCompleted(request, 'Room Booking');
      }
      
      // Notify the guest
      await _notifyGuest(request, 'approved');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$requestType approved and guest notified!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'REFRESH',
            textColor: Colors.white,
            onPressed: () {
              setState(() {}); // Refresh the UI to show updated data
            },
          ),
        ),
      );
      
      // Auto-refresh after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {});
        }
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving $requestType: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _declineRequest(Map<String, dynamic> request) async {
    final requestType = request['type'] ?? 'Unknown Request';
    
    // Show dialog to get decline reason
    final declineReason = await _showDeclineReasonInputDialog(requestType);
    
    if (declineReason == null) {
      // User canceled the dialog
      return;
    }
    
    final requestId = request['id'] ?? 'Unknown ID';
    
    try {
      // Update the request status to "declined" and add declined date with reason
      await _updateRequestStatus(requestId, 'declined', requestType, declineReason: declineReason);
      
      // Notify the guest about decline with reason
      await _notifyGuest(request, 'declined', declineReason: declineReason);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$requestType declined and moved to declined requests section.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              // Auto-refresh to show the updated lists
              _refreshDashboard();
            },
          ),
        ),
      );
      
      // Auto-refresh after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _refreshDashboard();
        }
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error declining $requestType: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<String?> _showDeclineReasonInputDialog(String requestType) async {
    final TextEditingController reasonController = TextEditingController();
    String? selectedReason;
    
    final List<String> commonReasons = [
      'Not available at requested time',
      'Facility/Service under maintenance',
      'Insufficient capacity',
      'Payment not verified',
      'Guest requirements not met',
      'Policy violation',
      'Other (specify below)',
    ];
    
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.cancel,
                    color: Colors.red[600],
                  ),
                  const SizedBox(width: 8),
                  Text('Decline $requestType'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please select or specify the reason for declining this request:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Common reasons dropdown
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReason,
                        hint: Text('Select a reason'),
                        isExpanded: true,
                        items: commonReasons.map((String reason) {
                          return DropdownMenuItem<String>(
                            value: reason,
                            child: Text(reason),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedReason = newValue;
                            if (newValue != 'Other (specify below)') {
                              reasonController.clear();
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Custom reason text field
                  if (selectedReason == 'Other (specify below)' || selectedReason == null) ...[
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        hintText: 'Enter specific reason...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    String reason = '';
                    if (selectedReason != null && selectedReason != 'Other (specify below)') {
                      reason = selectedReason!;
                    } else if (reasonController.text.trim().isNotEmpty) {
                      reason = reasonController.text.trim();
                    }
                    
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please provide a reason for declining'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.of(context).pop(reason);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Decline Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper method to update request status in SharedPreferences
  Future<void> _updateRequestStatus(String requestId, String status, String requestType, {String? declineReason}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Determine which list to update based on request type
    String listKey = '';
    switch (requestType) {
      case 'Service Request':
        listKey = 'service_requests';
        break;
      case 'Facility Booking':
        listKey = 'facility_bookings';
        break;
      case 'Activity Booking':
        listKey = 'activity_bookings';
        break;
      case 'Room Booking':
        listKey = 'room_bookings';
        break;
      default:
        listKey = 'service_requests';
        break;
    }
    
    // Get the current list
    final requestStrings = prefs.getStringList(listKey) ?? [];
    
    // Find and update the request
    List<String> updatedRequestStrings = [];
    bool found = false;
    
    for (String requestString in requestStrings) {
      final request = json.decode(requestString) as Map<String, dynamic>;
      
      if (request['id'] == requestId) {
        // Update the status and add declined date
        request['status'] = status;
        request['dateDeclined'] = DateTime.now().toIso8601String();
        request['declinedBy'] = staffName ?? 'Staff Member';
        
        // Add decline reason if provided
        if (declineReason != null) {
          request['declineReason'] = declineReason;
        }
        
        found = true;
        print('✅ Updated request $requestId status to $status');
      }
      
      updatedRequestStrings.add(json.encode(request));
    }
    
    if (found) {
      // Save the updated list
      await prefs.setStringList(listKey, updatedRequestStrings);
      print('💾 Saved updated $listKey list with ${updatedRequestStrings.length} items');
    } else {
      print('❌ Request $requestId not found in $listKey');
    }
  }

  Widget _buildStaffProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: staffRole == 'admin' ? Colors.red[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: staffRole == 'admin' ? Colors.red[100]! : Colors.blue[100]!,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: staffRole == 'admin' ? Colors.red[600] : Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    staffRole == 'admin' ? Icons.admin_panel_settings : Icons.support_agent,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  staffName ?? 'Staff Member',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: staffRole == 'admin' ? Colors.red[800] : Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  staffEmail ?? 'staff@resort.com',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: staffRole == 'admin' ? Colors.red[600] : Colors.blue[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    staffRole?.toUpperCase() ?? 'STAFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account Information Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
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
                    Icon(
                      Icons.account_circle,
                      color: staffRole == 'admin' ? Colors.red[600] : Colors.blue[600],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Account Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Staff ID
                _buildAccountInfoRow(
                  'Staff ID',
                  'STF${DateTime.now().year}${(staffName?.isNotEmpty == true ? staffName!.substring(0, (staffName!.length >= 2 ? 2 : staffName!.length)).toUpperCase() : 'ST')}${DateTime.now().millisecond.toString().padLeft(3, '0')}',
                  Icons.badge,
                ),
                const SizedBox(height: 12),
                
                // Department
                _buildAccountInfoRow(
                  'Department',
                  staffRole == 'admin' ? 'Administration' : 'Guest Services',
                  Icons.business,
                ),
                const SizedBox(height: 12),
                
                // Employment Type
                _buildAccountInfoRow(
                  'Employment Type',
                  'Full-time',
                  Icons.work,
                ),
                const SizedBox(height: 12),
                
                // Join Date
                _buildAccountInfoRow(
                  'Join Date',
                  'January 2024',
                  Icons.calendar_today,
                ),
                const SizedBox(height: 12),
                
                // Status
                _buildAccountInfoRow(
                  'Account Status',
                  'Active',
                  Icons.check_circle,
                  valueColor: Colors.green[600],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Profile Options
          _buildStaffProfileOption(
            icon: Icons.person_outline,
            title: 'Account Settings',
            subtitle: 'Manage your account details and preferences',
            onTap: () {
              _showAccountSettingsDialog();
            },
          ),
          const SizedBox(height: 12),
          
          _buildStaffProfileOption(
            icon: Icons.edit,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: () {
              _showEditProfileDialog();
            },
          ),
          const SizedBox(height: 12),
          
          _buildStaffProfileOption(
            icon: Icons.schedule,
            title: 'Work Schedule',
            subtitle: 'View and manage your work schedule',
            onTap: () {
              _showWorkScheduleDialog();
            },
          ),
          const SizedBox(height: 12),
          
          _buildStaffProfileOption(
            icon: Icons.assignment,
            title: 'My Tasks',
            subtitle: 'View assigned tasks and responsibilities',
            onTap: () {
              _showMyTasksDialog();
            },
          ),
          const SizedBox(height: 12),
          
          _buildStaffProfileOption(
            icon: Icons.analytics,
            title: 'Performance',
            subtitle: 'View your performance metrics',
            onTap: () {
              _showPerformanceDialog();
            },
          ),
          const SizedBox(height: 12),
          
          _buildStaffProfileOption(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings coming soon!')),
              );
            },
          ),
          const SizedBox(height: 12),
          
          _buildStaffProfileOption(
            icon: Icons.security,
            title: 'Security',
            subtitle: 'Change password and security settings',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security settings coming soon!')),
              );
            },
          ),
          const SizedBox(height: 12),
          
          if (staffRole == 'admin') ...[
            _buildStaffProfileOption(
              icon: Icons.settings,
              title: 'Admin Settings',
              subtitle: 'Manage system and user settings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin Settings feature coming soon!')),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          
          _buildStaffProfileOption(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support coming soon!')),
              );
            },
          ),
          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showStaffLogoutDialog();
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaffProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: staffRole == 'admin' ? Colors.red[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: staffRole == 'admin' ? Colors.red[600] : Colors.blue[600],
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showAccountSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.person_outline,
                color: staffRole == 'admin' ? Colors.red[600] : Colors.blue[600],
              ),
              const SizedBox(width: 8),
              const Text('Account Settings'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSettingOption('Change Password', Icons.lock_outline),
                const Divider(),
                _buildSettingOption('Two-Factor Authentication', Icons.security),
                const Divider(),
                _buildSettingOption('Email Notifications', Icons.email_outlined),
                const Divider(),
                _buildSettingOption('Privacy Settings', Icons.privacy_tip_outlined),
                const Divider(),
                _buildSettingOption('Account Recovery', Icons.restore),
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

  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: staffName);
    final TextEditingController emailController = TextEditingController(text: staffEmail);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  enabled: staffRole == 'admin',
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
              onPressed: () {
                // TODO: Save profile changes
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showWorkScheduleDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.schedule,
                color: staffRole == 'admin' ? Colors.red[600] : Colors.blue[600],
              ),
              const SizedBox(width: 8),
              const Text('Work Schedule'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current Week Schedule',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                _buildScheduleRow('Monday', '8:00 AM - 5:00 PM'),
                _buildScheduleRow('Tuesday', '8:00 AM - 5:00 PM'),
                _buildScheduleRow('Wednesday', '8:00 AM - 5:00 PM'),
                _buildScheduleRow('Thursday', '8:00 AM - 5:00 PM'),
                _buildScheduleRow('Friday', '8:00 AM - 5:00 PM'),
                _buildScheduleRow('Saturday', 'Off'),
                _buildScheduleRow('Sunday', 'Off'),
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

  void _showMyTasksDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.assignment,
                color: staffRole == 'admin' ? Colors.red[600] : Colors.blue[600],
              ),
              const SizedBox(width: 8),
              const Text('My Tasks'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTaskItem('Handle guest check-ins', 'High Priority', Colors.red),
                _buildTaskItem('Update room status', 'Medium Priority', Colors.orange),
                _buildTaskItem('Process service requests', 'High Priority', Colors.red),
                _buildTaskItem('Staff meeting at 2 PM', 'Low Priority', Colors.green),
                _buildTaskItem('Inventory check', 'Medium Priority', Colors.orange),
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

  // Helper method to check if a booking has payment information
  bool _hasPaymentInfo(Map<String, dynamic> request) {
    return request['paymentMethod'] != null ||
           request['referenceId'] != null ||
           request['totalAmount'] != null ||
           request['paymentScreenshot'] != null;
  }

  // Helper method to format payment amount
  String _formatAmount(dynamic amount) {
    if (amount == null) return 'Not specified';
    
    String amountStr = amount.toString();
    
    // If amount already has P prefix, return as is
    if (amountStr.startsWith('P') || amountStr.startsWith('₱')) {
      return amountStr;
    }
    
    // If amount is just a number, add P prefix
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(amountStr)) {
      return 'P$amountStr';
    }
    
    // For other formats, return as is
    return amountStr;
  }

  // Helper method to view payment screenshot
  void _viewPaymentScreenshot(Map<String, dynamic> request) {
    final screenshotPath = request['paymentScreenshot'];
    
    if (screenshotPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No payment screenshot available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.image, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text('Payment Screenshot'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Payment Screenshot Details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Payment Method: ${request['paymentMethod'] ?? 'Not specified'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reference ID: ${request['referenceId'] ?? 'Not provided'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Amount: ${_formatAmount(request['totalAmount'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.image, color: Colors.orange[600], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Screenshot file path: ${screenshotPath.toString().split('/').last}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Screenshot viewing functionality will be available in the full version of the application.',
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

  void _showPerformanceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.analytics,
                color: staffRole == 'admin' ? Colors.red[600] : Colors.blue[600],
              ),
              const SizedBox(width: 8),
              const Text('Performance Metrics'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPerformanceMetric('Tasks Completed', '45', '92%'),
                _buildPerformanceMetric('Guest Satisfaction', '4.8/5.0', '96%'),
                _buildPerformanceMetric('Response Time', '2.3 min', '88%'),
                _buildPerformanceMetric('Attendance', '98%', '98%'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Excellent performance this month!',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildSettingOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title feature coming soon!')),
        );
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildScheduleRow(String day, String time) {
    final bool isOff = time == 'Off';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            time,
            style: TextStyle(
              color: isOff ? Colors.grey[600] : Colors.grey[800],
              fontWeight: isOff ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String task, String priority, Color priorityColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  priority,
                  style: TextStyle(
                    fontSize: 12,
                    color: priorityColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String metric, String value, String percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showStaffLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pushReplacementNamed(context, '/signIn');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTicketsContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.indigo[50]!, Colors.indigo[100]!],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.indigo[200]!),
            ),
            child: MediaQuery.of(context).size.width < 600
                ? Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.indigo[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.confirmation_number,
                          color: Colors.indigo[600],
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Guest Support Tickets',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage guest support tickets and notify about status updates',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.indigo[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.confirmation_number,
                          color: Colors.indigo[600],
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guest Support Tickets',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage guest support tickets and notify about status updates',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ], // Fixed: Added missing closing bracket for Row
                  ),
          ),

          const SizedBox(height: 24),

          // Tickets Statistics
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getAllTickets(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Center(
                    child: Text(
                      'Error loading tickets: ${snapshot.error}',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ),
                );
              }
              
              final allTickets = snapshot.data ?? [];
              final pendingTickets = allTickets.where((ticket) => 
                ticket['status'] != 'Completed' && ticket['status'] != 'Confirmed').toList();
              final completedTickets = allTickets.where((ticket) => 
                ticket['status'] == 'Completed' || ticket['status'] == 'Confirmed').toList();
              
              if (allTickets.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.confirmation_number_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Support Tickets Yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Guest support tickets will appear here when submitted.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Statistics Overview
                  MediaQuery.of(context).size.width < 600
                      ? Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTicketStatCard(
                                    'Support Tickets',
                                    allTickets.length.toString(),
                                    Icons.confirmation_number,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTicketStatCard(
                                    'Pending',
                                    pendingTickets.length.toString(),
                                    Icons.pending_actions,
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: _buildTicketStatCard(
                                'Completed',
                                completedTickets.length.toString(),
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildTicketStatCard(
                                'Support Tickets',
                                allTickets.length.toString(),
                                Icons.confirmation_number,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTicketStatCard(
                                'Pending',
                                pendingTickets.length.toString(),
                                Icons.pending_actions,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTicketStatCard(
                                'Completed',
                                completedTickets.length.toString(),
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),

                  const SizedBox(height: 24),

                  // Pending Tickets Section
                  if (pendingTickets.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 20),
                            child: Row(
                              children: [
                                Icon(Icons.pending_actions, color: Colors.orange[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'Pending Support Tickets (${pendingTickets.length})',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pendingTickets.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              return _buildTicketCard(pendingTickets[index], isPending: true);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Completed Tickets Section
                  if (completedTickets.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 20),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'Completed Support Tickets (${completedTickets.length})',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: completedTickets.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              return _buildTicketCard(completedTickets[index], isPending: false);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Load only guest-submitted support tickets
  Future<List<Map<String, dynamic>>> _getAllTickets() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> allTickets = [];
    
    // Load guest-created support tickets (main tickets from CreateTicketScreen)
    final supportTicketStrings = prefs.getStringList('support_tickets') ?? [];
    final supportTickets = supportTicketStrings.map((str) {
      final ticket = json.decode(str) as Map<String, dynamic>;
      ticket['ticketType'] = 'Support Ticket';
      ticket['priority'] = _determinePriority(ticket);
      ticket['serviceType'] = ticket['subject'] ?? 'Support Request';
      ticket['guestName'] = ticket['email'] ?? 'Guest';
      ticket['details'] = ticket['issue'] ?? 'No details provided';
      ticket['dateSubmitted'] = ticket['submissionDate'] ?? DateTime.now().toString().split(' ')[0];
      return ticket;
    }).toList();
    
    // Add support tickets
    allTickets.addAll(supportTickets);
    
    // Sort by submission date (newest first)
    allTickets.sort((a, b) {
      try {
        String dateStringA = a['dateSubmitted'] ?? a['submissionDate'] ?? DateTime.now().toString();
        String dateStringB = b['dateSubmitted'] ?? b['submissionDate'] ?? DateTime.now().toString();
        
        DateTime dateA;
        DateTime dateB;
        
        try {
          dateA = DateTime.parse(dateStringA);
        } catch (e) {
          dateA = DateTime.now();
        }
        
        try {
          dateB = DateTime.parse(dateStringB);
        } catch (e) {
          dateB = DateTime.now();
        }
        
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });
    
    return allTickets;
  }

  String _determinePriority(Map<String, dynamic> ticket) {
    final ticketType = ticket['ticketType'] ?? ticket['type'] ?? '';
    
    // Handle support tickets priority
    if (ticketType == 'Support Ticket') {
      final priority = ticket['priority'] ?? '';
      if (priority.isNotEmpty) {
        return priority; // Use the priority set by the guest
      }
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
    
    // Default priority for any other ticket types
    return 'Medium';
  }

  Widget _buildTicketStatCard(String title, String count, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color[600], size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, {required bool isPending}) {
    final ticketType = ticket['ticketType'] ?? 'Support Ticket';
    final serviceType = ticket['serviceType'] ?? ticket['subject'] ?? 'Support Request';
    final ticketId = ticket['id'] ?? 'Unknown ID';
    final priority = ticket['priority'] ?? 'Medium';
    final guestName = ticket['guestName'] ?? ticket['email'] ?? 'Guest';
    final details = ticket['details'] ?? ticket['issue'] ?? 'No details provided';
    final contactNumber = ticket['contactNumber'] ?? 'Not provided';
    
    // Format date
    String formatDate(dynamic dateValue) {
      if (dateValue == null) return 'Date not available';
      try {
        final date = DateTime.parse(dateValue.toString());
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return dateValue.toString();
      }
    }
    
    final submittedDate = formatDate(ticket['dateSubmitted'] ?? ticket['submissionDate']);
    
    // Support ticket color and icon
    Color typeColor = Colors.indigo[600]!;
    IconData typeIcon = Icons.support_agent;
    
    // Get priority color
    Color priorityColor = Colors.green;
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
    }
    
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaQuery.of(context).size.width < 600
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(typeIcon, color: typeColor, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            serviceType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Guest: $guestName',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Submitted: $submittedDate',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPending ? Colors.orange[50] : Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPending ? Colors.orange[200]! : Colors.green[200]!,
                                ),
                              ),
                              child: Text(
                                ticketType,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isPending ? Colors.orange[700] : Colors.green[700],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '$priority Priority',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: priorityColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            serviceType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '$priority Priority',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: priorityColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          guestName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          submittedDate,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPending ? Colors.orange[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPending ? Colors.orange[200]! : Colors.green[200]!,
                        ),
                      ),
                      child: Text(
                        ticketType,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isPending ? Colors.orange[700] : Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Ticket Details
          if (ticket['details'] != null || ticket['specialRequirements'] != null || 
              ticket['additionalDetails'] != null || ticket['specialRequests'] != null ||
              ticket['issue'] != null || ticket['subject'] != null) ...[
            Container(
              width: double.infinity,
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
                    details,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (contactNumber != 'Not provided') ...[
                    Text(
                      'Contact: $contactNumber',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (guestName != 'Guest') ...[
                    Text(
                      'Email: $guestName',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Action buttons for pending tickets
          if (isPending) ...[
            MediaQuery.of(context).size.width < 600
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showTicketStatusDialog(ticket),
                          icon: const Icon(Icons.notifications, size: 18),
                          label: const Text('Notify Guest'),
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
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _markTicketAsCompleted(ticket),
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
                  )
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showTicketStatusDialog(ticket),
                          icon: const Icon(Icons.notifications, size: 18),
                          label: const Text('Notify Guest'),
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
                          onPressed: () => _markTicketAsCompleted(ticket),
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
          ] else ...[
            // Status for completed tickets
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
                    onPressed: () => _showTicketStatusDialog(ticket),
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
          
          const SizedBox(height: 8),
          
          // Ticket ID
          Text(
            'Ticket ID: #${ticketId.substring(ticketId.length > 8 ? ticketId.length - 8 : 0)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  void _showTicketStatusDialog(Map<String, dynamic> ticket) {
    final ticketType = ticket['ticketType'] ?? 'Support Ticket';
    final serviceType = ticket['serviceType'] ?? ticket['subject'] ?? 'Support Request';
    final guestName = ticket['guestName'] ?? ticket['email'] ?? 'Guest';
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
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Send status notification to $guestName about their $ticketType:',
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
                        'Ticket: $serviceType',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('ID: #${ticketId.substring(ticketId.length > 8 ? ticketId.length - 8 : 0)}'),
                      Text('Type: $ticketType'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Select notification type:'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendTicketNotification(ticket, 'In Progress', 'Your ticket is being processed by our staff.');
              },
              child: const Text('In Progress'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendTicketNotification(ticket, 'Under Review', 'Your ticket is under review and will be processed soon.');
              },
              child: const Text('Under Review'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendTicketNotification(ticket, 'Completed', 'Your ticket has been completed successfully!');
                _markTicketAsCompleted(ticket);
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

  void _markTicketAsCompleted(Map<String, dynamic> ticket) async {
    final ticketType = ticket['ticketType'] ?? 'Support Ticket';
    final ticketId = ticket['id'] ?? 'Unknown ID';
    
    try {
      // Update the support ticket status
      await _updateSupportTicketStatus(ticketId, 'Completed');
      
      // Send completion notification to guest
      await _sendTicketNotification(ticket, 'Completed', 'Your support ticket has been completed successfully!');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$ticketType marked as completed and guest notified!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'REFRESH',
            textColor: Colors.white,
            onPressed: () {
              setState(() {}); // Refresh the UI to show updated data
            },
          ),
        ),
      );
      
      // Auto-refresh after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {});
        }
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing $ticketType: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _sendTicketNotification(Map<String, dynamic> ticket, String status, String message) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('guest_notifications') ?? [];
    
    final ticketType = ticket['ticketType'] ?? ticket['type'] ?? 'Unknown';
    final serviceType = ticket['serviceType'] ?? ticket['facilityName'] ?? ticket['activityName'] ?? ticket['roomType'] ?? 'Unknown Service';
    final ticketId = ticket['id'] ?? 'Unknown ID';
    
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': '$ticketType Update - $status',
      'message': '$serviceType: $message',
      'ticketId': ticketId,
      'ticketType': ticketType,
      'status': status,
      'timestamp': DateTime.now().toString(),
      'isRead': false,
      'staffName': staffName ?? 'Resort Staff',
    };
    
    notifications.add(json.encode(notification));
    await prefs.setStringList('guest_notifications', notifications);
    
    // Show confirmation to staff
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification sent: $status - $serviceType'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildOtherContent(String title, String message) {
    // Special handling for Chat tab
    if (title == 'Chat') {
      // Navigate to StaffPanelScreen when Chat tab is selected
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const StaffPanelScreen(),
          ),
        ).then((_) {
          // Reset to Home tab when returning from chat
          setState(() {
            _selectedIndex = 0;
          });
        });
      });
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            title == 'Chat' ? Icons.chat : Icons.construction,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
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

  Future<void> _updateServiceRequestStatus(String requestId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final requestStrings = prefs.getStringList('service_requests') ?? [];
    
    // Find and update the specific request
    final updatedRequests = requestStrings.map((str) {
      final request = json.decode(str) as Map<String, dynamic>;
      if (request['id'] == requestId) {
        request['status'] = newStatus;
        if (newStatus == 'Completed') {
          request['dateCompleted'] = DateTime.now().toString().split(' ')[0];
        }
      }
      return json.encode(request);
    }).toList();
    
    // Save updated requests back to SharedPreferences
    await prefs.setStringList('service_requests', updatedRequests);
  }

  Future<void> _updateSupportTicketStatus(String ticketId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final ticketStrings = prefs.getStringList('support_tickets') ?? [];
    
    // Find and update the specific support ticket
    final updatedTickets = ticketStrings.map((str) {
      final ticket = json.decode(str) as Map<String, dynamic>;
      if (ticket['id'] == ticketId) {
        ticket['status'] = newStatus;
        if (newStatus == 'Completed') {
          ticket['dateCompleted'] = DateTime.now().toString().split(' ')[0];
          ticket['resolvedBy'] = staffName ?? 'Staff Member';
        }
      }
      return json.encode(ticket);
    }).toList();
    
    // Save updated tickets back to SharedPreferences
    await prefs.setStringList('support_tickets', updatedTickets);
  }

  // Update booking status in SharedPreferences
  Future<void> _updateBookingStatus(String storageKey, String bookingId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final bookingStrings = prefs.getStringList(storageKey) ?? [];
    
    // Find and update the specific booking
    final updatedBookings = bookingStrings.map((str) {
      final booking = json.decode(str) as Map<String, dynamic>;
      if (booking['id'] == bookingId) {
        booking['status'] = newStatus;
        booking['dateConfirmed'] = DateTime.now().toString().split(' ')[0];
        booking['confirmedBy'] = staffName ?? 'Staff Member';
      }
      return json.encode(booking);
    }).toList();
    
    // Save updated bookings back to SharedPreferences
    await prefs.setStringList(storageKey, updatedBookings);
  }

  // Move approved booking to completed service requests
  Future<void> _moveBookingToCompleted(Map<String, dynamic> booking, String bookingType) async {
    final prefs = await SharedPreferences.getInstance();
    final serviceRequestStrings = prefs.getStringList('service_requests') ?? [];
    
    // Create a new service request entry for the completed booking
    final completedBooking = {
      'id': booking['id'],
      'serviceType': bookingType,
      'details': _getBookingDetails(booking, bookingType),
      'date': booking['selectedDate'] ?? booking['checkInDate'] ?? booking['date'] ?? DateTime.now().toString().split(' ')[0],
      'status': 'Completed',
      'rated': false,
      'dateCompleted': DateTime.now().toString().split(' ')[0],
      'confirmedBy': staffName ?? 'Staff Member',
      'originalBookingType': bookingType,
    };
    
    serviceRequestStrings.add(json.encode(completedBooking));
    await prefs.setStringList('service_requests', serviceRequestStrings);
  }

  // Get booking details based on type
  String _getBookingDetails(Map<String, dynamic> booking, String bookingType) {
    switch (bookingType) {
      case 'Facility Booking':
        return 'Facility: ${booking['facilityName'] ?? 'Unknown'}\n'
               'Date: ${booking['selectedDate'] ?? 'Not specified'}\n'
               'Time: ${booking['selectedTime'] ?? 'Not specified'}\n'
               'Duration: ${booking['duration'] ?? 'Not specified'}\n'
               'Participants: ${booking['participants'] ?? 'Not specified'}';
      case 'Activity Booking':
        return 'Activity: ${booking['activityName'] ?? 'Unknown'}\n'
               'Date: ${booking['selectedDate'] ?? 'Not specified'}\n'
               'Time: ${booking['selectedTime'] ?? 'Not specified'}\n'
               'Participants: ${booking['participants'] ?? 'Not specified'}\n'
               'Special Requirements: ${booking['specialRequirements'] ?? 'None'}';
      case 'Room Booking':
        return 'Room Type: ${booking['roomType'] ?? 'Unknown'}\n'
               'Check-in: ${booking['checkInDate'] ?? 'Not specified'}\n'
               'Check-out: ${booking['checkOutDate'] ?? 'Not specified'}\n'
               'Guests: ${booking['guests'] ?? 'Not specified'}\n'
               'Special Requests: ${booking['specialRequests'] ?? 'None'}';
      default:
        return 'Booking details not available';
    }
  }

  // Notify guest about booking approval
  Future<void> _notifyGuest(Map<String, dynamic> request, String action, {String? declineReason}) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('guest_notifications') ?? [];
    
    final requestType = request['type'] ?? 'Unknown Request';
    final requestId = request['id'] ?? 'Unknown ID';
    
    // Create notification message
    String title = '';
    String message = '';
    
    if (action == 'approved') {
      title = '$requestType Approved! ✅';
      switch (requestType) {
        case 'Service Request':
          title = 'Service Request Completed! ✅';
          message = 'Your ${request['serviceType'] ?? 'service request'} has been completed by our staff. We hope you enjoyed our service!';
          break;
        case 'Facility Booking':
          message = 'Your booking for ${request['facilityName'] ?? 'the facility'} has been approved! Date: ${request['selectedDate'] ?? 'TBD'}, Time: ${request['selectedTime'] ?? 'TBD'}';
          break;
        case 'Activity Booking':
          message = 'Your booking for ${request['activityName'] ?? 'the activity'} has been approved! Date: ${request['selectedDate'] ?? 'TBD'}, Time: ${request['selectedTime'] ?? 'TBD'}';
          break;
        case 'Room Booking':
          message = 'Your ${request['roomType'] ?? 'room'} booking has been approved! Check-in: ${request['checkInDate'] ?? 'TBD'}';
          break;
      }
    } else if (action == 'declined') {
      title = '$requestType Declined ❌';
      
      // Create detailed decline message with reason
      String baseMessage = 'Unfortunately, your $requestType could not be processed at this time.';
      
      if (declineReason != null && declineReason.isNotEmpty) {
        message = '$baseMessage\n\nReason: $declineReason\n\nPlease contact our staff if you have any questions or would like to make alternative arrangements.';
      } else {
        message = '$baseMessage Please contact our staff for more information.';
      }
    }
    
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'requestId': requestId,
      'requestType': requestType,
      'timestamp': DateTime.now().toString(),
      'isRead': false,
      'action': action,
      'declineReason': declineReason, // Store decline reason in notification
    };
    
    notifications.add(json.encode(notification));
    await prefs.setStringList('guest_notifications', notifications);
    
    // Show local notification to staff
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Guest notification sent: $title'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showServiceRequestDetails(Map<String, dynamic> request) {
    final requestType = request['type'] ?? 'Service Request';
    
    // Determine colors and icons based on request type
    Color headerColor = Colors.blue[600]!;
    IconData headerIcon = Icons.room_service;
    String headerTitle = 'Service Request Details';
    
    switch (requestType) {
      case 'Facility Booking':
        headerColor = Colors.green[600]!;
        headerIcon = Icons.event_seat;
        headerTitle = 'Facility Booking Details';
        break;
      case 'Activity Booking':
        headerColor = Colors.purple[600]!;
        headerIcon = Icons.sports;
        headerTitle = 'Activity Booking Details';
        break;
      case 'Room Booking':
        headerColor = Colors.orange[600]!;
        headerIcon = Icons.hotel;
        headerTitle = 'Room Booking Details';
        break;
      case 'Service Request':
      default:
        headerColor = Colors.blue[600]!;
        headerIcon = Icons.room_service;
        headerTitle = 'Service Request Details';
        break;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: headerColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        headerIcon,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              headerTitle,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Request ID: #${request['id']?.substring((request['id']?.length ?? 8) > 8 ? (request['id']?.length ?? 8) - 8 : 0) ?? 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Request Type Specific Details
                        if (requestType == 'Service Request') ...[
                          _buildDetailRow(
                            'Service Type',
                            request['serviceType'] ?? 'Not specified',
                            Icons.room_service,
                            headerColor,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Date Requested',
                            request['date'] ?? 'Not specified',
                            Icons.calendar_today,
                            headerColor,
                          ),
                          const SizedBox(height: 16),
                          
                          // Service Details
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: headerColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: headerColor.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.description,
                                      color: headerColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Service Details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: headerColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  request['details'] ?? 'No details provided',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: headerColor.withValues(alpha: 0.8),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (requestType == 'Facility Booking') ...[
                          _buildDetailRow(
                            'Facility Name',
                            request['facilityName'] ?? 'Not specified',
                            Icons.event_seat,
                            headerColor,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Selected Date',
                            request['selectedDate'] ?? 'Not specified',
                            Icons.calendar_today,
                            headerColor,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Selected Time',
                            request['selectedTime'] ?? 'Not specified',
                            Icons.access_time,
                            headerColor,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Duration',
                            request['duration'] ?? 'Not specified',
                            Icons.timer,
                            headerColor,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Number of Participants',
                            (request['participants'] ?? 'Not specified').toString(),
                            Icons.group,
                            headerColor,
                          ),
                        ] else if (requestType == 'Activity Booking') ...[
                          _buildDetailRow(
                            'Activity Name',
                            request['activityName'] ?? 'Not specified',
                            Icons.sports,
                            headerColor,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Selected Date',
                            request['selectedDate'] ?? 'Not specified',
                            Icons.calendar_today,
                            headerColor,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Selected Time',
                            request['selectedTime'] ?? 'Not specified',
                            Icons.access_time,
                            headerColor,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Number of Participants',
                            (request['participants'] ?? 'Not specified').toString(),
                            Icons.group,
                            headerColor,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Special Requirements',
                            request['specialRequirements'] ?? 'None',
                            Icons.note_alt,
                            headerColor,
                          ),
                        ] else if (requestType == 'Room Booking') ...[
                          _buildDetailRow(
                            'Room Type',
                            request['roomType'] ?? 'Not specified',
                            Icons.hotel,
                            headerColor,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Check-in Date',
                            request['checkInDate'] ?? 'Not specified',
                            Icons.login,
                            headerColor,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Check-out Date',
                            request['checkOutDate'] ?? 'Not specified',
                            Icons.logout,
                            headerColor,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Number of Guests',
                            (request['guests'] ?? 'Not specified').toString(),
                            Icons.person,
                            headerColor,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Special Requests',
                            request['specialRequests'] ?? 'None',
                            Icons.note_alt,
                            headerColor,
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Status
                        _buildDetailRow(
                          'Current Status',
                          request['status'] ?? 'Pending',
                          Icons.info_outline,
                          request['status'] == 'Completed' || request['status'] == 'Confirmed' ? Colors.green : Colors.orange,
                        ),
                        
                        // Additional info if available
                        if (request['confirmedBy'] != null) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Confirmed By',
                            request['confirmedBy'],
                            Icons.verified_user,
                            Colors.indigo,
                          ),
                        ],
                        
                        if (request['dateCompleted'] != null) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Date Completed',
                            request['dateCompleted'],
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Images (if any) - for Service Requests
                        if (requestType == 'Service Request' && request['images'] != null && (request['images'] as List).isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.photo_library,
                                      color: Colors.grey[700],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Attached Images',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${(request['images'] as List).length} image(s) attached',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Rating (if completed and rated) - For ALL booking types
                        if (request['rating'] != null && request['rating'] > 0) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber[700],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Guest Rating',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < (request['rating']?.toDouble() ?? 0).floor() 
                                              ? Icons.star 
                                              : (index < (request['rating']?.toDouble() ?? 0) ? Icons.star_half : Icons.star_border),
                                          color: Colors.amber,
                                          size: 20,
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${request['rating']?.toStringAsFixed(1) ?? '0.0'}/5.0',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[700],
                                      ),
                                    ),
                                  ],
                                ),
                                if (request['feedback'] != null && request['feedback'].toString().isNotEmpty && request['feedback'] != 'No feedback provided') ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Feedback: ${request['feedback']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.amber[800],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ] else if (request['status'] == 'Completed' || request['status'] == 'Confirmed') ...[
                          // Show "Awaiting rating" for completed bookings without rating
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.pending_actions,
                                  color: Colors.orange[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  requestType == 'Service Request' 
                                      ? 'Awaiting guest rating for service'
                                      : 'Awaiting guest rating for booking',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (request['status'] != 'Completed' && request['status'] != 'Confirmed') ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _approveRequest(request);
                            },
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: Text(requestType == 'Service Request' ? 'Complete' : 'Approve'),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _declineRequest(request);
                            },
                            icon: const Icon(Icons.cancel, size: 18),
                            label: const Text('Decline'),
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
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: Text(requestType == 'Service Request' ? 'Request Completed' : 'Booking Confirmed'),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        title: Row(
          children: [
            Icon(
              staffRole == 'admin' ? Icons.admin_panel_settings : Icons.support_agent,
              color: staffRole == 'admin' ? Colors.red[600] : Colors.blue[600],
              size: 28,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staffRole == 'admin' ? 'Admin Dashboard' : 'Staff Dashboard',
                  style: TextStyle(
                    color: staffRole == 'admin' ? Colors.red[800] : Colors.blue[800],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'GloryMar Vista Beach Resort',
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
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.blue[600],
            ),
            onPressed: _refreshDashboard,
            tooltip: 'Refresh Dashboard',
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.red[600],
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pushReplacementNamed(context, '/signIn');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: _selectedIndex == 0 
              ? _buildHomeContent()
              : _selectedIndex == 1
                  ? _buildGuestRatingsContent()
                  : _selectedIndex == 2
                      ? _buildTicketsContent()
                      : _selectedIndex == 3
                          ? _buildOtherContent('Chat', 'Opening chat panel...')
                          : _buildStaffProfileContent(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: staffRole == 'admin' ? Colors.red[600] : Colors.blue[600],
        unselectedItemColor: Colors.grey[500],
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_rate),
            label: 'Guests Ratings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
