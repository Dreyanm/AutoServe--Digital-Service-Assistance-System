import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  List<Map<String, dynamic>> activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final activitiesJson = prefs.getString('activities') ?? '[]';
    final List<dynamic> decodedActivities = json.decode(activitiesJson);
    
    setState(() {
      activities = decodedActivities.map((activity) {
        final Map<String, dynamic> activityMap = Map<String, dynamic>.from(activity);
        return activityMap;
      }).toList();
    });
  }

  Future<void> _saveActivities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activities', json.encode(activities));
  }

  Future<void> _joinActivity(Map<String, dynamic> activity) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _JoinActivityDialog(activity: activity),
    );

    if (result != null && result['confirmed'] == true) {
      final numberOfPax = result['numberOfPax'] as int;
      final paymentMethod = result['paymentMethod'] as String?;
      final referenceId = result['referenceId'] as String?;
      final paymentScreenshot = result['paymentScreenshot'] as String?;

      // Update activity joined count
      setState(() {
        activity['joined'] = (activity['joined'] as int) + numberOfPax;
      });
      await _saveActivities();

      // Save booking to user's bookings
      await _saveBooking(activity, numberOfPax, paymentMethod, referenceId, paymentScreenshot);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined ${activity['name']}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _saveBooking(
    Map<String, dynamic> activity,
    int numberOfPax,
    String? paymentMethod,
    String? referenceId,
    String? paymentScreenshot,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getString('activity_bookings') ?? '[]';
    final List<dynamic> bookings = json.decode(bookingsJson);

    final booking = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': 'activity',
      'activityName': activity['name'],
      'schedule': activity['schedule'],
      'location': activity['location'],
      'price': activity['price'],
      'numberOfPax': numberOfPax,
      'totalAmount': _calculateTotalAmount(activity['price'], numberOfPax),
      'paymentMethod': paymentMethod,
      'referenceId': referenceId,
      'paymentScreenshot': paymentScreenshot,
      'bookingDate': DateTime.now().toIso8601String(),
      'status': 'confirmed',
    };

    bookings.add(booking);
    await prefs.setString('activity_bookings', json.encode(bookings));
  }

  String _calculateTotalAmount(String price, int numberOfPax) {
    // Handle free activities
    if (price.toLowerCase() == 'free') {
      return '0';
    }
    
    // Extract numeric value from price string
    final priceMatch = RegExp(r'(\d+)').firstMatch(price);
    if (priceMatch != null) {
      final pricePerPerson = int.parse(priceMatch.group(1)!);
      return (pricePerPerson * numberOfPax).toString();
    }
    
    // Fallback to 0 if price cannot be parsed
    return '0';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: activities.isEmpty
          ? const Center(
              child: Text(
                'No activities available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                final capacity = activity['capacity'] as int;
                final joined = activity['joined'] as int;
                final isAvailable = joined < capacity;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          image: DecorationImage(
                            image: NetworkImage(activity['image'] ?? ''),
                            fit: BoxFit.cover,
                            onError: (error, stackTrace) => const AssetImage('assets/placeholder.png'),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['name'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Schedule: ${activity['schedule']}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Location: ${activity['location']}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Price: ${activity['price']}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Capacity: $joined/$capacity people',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            if (activity['description'] != null && activity['description'].isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                activity['description'],
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isAvailable
                                    ? () => _joinActivity(activity)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isAvailable ? Colors.blue[600] : Colors.grey,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  isAvailable ? 'Join Activity' : 'Fully Booked',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _JoinActivityDialog extends StatefulWidget {
  final Map<String, dynamic> activity;

  const _JoinActivityDialog({required this.activity});

  @override
  State<_JoinActivityDialog> createState() => _JoinActivityDialogState();
}

class _JoinActivityDialogState extends State<_JoinActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _paxController = TextEditingController();
  final _referenceIdController = TextEditingController();
  String? _selectedPaymentMethod;
  File? _paymentScreenshot;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Add listener for automatic updates
    _paxController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _paxController.dispose();
    _referenceIdController.dispose();
    super.dispose();
  }

  Future<void> _uploadPaymentScreenshot() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _paymentScreenshot = File(image.path);
      });
    }
  }

  String _calculateTotalAmount(String price, int numberOfPax) {
    // Handle free activities
    if (price.toLowerCase() == 'free') {
      return '0';
    }
    
    // Extract numeric value from price string
    final priceMatch = RegExp(r'(\d+)').firstMatch(price);
    if (priceMatch != null) {
      final pricePerPerson = int.parse(priceMatch.group(1)!);
      return (pricePerPerson * numberOfPax).toString();
    }
    
    // Fallback to 0 if price cannot be parsed
    return '0';
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final capacity = activity['capacity'] as int;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Join ${activity['name']}',
        style: TextStyle(
          color: Colors.blue[800],
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity Details:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location: ${activity['location']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Price: ₱${activity['price']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capacity: ${activity['joined']}/$capacity people',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      if (activity['description'] != null && activity['description'].isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Description: ${activity['description']}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Number of people:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _paxController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Enter number of people',
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter number of people';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number < 1) {
                      return 'Please enter a valid number';
                    }
                    if (activity['joined'] + number > capacity) {
                      return 'Not enough capacity. Available: ${capacity - activity['joined']}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Payment Method:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: const [
                    DropdownMenuItem(value: 'GCash', child: Text('GCash')),
                    DropdownMenuItem(value: 'PayMaya', child: Text('PayMaya')),
                    DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a payment method';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Payment Instructions:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transfer the payment to:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Account Name: Resort Management',
                        style: TextStyle(color: Colors.blue[700], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Account Number: 09XX-XXXX-XXXX',
                        style: TextStyle(color: Colors.blue[700], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'After payment, please upload a screenshot as proof.',
                        style: TextStyle(color: Colors.blue[700], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reference ID:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _referenceIdController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Enter reference ID',
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter reference ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Upload Payment Screenshot:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _uploadPaymentScreenshot,
                  child: Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                      color: Colors.grey[50],
                    ),
                    child: _paymentScreenshot != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 24, color: Colors.blue[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Screenshot selected',
                                style: TextStyle(color: Colors.blue[600]),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 24, color: Colors.grey[600]),
                              const SizedBox(height: 4),
                              Text(
                                'Upload payment screenshot',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                // Booking Summary
                Text(
                  'Booking Summary:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Activity:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                              fontSize: 14,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              activity['name'],
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Number of People:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _paxController.text.isEmpty ? '0' : _paxController.text,
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '₱${_calculateTotalAmount(activity['price'], _paxController.text.isEmpty ? 0 : int.tryParse(_paxController.text) ?? 0)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              if (_paymentScreenshot == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please upload payment screenshot'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              final numberOfPax = int.parse(_paxController.text);
              Navigator.of(context).pop({
                'confirmed': true,
                'numberOfPax': numberOfPax,
                'paymentMethod': _selectedPaymentMethod,
                'referenceId': _referenceIdController.text.trim(),
                'paymentScreenshot': _paymentScreenshot?.path,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Join Activity'),
        ),
      ],
    );
  }
}
