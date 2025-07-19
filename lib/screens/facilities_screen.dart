import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'room_view_screen.dart';
import '../helpers/notification_helper.dart';

class FacilitiesScreen extends StatefulWidget {
  const FacilitiesScreen({Key? key}) : super(key: key);

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Booking form variables
  String? _selectedFacilityType;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;
  int _numberOfPax = 1; // For cottages booking
  final TextEditingController _notesController = TextEditingController();

  // Payment variables
  String? _selectedPaymentMethod;
  final TextEditingController _referenceIdController = TextEditingController();
  XFile? _paymentScreenshot;
  final ImagePicker _picker = ImagePicker();

  // Available facilities
  final List<Map<String, dynamic>> _facilities = [
    {
      'name': 'Swimming Pool',
      'icon': Icons.pool,
      'description': 'Olympic-size swimming pool with crystal clear water and poolside amenities',
      'price': 'P200/hour',
      'availability': 'Available 6:00 AM - 10:00 PM',
    },
    {
      'name': 'Restaurant',
      'icon': Icons.restaurant,
      'description': 'Fine dining restaurant featuring local and international cuisine',
      'price': 'Table reservation free',
      'availability': 'Available 6:00 AM - 12:00 AM',
    },
    {
      'name': 'Spa',
      'icon': Icons.spa,
      'description': 'Luxurious spa offering relaxing treatments and wellness services',
      'price': 'P800/session',
      'availability': 'Available 9:00 AM - 8:00 PM',
    },
    {
      'name': 'Cottages',
      'icon': Icons.cabin,
      'description': 'Private cottages with scenic views perfect for families and groups',
      'price': 'P1,500/day',
      'availability': 'Available 24/7',
    },
    {
      'name': 'Room',
      'icon': Icons.hotel,
      'description': 'Comfortable rooms with modern amenities for overnight stays',
      'price': 'Starting from P2,500/night',
      'availability': 'Available 24/7',
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
    _notesController.dispose();
    _referenceIdController.dispose();
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
          'Resort Facilities',
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
            Tab(text: 'View Facilities'),
            Tab(text: 'Book Facility'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildViewFacilitiesTab(),
          _buildBookFacilityTab(),
        ],
      ),
    );
  }

  Widget _buildViewFacilitiesTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Facilities',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover all the amazing facilities our resort has to offer',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _facilities.length,
              itemBuilder: (context, index) {
                return _buildFacilityCard(_facilities[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityCard(Map<String, dynamic> facility) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              facility['icon'],
              color: Colors.blue[600],
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facility['name'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  facility['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        facility['availability'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  facility['price'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: facility['name'] == 'Restaurant' ? null : () {
              if (facility['name'] == 'Room') {
                // Navigate to room view screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoomViewScreen(),
                  ),
                );
              } else {
                setState(() {
                  _selectedFacilityType = facility['name'];
                });
                _tabController.animateTo(1);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: facility['name'] == 'Restaurant' ? Colors.grey[400] : Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              facility['name'] == 'Room' ? 'View Rooms' : 
              facility['name'] == 'Restaurant' ? 'Coming Soon...' : 'Book',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookFacilityTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book a Facility',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select your preferred facility and schedule',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Facility Type Selection
            Text(
              'Facility Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFacilityType,
                  hint: const Text('Select a facility'),
                  isExpanded: true,
                  items: _facilities.where((facility) => 
                    facility['name'] != 'Room' && facility['name'] != 'Restaurant'
                  ).map((facility) {
                    return DropdownMenuItem<String>(
                      value: facility['name'],
                      child: Row(
                        children: [
                          Icon(facility['icon'], size: 20, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(facility['name']),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFacilityType = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Conditional form fields based on facility type
            if (_selectedFacilityType == 'Swimming Pool') ...[
              // Date Selection for Swimming Pool
              Text(
                'Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectCheckInDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Text(
                        _checkInDate != null
                            ? '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}'
                            : 'Select date',
                        style: TextStyle(
                          fontSize: 16,
                          color: _checkInDate != null ? Colors.black : Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Check-in Time Selection for Swimming Pool
              Text(
                'Check-in Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectCheckInTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Text(
                        _checkInTime != null
                            ? _checkInTime!.format(context)
                            : 'Select check-in time',
                        style: TextStyle(
                          fontSize: 16,
                          color: _checkInTime != null ? Colors.black : Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Check-out Time Selection for Swimming Pool
              Text(
                'Check-out Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectCheckOutTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Text(
                        _checkOutTime != null
                            ? _checkOutTime!.format(context)
                            : 'Select check-out time',
                        style: TextStyle(
                          fontSize: 16,
                          color: _checkOutTime != null ? Colors.black : Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
            ] else if (_selectedFacilityType == 'Spa') ...[
              // Spa booking - only check-in date and time
              Text(
                'Check-in Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectCheckInDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Text(
                        _checkInDate != null
                            ? '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}'
                            : 'Select check-in date',
                        style: TextStyle(
                          fontSize: 16,
                          color: _checkInDate != null ? Colors.black : Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Time Selection for Spa
              Text(
                'Preferred Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Text(
                        _checkInTime != null
                            ? _checkInTime!.format(context)
                            : 'Select preferred time',
                        style: TextStyle(
                          fontSize: 16,
                          color: _checkInTime != null ? Colors.black : Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
            ] else if (_selectedFacilityType == 'Cottages') ...[
              // Cottages booking - check-in/out dates, time, number of pax
              Text(
                'Check-in Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectCheckInDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Text(
                        _checkInDate != null
                            ? '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}'
                            : 'Select check-in date',
                        style: TextStyle(
                          fontSize: 16,
                          color: _checkInDate != null ? Colors.black : Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Check-out Date Selection for Cottages
              Text(
                'Check-out Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectCheckOutDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Text(
                        _checkOutDate != null
                            ? '${_checkOutDate!.day}/${_checkOutDate!.month}/${_checkOutDate!.year}'
                            : 'Select check-out date',
                        style: TextStyle(
                          fontSize: 16,
                          color: _checkOutDate != null ? Colors.black : Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Time Selection for Cottages
              Text(
                'Check-in Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Text(
                        _checkInTime != null
                            ? _checkInTime!.format(context)
                            : 'Select check-in time',
                        style: TextStyle(
                          fontSize: 16,
                          color: _checkInTime != null ? Colors.black : Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Number of Pax Selection for Cottages
              Text(
                'Number of Pax',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Number of guests',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _numberOfPax > 1 ? () {
                            setState(() {
                              _numberOfPax--;
                            });
                          } : null,
                          icon: Icon(Icons.remove_circle_outline, 
                            color: _numberOfPax > 1 ? Colors.blue[600] : Colors.grey[400]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_numberOfPax',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _numberOfPax < 20 ? () {
                            setState(() {
                              _numberOfPax++;
                            });
                          } : null,
                          icon: Icon(Icons.add_circle_outline, 
                            color: _numberOfPax < 20 ? Colors.blue[600] : Colors.grey[400]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // This case should never be reached now with Restaurant removed
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Please select a facility type to continue',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Additional Notes
            Text(
              'Additional Notes (Optional)',
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
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Any special requests or notes...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Payment Section
            Text(
              'Payment Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 12),
            
            // Payment Method Selection
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: InputDecoration(
                hintText: 'Select payment method',
                prefixIcon: Icon(Icons.payment, color: Colors.blue[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue[600]!),
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
                  _selectedPaymentMethod = value;
                });
              },
            ),
            const SizedBox(height: 12),

            // Payment Details
            if (_selectedPaymentMethod != null) ...[
              // Payment Instructions
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
                      _selectedPaymentMethod == 'GCash'
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
              TextFormField(
                controller: _referenceIdController,
                decoration: InputDecoration(
                  hintText: 'Enter payment reference ID',
                  prefixIcon: Icon(Icons.receipt, color: Colors.blue[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue[600]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),

              // Payment Screenshot Upload
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Screenshot',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickPaymentScreenshot,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            Text(
                              _paymentScreenshot != null ? 'Screenshot Selected' : 'Upload Screenshot',
                              style: TextStyle(
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
              const SizedBox(height: 32),
            ],

            // Booking Summary
            if (_shouldShowBookingSummary()) ...[
              _buildBookingSummary(),
              const SizedBox(height: 24),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Submit Booking',
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

  Future<void> _selectCheckInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _checkInDate) {
      setState(() {
        _checkInDate = picked;
        // Reset check-out date if it's before the new check-in date
        if (_checkOutDate != null && _checkOutDate!.isBefore(picked)) {
          _checkOutDate = null;
        }
      });
    }
  }

  Future<void> _selectCheckOutDate() async {
    if (_checkInDate == null) {
      _showSnackBar('Please select check-in date first', Colors.red);
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate!.add(const Duration(days: 1)),
      firstDate: _checkInDate!.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _checkOutDate) {
      setState(() {
        _checkOutDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _checkInTime) {
      setState(() {
        _checkInTime = picked;
      });
    }
  }

  Future<void> _selectCheckInTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _checkInTime) {
      setState(() {
        _checkInTime = picked;
        // Reset check-out time if it's before the new check-in time
        if (_checkOutTime != null && _isTimeAfter(_checkOutTime!, picked)) {
          _checkOutTime = null;
        }
      });
    }
  }

  Future<void> _selectCheckOutTime() async {
    if (_checkInTime == null) {
      _showSnackBar('Please select check-in time first', Colors.red);
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _checkInTime!.hour + 1 < 24 ? _checkInTime!.hour + 1 : 23,
        minute: _checkInTime!.minute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Validate that check-out time is after check-in time
      if (_isTimeAfter(picked, _checkInTime!)) {
        setState(() {
          _checkOutTime = picked;
        });
      } else {
        _showSnackBar('Check-out time must be after check-in time', Colors.red);
      }
    }
  }

  bool _isTimeAfter(TimeOfDay checkTime, TimeOfDay referenceTime) {
    final checkMinutes = checkTime.hour * 60 + checkTime.minute;
    final referenceMinutes = referenceTime.hour * 60 + referenceTime.minute;
    return checkMinutes > referenceMinutes;
  }

  Future<void> _pickPaymentScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _paymentScreenshot = image;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', Colors.red);
    }
  }

  bool _shouldShowBookingSummary() {
    if (_selectedFacilityType == null) return false;
    
    // Show summary for different facility types with their specific requirements
    switch (_selectedFacilityType) {
      case 'Swimming Pool':
        return _checkInDate != null && _checkInTime != null && _checkOutTime != null;
      case 'Spa':
        return _checkInDate != null && _checkInTime != null;
      case 'Cottages':
        return _checkInDate != null && _checkOutDate != null && _checkInTime != null;
      default:
        return false;
    }
  }

  Widget _buildBookingSummary() {
    if (_selectedFacilityType == null) return const SizedBox.shrink();

    // Get facility details
    final facility = _facilities.firstWhere(
      (f) => f['name'] == _selectedFacilityType,
      orElse: () => {},
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.blue[100]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Colors.blue[700],
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Booking Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Facility Information
          _buildSummaryRow(
            icon: facility['icon'] ?? Icons.business,
            label: 'Facility',
            value: _selectedFacilityType!,
            isHeader: true,
          ),
          const SizedBox(height: 12),
          
          // Date Information
          if (_selectedFacilityType == 'Swimming Pool') ...[
            _buildSummaryRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: _checkInDate != null 
                  ? '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}'
                  : 'Not selected',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              icon: Icons.access_time,
              label: 'Time Slot',
              value: _checkInTime != null && _checkOutTime != null
                  ? '${_checkInTime!.format(context)} - ${_checkOutTime!.format(context)}'
                  : 'Not selected',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              icon: Icons.schedule,
              label: 'Duration',
              value: _calculateDuration(),
            ),
          ] else if (_selectedFacilityType == 'Spa') ...[
            _buildSummaryRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: _checkInDate != null 
                  ? '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}'
                  : 'Not selected',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              icon: Icons.access_time,
              label: 'Preferred Time',
              value: _checkInTime != null 
                  ? _checkInTime!.format(context)
                  : 'Not selected',
            ),
          ] else if (_selectedFacilityType == 'Cottages') ...[
            _buildSummaryRow(
              icon: Icons.calendar_today,
              label: 'Check-in Date',
              value: _checkInDate != null 
                  ? '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}'
                  : 'Not selected',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              icon: Icons.calendar_month,
              label: 'Check-out Date',
              value: _checkOutDate != null 
                  ? '${_checkOutDate!.day}/${_checkOutDate!.month}/${_checkOutDate!.year}'
                  : 'Not selected',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              icon: Icons.access_time,
              label: 'Check-in Time',
              value: _checkInTime != null 
                  ? _checkInTime!.format(context)
                  : 'Not selected',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              icon: Icons.people,
              label: 'Number of Pax',
              value: '$_numberOfPax ${_numberOfPax == 1 ? 'person' : 'people'}',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              icon: Icons.nights_stay,
              label: 'Duration',
              value: _checkInDate != null && _checkOutDate != null
                  ? '${_checkOutDate!.difference(_checkInDate!).inDays} day(s)'
                  : 'Not calculated',
            ),
          ] else ...[
            _buildSummaryRow(
              icon: Icons.calendar_today,
              label: 'Check-in Date',
              value: _checkInDate != null 
                  ? '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}'
                  : 'Not selected',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              icon: Icons.calendar_month,
              label: 'Check-out Date',
              value: _checkOutDate != null 
                  ? '${_checkOutDate!.day}/${_checkOutDate!.month}/${_checkOutDate!.year}'
                  : 'Not selected',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              icon: Icons.nights_stay,
              label: 'Duration',
              value: _checkInDate != null && _checkOutDate != null
                  ? '${_checkOutDate!.difference(_checkInDate!).inDays} day(s)'
                  : 'Not calculated',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              icon: Icons.access_time,
              label: 'Time',
              value: _checkInTime != null 
                  ? _checkInTime!.format(context)
                  : 'Not selected',
            ),
          ],
          
          const SizedBox(height: 8),
          _buildSummaryRow(
            icon: Icons.attach_money,
            label: 'Price',
            value: facility['price'] ?? 'N/A',
          ),
          
          const SizedBox(height: 8),
          _buildSummaryRow(
            icon: Icons.receipt,
            label: 'Total Bill',
            value: _calculateTotalBill(),
            isHeader: true,
          ),
          
          if (_notesController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              icon: Icons.note,
              label: 'Notes',
              value: _notesController.text.trim(),
              isMultiline: true,
            ),
          ],
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your booking will be pending until approved by our staff.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHeader = false,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isHeader ? Colors.blue[700] : Colors.blue[600],
          size: isHeader ? 24 : 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isHeader ? 16 : 14,
                  fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isHeader ? 18 : 16,
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.w600,
                  color: isHeader ? Colors.blue[800] : Colors.grey[800],
                ),
                maxLines: isMultiline ? null : 1,
                overflow: isMultiline ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _calculateDuration() {
    if (_checkInTime == null || _checkOutTime == null) return 'Not calculated';
    
    final checkInMinutes = _checkInTime!.hour * 60 + _checkInTime!.minute;
    final checkOutMinutes = _checkOutTime!.hour * 60 + _checkOutTime!.minute;
    final durationMinutes = checkOutMinutes - checkInMinutes;
    
    if (durationMinutes <= 0) return 'Invalid duration';
    
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '$hours hour(s) $minutes minute(s)';
    } else if (hours > 0) {
      return '$hours hour(s)';
    } else {
      return '$minutes minute(s)';
    }
  }

  String _calculateTotalBill() {
    if (_selectedFacilityType == null) return 'P0.00';

    double totalAmount = 0.0;

    switch (_selectedFacilityType) {
      case 'Swimming Pool':
        if (_checkInTime != null && _checkOutTime != null) {
          final checkInMinutes = _checkInTime!.hour * 60 + _checkInTime!.minute;
          final checkOutMinutes = _checkOutTime!.hour * 60 + _checkOutTime!.minute;
          final durationMinutes = checkOutMinutes - checkInMinutes;
          
          if (durationMinutes > 0) {
            // P200/hour, calculate based on duration
            final hours = (durationMinutes / 60).ceil(); // Round up to next hour
            totalAmount = hours * 200.0;
          }
        }
        break;

      case 'Spa':
        // P800/session - fixed price per session
        totalAmount = 800.0;
        break;

      case 'Cottages':
        if (_checkInDate != null && _checkOutDate != null) {
          final numberOfDays = _checkOutDate!.difference(_checkInDate!).inDays;
          final days = numberOfDays > 0 ? numberOfDays : 1; // Minimum 1 day
          // P1,500/day - price may vary based on number of pax
          totalAmount = days * 1500.0;
        } else {
          // Minimum 1 day charge
          totalAmount = 1500.0;
        }
        break;

      default:
        totalAmount = 0.0;
    }

    return 'P${totalAmount.toStringAsFixed(2)}';
  }

  Future<void> _submitBooking() async {
    if (_selectedFacilityType == null) {
      _showSnackBar('Please select a facility type', Colors.red);
      return;
    }

    if (_checkInDate == null) {
      _showSnackBar('Please select a date', Colors.red);
      return;
    }

    // Payment validation
    if (_selectedPaymentMethod == null) {
      _showSnackBar('Please select a payment method', Colors.red);
      return;
    }

    if (_referenceIdController.text.trim().isEmpty) {
      _showSnackBar('Please enter your payment reference ID', Colors.red);
      return;
    }

    if (_paymentScreenshot == null) {
      _showSnackBar('Please upload your payment screenshot', Colors.red);
      return;
    }

    // Different validation based on facility type
    if (_selectedFacilityType == 'Swimming Pool') {
      if (_checkInTime == null) {
        _showSnackBar('Please select a check-in time', Colors.red);
        return;
      }

      if (_checkOutTime == null) {
        _showSnackBar('Please select a check-out time', Colors.red);
        return;
      }
    } else if (_selectedFacilityType == 'Spa') {
      if (_checkInTime == null) {
        _showSnackBar('Please select a preferred time', Colors.red);
        return;
      }
    } else if (_selectedFacilityType == 'Cottages') {
      if (_checkOutDate == null) {
        _showSnackBar('Please select a check-out date', Colors.red);
        return;
      }

      if (_checkInTime == null) {
        _showSnackBar('Please select a check-in time', Colors.red);
        return;
      }
    }

    // Save booking to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final existingBookings = prefs.getStringList('facility_bookings') ?? [];
    
    Map<String, dynamic> newBooking;

    if (_selectedFacilityType == 'Swimming Pool') {
      // Swimming pool booking with single date and check-in/check-out times
      newBooking = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'facilityName': _selectedFacilityType,
        'facilityType': _selectedFacilityType,
        'checkInDate': '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}',
        'checkOutDate': '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}', // Same date
        'selectedDate': '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}', // Service date
        'numberOfDays': 1,
        'numberOfGuests': 1,
        'checkInTime': _checkInTime!.format(context),
        'checkOutTime': _checkOutTime!.format(context),
        'time': '${_checkInTime!.format(context)} - ${_checkOutTime!.format(context)}',
        'totalAmount': _calculateTotalBill(),
        'notes': _notesController.text.trim(),
        'bookingDate': DateTime.now().toString().split(' ')[0], // Date when booking was submitted
        'dateSubmitted': DateTime.now().toString().split(' ')[0], // Clear submitted date
        'status': 'Pending',
        'paymentMethod': _selectedPaymentMethod,
        'referenceId': _referenceIdController.text.trim(),
        'paymentScreenshot': _paymentScreenshot?.path,
      };
    } else if (_selectedFacilityType == 'Spa') {
      // Spa booking with single date and time
      newBooking = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'facilityName': _selectedFacilityType,
        'facilityType': _selectedFacilityType,
        'checkInDate': '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}',
        'checkOutDate': '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}', // Same date
        'selectedDate': '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}', // Service date
        'numberOfDays': 1,
        'numberOfGuests': 1,
        'time': _checkInTime!.format(context),
        'totalAmount': _calculateTotalBill(),
        'notes': _notesController.text.trim(),
        'bookingDate': DateTime.now().toString().split(' ')[0], // Date when booking was submitted
        'dateSubmitted': DateTime.now().toString().split(' ')[0], // Clear submitted date
        'status': 'Pending',
        'paymentMethod': _selectedPaymentMethod,
        'referenceId': _referenceIdController.text.trim(),
        'paymentScreenshot': _paymentScreenshot?.path,
      };
    } else if (_selectedFacilityType == 'Cottages') {
      // Cottages booking with check-in/check-out dates, time, and number of pax
      final int numberOfDays = _checkOutDate!.difference(_checkInDate!).inDays;
      
      newBooking = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'facilityName': _selectedFacilityType,
        'facilityType': _selectedFacilityType,
        'checkInDate': '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}',
        'checkOutDate': '${_checkOutDate!.day}/${_checkOutDate!.month}/${_checkOutDate!.year}',
        'selectedDate': '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}', // Service date
        'numberOfDays': numberOfDays,
        'numberOfGuests': _numberOfPax,
        'participants': _numberOfPax, // For display consistency
        'time': _checkInTime!.format(context),
        'totalAmount': _calculateTotalBill(),
        'notes': _notesController.text.trim(),
        'bookingDate': DateTime.now().toString().split(' ')[0], // Date when booking was submitted
        'dateSubmitted': DateTime.now().toString().split(' ')[0], // Clear submitted date
        'status': 'Pending',
        'paymentMethod': _selectedPaymentMethod,
        'referenceId': _referenceIdController.text.trim(),
        'paymentScreenshot': _paymentScreenshot?.path,
      };
    } else {
      // Default fallback (should not reach here)
      return;
    }
    
    existingBookings.add(json.encode(newBooking));
    await prefs.setStringList('facility_bookings', existingBookings);

    // Get user name for notification
    final userName = prefs.getString('user_name') ?? 'Guest';
    
    // Send booking notification
    String timeSlot = '';
    if (_selectedFacilityType == 'Swimming Pool') {
      timeSlot = '${_checkInTime!.format(context)} - ${_checkOutTime!.format(context)}';
    } else if (_selectedFacilityType == 'Spa') {
      timeSlot = _checkInTime!.format(context);
    } else if (_selectedFacilityType == 'Cottages') {
      timeSlot = _checkInTime!.format(context);
    }
    
    await NotificationHelper.sendFacilityBookingNotification(
      facilityName: _selectedFacilityType!,
      bookingId: newBooking['id'],
      customerName: userName,
      bookingDate: '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}',
      timeSlot: timeSlot,
      status: 'Pending',
    );

    final String currentSelectedFacilityType = _selectedFacilityType!; // Store before reset

    // Reset form
    setState(() {
      _selectedFacilityType = null;
      _checkInDate = null;
      _checkOutDate = null;
      _checkInTime = null;
      _checkOutTime = null;
      _numberOfPax = 1;
      _notesController.clear();
      _selectedPaymentMethod = null;
      _referenceIdController.clear();
      _paymentScreenshot = null;
    });

    String message = '$currentSelectedFacilityType booking submitted successfully! Awaiting staff approval.';
    
    _showSnackBar(message, Colors.green);
    
    // Switch to view facilities tab
    _tabController.animateTo(0);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
