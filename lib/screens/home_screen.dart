import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'qr_scanner_screen.dart';
import 'profile_screen.dart';
import 'loyalty_screen.dart';
import 'order_history_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId') ?? 'default_user';
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'label': 'Local', 'icon': Icons.restaurant},
      {'label': 'International', 'icon': Icons.public},
      {'label': 'Specials', 'icon': Icons.star},
      {'label': 'Drinks', 'icon': Icons.local_drink},
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Welcome to The One Restaurant',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Delicious food, delivered fast! 🍔🍕🥗',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                ),
              ),
            ],
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(26),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for dishes...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _QuickActionButton(
                    icon: Icons.qr_code_scanner,
                    label: 'Dine-In',
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final tableId = await navigator.push(
                        MaterialPageRoute(
                            builder: (context) => const QRScannerScreen()),
                      );
                      if (tableId != null) {
                        if (!mounted) return;
                        await navigator.push(
                          MaterialPageRoute(
                            builder: (context) => AlertDialog(
                              title: const Text('Table Scanned'),
                              content:
                                  Text('You are ordering for Table: $tableId'),
                              actions: [
                                TextButton(
                                  onPressed: () => navigator.pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _QuickActionButton(
                    icon: Icons.history,
                    label: 'Orders',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OrderHistoryScreen()),
                    ),
                  ),
                  _QuickActionButton(
                    icon: Icons.card_giftcard,
                    label: 'Loyalty',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              LoyaltyScreen(userId: _userId ?? 'default_user')),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: categories
                        .map((cat) => _CategoryChip(
                              label: cat['label'] as String,
                              icon: cat['icon'] as IconData,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          // Featured Dishes
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Featured Dishes',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _MenuItemCard(
                          name: 'Jollof Rice',
                          imageUrl:
                              'https://ghanacuisine.com/wp-content/uploads/2021/06/jollof-rice.jpg',
                          price: 35.00,
                          description:
                              'Traditional Ghanaian rice dish with rich tomato sauce',
                          onAddToCart: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CartScreen(
                                    userId: _userId ?? 'default_user'),
                              ),
                            );
                          },
                        ),
                        _MenuItemCard(
                          name: 'Banku & Tilapia',
                          imageUrl:
                              'https://ghanacuisine.com/wp-content/uploads/2021/06/banku-and-tilapia.jpg',
                          price: 50.00,
                          description:
                              'Fermented corn and cassava dough with grilled fish',
                          onAddToCart: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CartScreen(
                                    userId: _userId ?? 'default_user'),
                              ),
                            );
                          },
                        ),
                        _MenuItemCard(
                          name: 'Waakye',
                          imageUrl:
                              'https://ghanacuisine.com/wp-content/uploads/2021/06/waakye-ghanaian-food.jpg',
                          price: 30.00,
                          description:
                              'Rice and beans cooked with sorghum leaves',
                          onAddToCart: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CartScreen(
                                    userId: _userId ?? 'default_user'),
                              ),
                            );
                          },
                        ),
                        _MenuItemCard(
                          name: 'Fufu & Light Soup',
                          imageUrl:
                              'https://ghanacuisine.com/wp-content/uploads/2021/06/fufu-and-light-soup.jpg',
                          price: 40.00,
                          description:
                              'Pounded cassava and plantain with spicy soup',
                          onAddToCart: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CartScreen(
                                    userId: _userId ?? 'default_user'),
                              ),
                            );
                          },
                        ),
                      ],
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

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.deepOrange),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.deepOrange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _CategoryChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 20, color: Colors.deepOrange),
      label: Text(label),
      backgroundColor: Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double price;
  final String description;
  final VoidCallback onAddToCart;

  const _MenuItemCard({
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.description,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Image.network(
              imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₵${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onAddToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
