import 'package:flutter/material.dart';
import 'room_booking_screen.dart';

class RoomViewScreen extends StatelessWidget {
  const RoomViewScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> _roomTypes = const [
    {
      'name': 'Standard Room',
      'price': 'P2,500/night',
      'color': Colors.blue,
      'icon': Icons.single_bed,
      'description': 'Comfortable and cozy room with modern amenities perfect for couples or solo travelers.',
      'features': [
        'Queen-size bed',
        'Air conditioning',
        'Private bathroom',
        'Free Wi-Fi',
        'Cable TV',
        'Mini fridge'
      ],
      'maxGuests': 2,
    },
    {
      'name': 'Deluxe Room',
      'price': 'P3,500/night',
      'color': Colors.purple,
      'icon': Icons.king_bed,
      'description': 'Spacious room with premium furnishing and beautiful resort views.',
      'features': [
        'King-size bed',
        'Air conditioning',
        'Balcony with resort view',
        'Private bathroom with bathtub',
        'Free Wi-Fi',
        'Smart TV',
        'Mini bar',
        'Work desk'
      ],
      'maxGuests': 2,
    },
    {
      'name': 'Family Room',
      'price': 'P4,500/night',
      'color': Colors.green,
      'icon': Icons.family_restroom,
      'description': 'Perfect for families with separate sleeping areas and kid-friendly amenities.',
      'features': [
        '1 King bed + 2 Single beds',
        'Air conditioning',
        'Separate living area',
        'Family bathroom',
        'Free Wi-Fi',
        'Cable TV',
        'Mini fridge',
        'Play area for kids',
        'Safety features'
      ],
      'maxGuests': 4,
    },
    {
      'name': 'Suite',
      'price': 'P6,500/night',
      'color': Colors.orange,
      'icon': Icons.villa,
      'description': 'Luxurious suite with separate living room and premium amenities.',
      'features': [
        'King-size bed',
        'Separate living room',
        'Air conditioning',
        'Ocean view balcony',
        'Jacuzzi bathtub',
        'Premium bathroom amenities',
        'Free Wi-Fi',
        'Smart TV in both rooms',
        'Mini bar & coffee machine',
        'Room service'
      ],
      'maxGuests': 3,
    },
    {
      'name': 'Presidential Suite',
      'price': 'P9,500/night',
      'color': Colors.red,
      'icon': Icons.hotel,
      'description': 'The ultimate luxury experience with top-tier amenities and personalized service.',
      'features': [
        'Master bedroom with King bed',
        'Separate dining room',
        'Living room with sofa bed',
        'Private terrace with panoramic view',
        'Jacuzzi and rain shower',
        'Premium toiletries',
        'Free Wi-Fi',
        'Multiple Smart TVs',
        'Fully stocked mini bar',
        '24/7 butler service',
        'Private check-in/out'
      ],
      'maxGuests': 4,
    },
  ];

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
          'Resort Rooms',
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
              Text(
                'Choose Your Perfect Room',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Experience comfort and luxury in our carefully designed rooms',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _roomTypes.length,
                itemBuilder: (context, index) {
                  return _buildRoomCard(_roomTypes[index], context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Room Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (room['color'] as Color).withValues(alpha: 0.7),
                  (room['color'] as Color).withValues(alpha: 0.9),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  room['icon'],
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  room['name'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  room['price'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Room Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        room['name'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        room['price'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Max ${room['maxGuests']} guests',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Text(
                  room['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Features
                Text(
                  'Room Features:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 8),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (room['features'] as List<String>).map((feature) {
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
                const SizedBox(height: 20),
                
                // Book Now Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomBookingScreen(selectedRoom: room),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Book This Room',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
}
