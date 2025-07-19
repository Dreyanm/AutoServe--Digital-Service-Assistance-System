import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../helpers/notification_helper.dart';

class RoomBookingScreen extends StatefulWidget {
  final Map<String, dynamic> selectedRoom;
  
  const RoomBookingScreen({Key? key, required this.selectedRoom}) : super(key: key);

  @override
  State<RoomBookingScreen> createState() => _RoomBookingScreenState();
}

class _RoomBookingScreenState extends State<RoomBookingScreen> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;
  int _numberOfGuests = 1;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  // Payment variables
  String? _selectedPaymentMethod;
  final TextEditingController _referenceIdController = TextEditingController();
  XFile? _paymentScreenshot;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
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
          'Book ${widget.selectedRoom['name']}',
          style: TextStyle(
            color: Colors.blue[800],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Room Summary
              _buildSelectedRoomSummary(),
              const SizedBox(height: 24),
              
              // Booking Form
              _buildBookingForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedRoomSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.selectedRoom['icon'],
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
                      widget.selectedRoom['name'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Max ${widget.selectedRoom['maxGuests']} guests',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                widget.selectedRoom['price'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.selectedRoom['description'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Features:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (widget.selectedRoom['features'] as List<String>).map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  feature,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Booking Form Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.edit_calendar, color: Colors.blue[600]),
              const SizedBox(width: 12),
              Text(
                'Complete Your Booking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Number of Guests
        Text(
          'Number of Guests',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              onPressed: _numberOfGuests > 1 ? () {
                setState(() {
                  _numberOfGuests--;
                });
              } : null,
              icon: Icon(Icons.remove_circle_outline, color: _numberOfGuests > 1 ? Colors.blue[600] : Colors.grey[400]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_numberOfGuests',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: _numberOfGuests < widget.selectedRoom['maxGuests'] ? () {
                setState(() {
                  _numberOfGuests++;
                });
              } : null,
              icon: Icon(Icons.add_circle_outline, color: _numberOfGuests < widget.selectedRoom['maxGuests'] ? Colors.blue[600] : Colors.grey[400]),
            ),
            const SizedBox(width: 12),
            Text(
              'Max: ${widget.selectedRoom['maxGuests']} guests',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Check-in Date
        Text(
          'Check-in Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 12),
        _buildDateSelector(
          label: 'Select check-in date',
          selectedDate: _checkInDate,
          onTap: () => _selectCheckInDate(),
        ),
        const SizedBox(height: 8),
        
        // Availability helper text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Unavailable dates are disabled in the calendar. Only available dates can be selected.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Check-in Time
        Text(
          'Check-in Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 12),
        _buildTimeSelector(
          label: 'Select check-in time',
          selectedTime: _checkInTime,
          onTap: () => _selectCheckInTime(),
        ),
        const SizedBox(height: 24),

        // Check-out Date
        Text(
          'Check-out Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 12),
        _buildDateSelector(
          label: 'Select check-out date',
          selectedDate: _checkOutDate,
          onTap: () => _selectCheckOutDate(),
        ),
        const SizedBox(height: 16),

        // Check-out Time
        Text(
          'Check-out Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 12),
        _buildTimeSelector(
          label: 'Select check-out time',
          selectedTime: _checkOutTime,
          onTap: () => _selectCheckOutTime(),
        ),
        const SizedBox(height: 24),

        // Special Requests
        Text(
          'Special Requests (Optional)',
          style: TextStyle(
            fontSize: 16,
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
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any special requests or preferences...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Payment Information Section
        Container(
          padding: const EdgeInsets.all(20),
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
              Text(
                'Payment Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 16),
              
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
              
              // Payment Instructions
              if (_selectedPaymentMethod != null) ...[
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
              ],
              
              // Reference ID Field
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
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Booking Summary
        _buildBookingSummary(),
        const SizedBox(height: 24),

        // Submit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Submitting...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Book Room',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector({required String label, required DateTime? selectedDate, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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
              selectedDate != null
                  ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                  : label,
              style: TextStyle(
                fontSize: 16,
                color: selectedDate != null ? Colors.black : Colors.grey[500],
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({required String label, required TimeOfDay? selectedTime, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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
              selectedTime != null
                  ? selectedTime.format(context)
                  : label,
              style: TextStyle(
                fontSize: 16,
                color: selectedTime != null ? Colors.black : Colors.grey[500],
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    if (_checkInDate == null || _checkOutDate == null) {
      return const SizedBox.shrink();
    }

    final int numberOfNights = _checkOutDate!.difference(_checkInDate!).inDays;
    final int pricePerNight = int.parse(widget.selectedRoom['price'].replaceAll(RegExp(r'[^\d]'), ''));
    final int totalPrice = pricePerNight * numberOfNights;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Booking Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Room Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Room Type:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Expanded(
                child: Text(
                  widget.selectedRoom['name'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Check-in and Check-out dates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Check-in:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Check-out:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${_checkOutDate!.day}/${_checkOutDate!.month}/${_checkOutDate!.year}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Guests and Nights
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Guests:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '$_numberOfGuests',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nights:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '$numberOfNights',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Price per night
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price per night:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '₱${pricePerNight.toString()}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Divider
          Divider(color: Colors.blue[200]),
          const SizedBox(height: 8),
          
          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              Text(
                '₱${totalPrice.toString()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectCheckInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        // Allow selection of any future date initially
        return date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
      },
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
      // Check availability after user selects date
      final isAvailable = await _isDateRangeAvailable(picked, picked.add(const Duration(days: 1)));
      if (!isAvailable) {
        if (mounted) {
          _showSnackBar('Selected date is not available. Please choose a different date.', Colors.red);
        }
        return;
      }
      
      setState(() {
        _checkInDate = picked;
        // Reset check-out date if it's before the new check-in date
        if (_checkOutDate != null && _checkOutDate!.isBefore(picked.add(const Duration(days: 1)))) {
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
      selectableDayPredicate: (DateTime date) {
        // Allow selection of any date after check-in
        return date.isAfter(_checkInDate!);
      },
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
      // Check availability for the entire range after user selects date
      final isAvailable = await _isDateRangeAvailable(_checkInDate!, picked);
      if (!isAvailable) {
        if (mounted) {
          _showSnackBar('Selected date range is not available. Please choose different dates.', Colors.red);
        }
        return;
      }
      
      setState(() {
        _checkOutDate = picked;
      });
    }
  }

  Future<void> _selectCheckInTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0), // Default 2:00 PM
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

  Future<void> _selectCheckOutTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0), // Default 12:00 PM
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
    if (picked != null && picked != _checkOutTime) {
      setState(() {
        _checkOutTime = picked;
      });
    }
  }

  Future<void> _pickPaymentScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _paymentScreenshot = image;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', Colors.red);
    }
  }

  // Date availability checking functions
  Future<bool> _isDateRangeAvailable(DateTime checkIn, DateTime checkOut) async {
    final prefs = await SharedPreferences.getInstance();
    final existingBookings = prefs.getStringList('room_bookings') ?? [];
    
    for (String bookingStr in existingBookings) {
      final booking = json.decode(bookingStr) as Map<String, dynamic>;
      
      // Skip if different room type
      if (booking['roomType'] != widget.selectedRoom['name']) continue;
      
      // Skip if booking is cancelled or rejected
      if (booking['status'] == 'Cancelled' || booking['status'] == 'Rejected') continue;
      
      // Parse existing booking dates
      final existingCheckIn = _parseDate(booking['checkInDate']);
      final existingCheckOut = _parseDate(booking['checkOutDate']);
      
      if (existingCheckIn != null && existingCheckOut != null) {
        // Check for date overlap
        if (_datesOverlap(checkIn, checkOut, existingCheckIn, existingCheckOut)) {
          return false;
        }
      }
    }
    
    return true;
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  bool _datesOverlap(DateTime checkIn1, DateTime checkOut1, DateTime checkIn2, DateTime checkOut2) {
    // Check if date ranges overlap
    return checkIn1.isBefore(checkOut2) && checkOut1.isAfter(checkIn2);
  }

  Future<void> _submitBooking() async {
    // Validation
    if (_checkInDate == null) {
      _showSnackBar('Please select check-in date', Colors.red);
      return;
    }

    if (_checkOutDate == null) {
      _showSnackBar('Please select check-out date', Colors.red);
      return;
    }

    if (_checkInTime == null) {
      _showSnackBar('Please select check-in time', Colors.red);
      return;
    }

    if (_checkOutTime == null) {
      _showSnackBar('Please select check-out time', Colors.red);
      return;
    }

    // Check date availability
    final isAvailable = await _isDateRangeAvailable(_checkInDate!, _checkOutDate!);
    if (!isAvailable) {
      _showSnackBar('Selected dates are not available. Please choose different dates.', Colors.red);
      return;
    }

    // Payment validation
    if (_selectedPaymentMethod == null) {
      _showSnackBar('Please select a payment method', Colors.red);
      return;
    }

    if (_referenceIdController.text.trim().isEmpty) {
      _showSnackBar('Please enter payment reference ID', Colors.red);
      return;
    }

    if (_paymentScreenshot == null) {
      _showSnackBar('Please upload payment screenshot', Colors.red);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate submission delay
    await Future.delayed(const Duration(seconds: 2));

    final int numberOfNights = _checkOutDate!.difference(_checkInDate!).inDays;
    final int pricePerNight = int.parse(widget.selectedRoom['price'].replaceAll(RegExp(r'[^\d]'), ''));
    final int totalAmount = pricePerNight * numberOfNights;

    // Save room booking to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final existingBookings = prefs.getStringList('room_bookings') ?? [];
    
    final newBooking = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'roomType': widget.selectedRoom['name'],
      'numberOfGuests': _numberOfGuests,
      'checkInDate': '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}',
      'checkOutDate': '${_checkOutDate!.day}/${_checkOutDate!.month}/${_checkOutDate!.year}',
      'checkInTime': _checkInTime!.format(context),
      'checkOutTime': _checkOutTime!.format(context),
      'numberOfNights': numberOfNights,
      'pricePerNight': pricePerNight,
      'totalAmount': totalAmount,
      'specialRequests': _notesController.text.trim(),
      'bookingDate': DateTime.now().toString().split(' ')[0], // Date when booking was submitted
      'dateSubmitted': DateTime.now().toString().split(' ')[0], // Clear submitted date
      'status': 'Pending',
      'paymentMethod': _selectedPaymentMethod!,
      'referenceId': _referenceIdController.text.trim(),
      'paymentScreenshot': _paymentScreenshot!.path,
    };
    
    existingBookings.add(json.encode(newBooking));
    await prefs.setStringList('room_bookings', existingBookings);

    // Get user name for notification
    final userName = prefs.getString('user_name') ?? 'Guest';
    
    // Send room booking notification
    await NotificationHelper.sendRoomBookingNotification(
      roomType: widget.selectedRoom['name'],
      bookingId: newBooking['id'],
      customerName: userName,
      checkinDate: '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}',
      checkoutDate: '${_checkOutDate!.day}/${_checkOutDate!.month}/${_checkOutDate!.year}',
      status: 'Pending',
    );

    setState(() {
      _isSubmitting = false;
    });

    // Show success dialog and navigate back
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Room Booking Submitted!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your room booking is pending approval from our staff. We will contact you shortly to confirm your reservation.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to facilities screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Got it, Thanks!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
