import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResortInformationScreen extends StatelessWidget {
  const ResortInformationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Resort Information',
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
              // Resort Header Image
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.villa,
                        size: 60,
                        color: Colors.white,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'GloryMar Vista Beach Resort',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Your Dream Vacation Destination',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Resort Details Section
              _buildSectionTitle('Resort Details'),
              const SizedBox(height: 10),
              _buildDetailCard(
                icon: Icons.location_on,
                title: 'Location',
                description: 'Pagkilatan, Batangas City, Philippines\nBeautiful beachfront location with pristine white sand',
              ),
              const SizedBox(height: 10),
              _buildDetailCard(
                icon: Icons.star,
                title: 'Rating',
                description: '4.8/5 Stars (Based on 1,250+ reviews)\nExcellent service and amenities',
              ),
              const SizedBox(height: 10),
              _buildDetailCard(
                icon: Icons.phone,
                title: 'Contact',
                description: '+63 951 640 4567\ninfo@glorymarvistabeachresort.com',
              ),
              const SizedBox(height: 20),

              // Facilities Section
              _buildSectionTitle('Resort Facilities'),
              const SizedBox(height: 15),
              _buildFacilitiesGrid(),
              const SizedBox(height: 20),

              // Location Section
              _buildSectionTitle('Location & Map'),
              const SizedBox(height: 10),
              _buildLocationSection(context),
              const SizedBox(height: 20),

              // About Section
              _buildSectionTitle('About the Resort'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  'Paradise Beach Resort is a premier beachfront destination located in the heart of Batangas City. Our resort offers world-class amenities, exceptional service, and breathtaking ocean views. Whether you\'re looking for a romantic getaway, family vacation, or corporate retreat, we provide the perfect setting for unforgettable memories.\n\nEstablished in 2018, we have been committed to providing guests with luxury accommodations, delicious dining options, and exciting recreational activities. Our team of dedicated professionals ensures that every aspect of your stay exceeds expectations.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blue[800],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesGrid() {
    final facilities = [
      {'icon': Icons.pool, 'name': 'Swimming Pool', 'description': 'Olympic-sized pool with poolside bar'},
      {'icon': Icons.restaurant, 'name': 'Restaurant', 'description': 'Fine dining with ocean view'},
      {'icon': Icons.spa, 'name': 'Spa & Wellness', 'description': 'Full-service spa and massage'},
      {'icon': Icons.fitness_center, 'name': 'Fitness Center', 'description': '24/7 modern gym facilities'},
      {'icon': Icons.wifi, 'name': 'Free WiFi', 'description': 'High-speed internet throughout'},
      {'icon': Icons.local_parking, 'name': 'Free Parking', 'description': 'Secure parking for all guests'},
      {'icon': Icons.room_service, 'name': 'Room Service', 'description': '24-hour room service available'},
      {'icon': Icons.beach_access, 'name': 'Private Beach', 'description': 'Exclusive beach access'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: facilities.length,
      itemBuilder: (context, index) {
        final facility = facilities[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  facility['icon'] as IconData,
                  color: Colors.blue[600],
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                facility['name'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                facility['description'] as String,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.blue[100]!, Colors.blue[300]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 60,
                      color: Colors.white,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Interactive Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tap to view on map',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _showMapDialog(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Exact Address: GloryMar Vista Beach Resort, Brgy. Pagkilatan, Batangas City, Batangas 4200',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMapDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.map, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text('Resort Location'),
            ],
          ),
          content: SizedBox(
            height: 300,
            width: 300,
            child: Column(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 40,
                          color: Colors.red,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'GloryMar Vista Beach Resort',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Batangas City, Philippines',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening Google Maps...'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.directions, size: 16),
                        label: const Text('Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            const ClipboardData(
                              text: 'GloryMar Vista Beach Resort, Brgy. Pagkilatan, Batangas City, Batangas 4200',
                            ),
                          );
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Address copied to clipboard!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
