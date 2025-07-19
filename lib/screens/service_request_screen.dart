import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/notification_helper.dart';

class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({Key? key}) : super(key: key);

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Form variables
  String? _selectedServiceType;
  final TextEditingController _requestDetailsController = TextEditingController();
  List<String> _uploadedImages = [];
  
  // Service types
  final List<Map<String, dynamic>> _serviceTypes = [
    {'name': 'Room Service', 'icon': Icons.room_service},
    {'name': 'Housekeeping', 'icon': Icons.cleaning_services},
    {'name': 'Maintenance', 'icon': Icons.build},
    {'name': 'Spa Booking', 'icon': Icons.spa},
    {'name': 'Restaurant Reservation', 'icon': Icons.restaurant},
    {'name': 'Laundry Service', 'icon': Icons.local_laundry_service},
    {'name': 'Concierge', 'icon': Icons.support_agent},
    {'name': 'Transportation', 'icon': Icons.directions_car},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _requestDetailsController.dispose();
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
          'Service Requests',
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
            Tab(text: 'New Request'),
            Tab(text: 'My Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewRequestTab(),
          _buildMyRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildNewRequestTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Type Selection
            Text(
              'Service Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 12),
            _buildServiceTypeGrid(),
            const SizedBox(height: 24),

            // Request Details
            Text(
              'Request Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _requestDetailsController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Please describe your service request in detail...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Image Upload Section
            Text(
              'Upload Images (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 12),
            _buildImageUploadSection(),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Submit Request',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: _serviceTypes.length,
      itemBuilder: (context, index) {
        final service = _serviceTypes[index];
        final isSelected = _selectedServiceType == service['name'];
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedServiceType = service['name'];
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  service['icon'],
                  color: isSelected ? Colors.blue[600] : Colors.grey[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    service['name'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.blue[600] : Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        // Upload button
        GestureDetector(
          onTap: _addImage,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
              color: Colors.grey[50],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to upload images',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                Text(
                  'JPG, PNG files accepted',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Display uploaded images
        if (_uploadedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _uploadedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: const Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMyRequestsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadServiceRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final requests = snapshot.data ?? [];
        
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No service requests yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your submitted requests will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(requests[index], index);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    final status = request['status'] ?? 'Pending';
    final statusColor = _getStatusColor(status);
    final completedBy = request['completedBy'] ?? '';
    
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
          // Header with service type and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request['serviceType'] ?? 'Unknown Service',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Request details
          Text(
            request['details'] ?? 'No details provided',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Request date
          Text(
            'Submitted: ${request['date'] ?? 'Unknown date'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          
          // Show completion info if completed by admin
          if (status == 'Completed' && completedBy.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Completed by: $completedBy on ${request['completionDate'] ?? 'Unknown date'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          
          // Action buttons based on status
          const SizedBox(height: 12),
          if (status == 'Pending') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Submitted',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.orange[800],
                          ),
                        ),
                        Text(
                          'Waiting for staff to start the service',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (status == 'In Progress') ...[
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
                  Icon(Icons.hourglass_empty, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service in Progress',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[800],
                          ),
                        ),
                        Text(
                          'Waiting for staff to complete the service',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (status == 'Completed' && !(request['rated'] ?? false)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Service completed by staff. You can now rate your experience!',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green[800],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showRatingDialog(index, request),
                icon: const Icon(Icons.star, size: 18),
                label: const Text('Rate Your Experience'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ] else if (status == 'Completed' && (request['rated'] ?? false)) ...[
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
                  Icon(Icons.verified, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Service completed and rated',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Show rating if already rated
          if (request['rated'] ?? false) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Your Rating: '),
                ...List.generate(5, (i) {
                  return Icon(
                    i < (request['rating'] ?? 0) ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${request['rating']}/5',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (request['staffRating'] != null) ...[
                  const SizedBox(width: 16),
                  const Text('Staff: '),
                  ...List.generate(5, (i) {
                    return Icon(
                      i < (request['staffRating'] ?? 0) ? Icons.star : Icons.star_border,
                      color: Colors.blue,
                      size: 16,
                    );
                  }),
                  const SizedBox(width: 4),
                  Text(
                    '${request['staffRating']}/5',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _addImage() {
    // Simulate image upload
    setState(() {
      _uploadedImages.add('image_${_uploadedImages.length + 1}.jpg');
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _uploadedImages.removeAt(index);
    });
  }

  Future<void> _submitRequest() async {
    if (_selectedServiceType == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a service type'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_requestDetailsController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide request details'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Save request to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final existingRequests = prefs.getStringList('service_requests') ?? [];
    
    final newRequest = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'serviceType': _selectedServiceType,
      'details': _requestDetailsController.text.trim(),
      'images': _uploadedImages,
      'date': DateTime.now().toString().split(' ')[0], // Service date (same as submitted for service requests)
      'dateSubmitted': DateTime.now().toString().split(' ')[0], // Date when request was submitted
      'status': 'Pending',
      'rated': false,
    };
    
    existingRequests.add(json.encode(newRequest));
    await prefs.setStringList('service_requests', existingRequests);

    // Get user name for notification
    final userName = prefs.getString('user_name') ?? 'Guest';
    
    // Send service request notification
    await NotificationHelper.sendServiceRequestNotification(
      serviceType: _selectedServiceType!,
      requestId: newRequest['id'] as String,
      customerName: userName,
      message: 'Your service request has been submitted and is pending review.',
      status: 'Pending',
    );

    // Reset form
    setState(() {
      _selectedServiceType = null;
      _requestDetailsController.clear();
      _uploadedImages.clear();
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service request submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Switch to My Requests tab
      _tabController.animateTo(1);
    }
  }

  Future<List<Map<String, dynamic>>> _loadServiceRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final requestStrings = prefs.getStringList('service_requests') ?? [];
    
    return requestStrings.map((str) {
      final request = json.decode(str) as Map<String, dynamic>;
      return request;
    }).toList();
  }

  void _showRatingDialog(int requestIndex, Map<String, dynamic> request) {
    int selectedRating = 0;
    int selectedStaffRating = 0;
    final TextEditingController commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rate Your Experience'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rate the Service Quality:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedRating = index + 1;
                            });
                          },
                          child: Icon(
                            index < selectedRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Rate the Staff Service:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedStaffRating = index + 1;
                            });
                          },
                          child: Icon(
                            index < selectedStaffRating ? Icons.star : Icons.star_border,
                            color: Colors.blue,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Additional Comments (Optional):',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: commentController,
                        maxLines: 3,
                        maxLength: 500,
                        onChanged: (value) {
                          setDialogState(() {}); // Update character counter
                        },
                        decoration: const InputDecoration(
                          hintText: 'Share your feedback about the service...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                          counterText: '', // Hide default character counter
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${commentController.text.length}/500 characters',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
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
                  onPressed: selectedRating > 0 && selectedStaffRating > 0
                      ? () async {
                          await _saveRating(
                            requestIndex, 
                            selectedRating, 
                            selectedStaffRating,
                            commentController.text.trim(),
                          );
                          if (mounted) {
                            Navigator.of(context).pop();
                            setState(() {}); // Refresh the requests list
                          }
                        }
                      : null,
                  child: const Text('Submit Rating'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveRating(int requestIndex, int serviceRating, int staffRating, [String? comment]) async {
    final prefs = await SharedPreferences.getInstance();
    final requestStrings = prefs.getStringList('service_requests') ?? [];
    
    if (requestIndex < requestStrings.length) {
      final request = json.decode(requestStrings[requestIndex]) as Map<String, dynamic>;
      request['rated'] = true;
      request['rating'] = serviceRating;
      request['staffRating'] = staffRating;
      request['ratingDate'] = DateTime.now().toString().split(' ')[0];
      
      // Save the comment if provided
      if (comment != null && comment.isNotEmpty) {
        request['feedback'] = comment;
        request['comment'] = comment; // Also save as 'comment' for backward compatibility
      }
      
      requestStrings[requestIndex] = json.encode(request);
      await prefs.setStringList('service_requests', requestStrings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              comment != null && comment.isNotEmpty 
                  ? 'Thank you for your rating and feedback! Your comments help us improve our service.'
                  : 'Thank you for your rating! Your feedback helps us improve our service.'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
