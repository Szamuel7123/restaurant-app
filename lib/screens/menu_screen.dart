import 'package:flutter/material.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String selectedCategory = 'Local';

  final List<Map<String, dynamic>> menuItems = [
    // Local dishes
    {
      'name': 'Jollof Rice',
      'imageUrl': 'https://ghanacuisine.com/wp-content/uploads/2021/06/jollof-rice.jpg',
      'price': 35.00,
      'desc': 'Ghanaian party jollof rice with spicy tomato sauce and veggies.',
      'options': ['Regular', 'Large', 'Extra Spicy', 'Chicken', 'Tilapia','Red Fish'],
      'category': 'Local',
    },
    {
      'name': 'Banku & Tilapia',
      'imageUrl': 'https://ghanacuisine.com/wp-content/uploads/2021/06/banku-and-tilapia.jpg',
      'price': 50.00,
      'desc': 'Fermented corn and cassava dough with grilled tilapia and pepper sauce.',
      'options': ['Mild Pepper', 'Medium Pepper', 'Hot Pepper'],
      'category': 'Local',
    },
    {
      'name': 'Banku with Okro',
      'imageUrl': 'https://ghanacuisine.com/wp-content/uploads/2021/06/banku-okro.jpg',
      'price': 40.00,
      'desc': 'Banku served with okro stew and assorted meats or fish.',
      'options': ['Assorted Meat', 'Fish'],
      'category': 'Local',
    },
    {
      'name': 'Waakye',
      'imageUrl': 'https://ghanacuisine.com/wp-content/uploads/2021/06/waakye-ghanaian-food.jpg',
      'price': 30.00,
      'desc': 'Rice and beans served with gari, spaghetti, egg, and stew.',
      'options': ['With Egg', 'With Fish', 'With Chicken'],
      'category': 'Local',
    },
    {
      'name': 'Fufu & Light Soup',
      'imageUrl': 'https://ghanacuisine.com/wp-content/uploads/2021/06/fufu-and-light-soup.jpg',
      'price': 40.00,
      'desc': 'Pounded cassava and plantain with spicy light soup and meat.',
      'options': ['Goat Meat', 'Chicken', 'Fish'],
      'category': 'Local',
    },
    {
      'name': 'Kelewele',
      'imageUrl': 'https://ghanacuisine.com/wp-content/uploads/2021/06/kelewele.jpg',
      'price': 15.00,
      'desc': 'Spicy fried plantains, a popular Ghanaian street snack.',
      'options': ['Mild', 'Spicy'],
      'category': 'Local',
    },
    {
      'name': 'Fried Rice & Chicken',
      'imageUrl': 'https://ghanacuisine.com/wp-content/uploads/2021/06/ghana-fried-rice.jpg',
      'price': 38.00,
      'desc': 'Ghanaian-style fried rice with grilled or fried chicken.',
      'options': ['Grilled Chicken', 'Fried Chicken', 'Extra Veggies'],
      'category': 'Local',
    },
    {
      'name': 'Assorted Fried Rice',
      'imageUrl': 'https://ghanacuisine.com/wp-content/uploads/2021/06/assorted-fried-rice.jpg',
      'price': 45.00,
      'desc': 'Fried rice with assorted meats, vegetables, and a touch of Ghanaian spice.',
      'options': ['Beef', 'Chicken', 'Shrimp'],
      'category': 'Local',
    },
    {
      'name': 'Assorted Rice',
      'imageUrl': 'https://ghanacuisine.com/wp-content/uploads/2021/06/assorted-rice.jpg',
      'price': 42.00,
      'desc': 'Rice cooked with a mix of meats, vegetables, and savory Ghanaian flavors.',
      'options': ['Goat', 'Chicken', 'Fish'],
      'category': 'Local',
    },
    {
      'name': 'Red Red',
      'imageUrl': 'https://ghanacuisine.com/wp-content/uploads/2021/06/red-red.jpg',
      'price': 28.00,
      'desc': 'Fried ripe plantain with beans stew.',
      'options': ['With Egg', 'With Fish'],
      'category': 'Local',
    },
    {
      'name': 'Yam & Palava Sauce',
      'imageUrl': 'https://ghanacuisine.com/wp-content/uploads/2021/06/yam-palava-sauce.jpg',
      'price': 32.00,
      'desc': 'Boiled yam served with palava (kontomire) sauce.',
      'options': ['With Egg', 'With Fish'],
      'category': 'Local',
    },
    // International dishes
    {
      'name': 'Pizza (International)',
      'imageUrl': 'https://images.unsplash.com/photo-1513104890138-7c749659a591',
      'price': 60.00,
      'desc': 'Classic cheese pizza, a favorite international treat.',
      'options': ['Cheese', 'Pepperoni', 'Veggie'],
      'category': 'International',
    },
    {
      'name': 'Burger (International)',
      'imageUrl': 'https://images.unsplash.com/photo-1550547660-d9450f859349',
      'price': 45.00,
      'desc': 'Juicy beef burger with cheese, lettuce, and tomato.',
      'options': ['Beef', 'Chicken', 'Veggie'],
      'category': 'International',
    },
    {
      'name': 'Spaghetti Bolognese',
      'imageUrl': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
      'price': 55.00,
      'desc': 'Italian pasta with rich meat sauce.',
      'options': ['Beef', 'Chicken', 'Veggie'],
      'category': 'International',
    },
    {
      'name': 'Chicken Shawarma',
      'imageUrl': 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c',
      'price': 40.00,
      'desc': 'Middle Eastern wrap with chicken, veggies, and sauce.',
      'options': ['Mild', 'Spicy'],
      'category': 'International',
    },
    {
      'name': 'Fish & Chips',
      'imageUrl': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0',
      'price': 48.00,
      'desc': 'Crispy fried fish with golden fries.',
      'options': ['Tartar Sauce', 'Ketchup'],
      'category': 'International',
    },
    {
      'name': 'Chicken Caesar Salad',
      'imageUrl': 'https://images.unsplash.com/photo-1502741338009-cac2772e18bc',
      'price': 38.00,
      'desc': 'Fresh salad with grilled chicken, croutons, and Caesar dressing.',
      'options': ['Grilled Chicken', 'Fried Chicken'],
      'category': 'International',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final categories = ['Local', 'International'];
    final filteredMenu = menuItems.where((item) => item['category'] == selectedCategory).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: categories.map((cat) {
              final isSelected = selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                selectedColor: Colors.deepOrange,
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                onSelected: (_) {
                  setState(() {
                    selectedCategory = cat;
                  });
                },
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredMenu.length,
            itemBuilder: (context, index) {
              final item = filteredMenu[index];
              final options = item['options'] as List<String>;
              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      child: Image.network(
                        item['imageUrl'] as String,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['desc'] as String,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: options.map((opt) => Chip(label: Text(opt))).toList(),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₵${(item['price'] as double).toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
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
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 