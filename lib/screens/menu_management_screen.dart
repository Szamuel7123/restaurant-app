import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/menu_service.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  late MenuService _menuService;
  List<MenuItem> _items = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _initMenuService();
  }

  Future<void> _initMenuService() async {
    _menuService = await MenuService.create();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _menuService.getMenuItems();
      final categories = await _menuService.getCategories();
      setState(() {
        _items = items;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading menu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addMenuItem() async {
    final result = await showDialog<MenuItem>(
      context: context,
      builder: (context) => const _MenuItemDialog(),
    );

    if (result != null) {
      try {
        await _menuService.addMenuItem(result);
        _loadMenu();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding menu item: $e')),
          );
        }
      }
    }
  }

  Future<void> _editMenuItem(MenuItem item) async {
    final result = await showDialog<MenuItem>(
      context: context,
      builder: (context) => _MenuItemDialog(item: item),
    );

    if (result != null) {
      try {
        await _menuService.updateMenuItem(result);
        _loadMenu();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating menu item: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteMenuItem(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _menuService.deleteMenuItem(item.id);
        _loadMenu();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting menu item: $e')),
          );
        }
      }
    }
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedCategory == 'All',
            onSelected: (selected) {
              setState(() => _selectedCategory = 'All');
            },
          ),
          ..._categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  setState(() => _selectedCategory = category);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: item.imageUrl != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(item.imageUrl!),
              )
            : const CircleAvatar(
                child: Icon(Icons.restaurant),
              ),
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description),
            Text(
              'Category: ${item.category}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            Text(
              'Price: \$${item.price.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editMenuItem(item),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteMenuItem(item),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Menu Management')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMenu,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredItems = _selectedCategory == 'All'
        ? _items
        : _items.where((item) => item.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text('No menu items found for this category'),
                  )
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      return _buildMenuItemCard(filteredItems[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMenuItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MenuItemDialog extends StatefulWidget {
  final MenuItem? item;

  const _MenuItemDialog({this.item});

  @override
  State<_MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends State<_MenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name);
    _descriptionController = TextEditingController(text: widget.item?.description);
    _priceController = TextEditingController(
      text: widget.item?.price.toString() ?? '',
    );
    _imageUrlController = TextEditingController(text: widget.item?.imageUrl);
    _selectedCategory = widget.item?.category ?? 'Main Course';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Menu Item' : 'Edit Menu Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL (optional)'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  'Appetizers',
                  'Main Course',
                  'Desserts',
                  'Beverages',
                ].map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final item = MenuItem(
                id: widget.item?.id ?? DateTime.now().toString(),
                name: _nameController.text,
                description: _descriptionController.text,
                price: double.parse(_priceController.text),
                category: _selectedCategory,
                imageUrl: _imageUrlController.text.isEmpty
                    ? null
                    : _imageUrlController.text,
              );
              Navigator.pop(context, item);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
} 