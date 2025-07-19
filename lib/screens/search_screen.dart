import 'package:flutter/material.dart';
import 'resort_information_screen.dart';
import 'activities_screen.dart';
import 'facilities_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  // Search data
  final List<Map<String, dynamic>> _allSearchItems = [
    // Resort Information
    {
      'title': 'Resort Information',
      'subtitle': 'Learn about our beautiful resort',
      'category': 'Resort',
      'icon': Icons.info_outline,
      'keywords': ['resort', 'information', 'about', 'details', 'location', 'contact'],
      'screen': 'resort_info',
    },
    {
      'title': 'Resort History',
      'subtitle': 'Discover our rich heritage and story',
      'category': 'Resort',
      'icon': Icons.history,
      'keywords': ['history', 'heritage', 'story', 'background', 'founded'],
      'screen': 'resort_info',
    },
    {
      'title': 'Resort Amenities',
      'subtitle': 'Explore our world-class amenities',
      'category': 'Resort',
      'icon': Icons.apartment,
      'keywords': ['amenities', 'features', 'services', 'luxury', 'comfort'],
      'screen': 'resort_info',
    },
    
    // Facilities
    {
      'title': 'Swimming Pool',
      'subtitle': 'Olympic-size pool with crystal clear water',
      'category': 'Facilities',
      'icon': Icons.pool,
      'keywords': ['swimming', 'pool', 'water', 'swim', 'olympic', 'recreation'],
      'screen': 'facilities',
    },
    {
      'title': 'Restaurant',
      'subtitle': 'Fine dining with local and international cuisine',
      'category': 'Facilities',
      'icon': Icons.restaurant,
      'keywords': ['restaurant', 'dining', 'food', 'cuisine', 'eat', 'meal', 'lunch', 'dinner'],
      'screen': 'facilities',
    },
    {
      'title': 'Spa',
      'subtitle': 'Relaxing treatments and wellness services',
      'category': 'Facilities',
      'icon': Icons.spa,
      'keywords': ['spa', 'massage', 'wellness', 'relaxation', 'treatment', 'therapy'],
      'screen': 'facilities',
    },
    {
      'title': 'Cottages',
      'subtitle': 'Private cottages with scenic views',
      'category': 'Facilities',
      'icon': Icons.cabin,
      'keywords': ['cottages', 'accommodation', 'private', 'scenic', 'view', 'stay'],
      'screen': 'facilities',
    },
    {
      'title': 'Rooms',
      'subtitle': 'Comfortable rooms with modern amenities',
      'category': 'Facilities',
      'icon': Icons.hotel,
      'keywords': ['rooms', 'accommodation', 'stay', 'sleep', 'bed', 'hotel', 'suite'],
      'screen': 'facilities',
    },
    
    // Activities
    {
      'title': 'Banana Boating',
      'subtitle': 'Exciting water adventure for groups',
      'category': 'Activities',
      'icon': Icons.sports_motorsports,
      'keywords': ['banana', 'boating', 'water', 'adventure', 'group', 'fun', 'exciting'],
      'screen': 'activities',
    },
    {
      'title': 'Kayaking',
      'subtitle': 'Peaceful paddling experience',
      'category': 'Activities',
      'icon': Icons.kayaking,
      'keywords': ['kayaking', 'paddle', 'water', 'peaceful', 'adventure', 'solo', 'calm'],
      'screen': 'activities',
    },
    {
      'title': 'Island Hopping',
      'subtitle': 'Explore nearby beautiful islands',
      'category': 'Activities',
      'icon': Icons.sailing,
      'keywords': ['island', 'hopping', 'explore', 'boat', 'tour', 'adventure', 'islands'],
      'screen': 'activities',
    },
    {
      'title': 'Snorkeling',
      'subtitle': 'Discover underwater marine life',
      'category': 'Activities',
      'icon': Icons.masks,
      'keywords': ['snorkeling', 'underwater', 'marine', 'fish', 'diving', 'ocean', 'sea'],
      'screen': 'activities',
    },
    {
      'title': 'Beach Volleyball',
      'subtitle': 'Fun team sport on the beach',
      'category': 'Activities',
      'icon': Icons.sports_volleyball,
      'keywords': ['beach', 'volleyball', 'sport', 'team', 'game', 'sand', 'fun'],
      'screen': 'activities',
    },
  ];

  List<Map<String, dynamic>> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return _selectedCategory == 'All' 
          ? _allSearchItems 
          : _allSearchItems.where((item) => item['category'] == _selectedCategory).toList();
    }

    return _allSearchItems.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item['category'] == _selectedCategory;
      final searchLower = _searchQuery.toLowerCase();
      
      // Check title, subtitle, and keywords
      final matchesSearch = 
          item['title'].toString().toLowerCase().contains(searchLower) ||
          item['subtitle'].toString().toLowerCase().contains(searchLower) ||
          (item['keywords'] as List<String>).any((keyword) => 
              keyword.toLowerCase().contains(searchLower));
      
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          'Search',
          style: TextStyle(
            color: Colors.blue[800],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search for facilities, activities, or resort info...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.blue[600]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            // Category Filter
            Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['All', 'Resort', 'Facilities', 'Activities'].map((category) {
                  final isSelected = _selectedCategory == category;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: Colors.blue[100],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue[800] : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Search Results
            Expanded(
              child: _filteredItems.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        return _buildSearchResultItem(_filteredItems[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Start searching...' : 'No results found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Search for facilities, activities, or resort information'
                : 'Try adjusting your search or filter',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            item['icon'],
            color: Colors.blue[600],
            size: 28,
          ),
        ),
        title: Text(
          item['title'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item['subtitle'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item['category'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 16,
        ),
        onTap: () => _navigateToScreen(item['screen']),
      ),
    );
  }

  void _navigateToScreen(String screenType) {
    Widget targetScreen;
    
    switch (screenType) {
      case 'resort_info':
        targetScreen = const ResortInformationScreen();
        break;
      case 'facilities':
        targetScreen = const FacilitiesScreen();
        break;
      case 'activities':
        targetScreen = const ActivitiesScreen();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }
}
