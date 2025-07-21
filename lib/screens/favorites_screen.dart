import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> favoriteItems;
  final Function(Map<String, dynamic>) onFavoriteToggle;

  const FavoritesScreen({
    Key? key,
    required this.favoriteItems,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: widget.favoriteItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on activities or facilities to add them here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: widget.favoriteItems.length,
                itemBuilder: (context, index) {
                  final item = widget.favoriteItems[index];
                  return _buildFavoriteCard(item);
                },
              ),
            ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> item) {
    // Handle both old and new data structures
    final String itemName = item['name'] ?? item['title'] ?? 'Unknown';
    final String itemImage = item['image'] ?? item['imagePath'] ?? '';
    final String itemType = item['type'] ?? 'unknown';

    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                image: itemImage.isNotEmpty ? DecorationImage(
                  image: AssetImage(itemImage),
                  fit: BoxFit.cover,
                ) : null,
                color: itemImage.isEmpty ? Colors.grey[300] : null,
              ),
              child: Stack(
                children: [
                  if (itemImage.isEmpty)
                    const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () {
                        widget.onFavoriteToggle(item);
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    itemType == 'activity' ? 'Activity' : 'Facility',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
