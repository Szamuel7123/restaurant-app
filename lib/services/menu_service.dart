import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_item.dart';

class MenuService {
  static const String _menuItemsKey = 'menu_items';
  static const String _categoriesKey = 'menu_categories';

  final SharedPreferences _prefs;

  MenuService(this._prefs);

  static Future<MenuService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return MenuService(prefs);
  }

  Future<List<MenuItem>> getMenuItems() async {
    final itemsJson = _prefs.getStringList(_menuItemsKey) ?? [];
    return itemsJson
        .map((json) => MenuItem.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<List<String>> getCategories() async {
    return _prefs.getStringList(_categoriesKey) ?? [
      'Appetizers',
      'Main Course',
      'Desserts',
      'Beverages',
    ];
  }

  Future<void> addMenuItem(MenuItem item) async {
    final items = await getMenuItems();
    items.add(item);
    await _saveMenuItems(items);
    await _updateCategories(item.category);
  }

  Future<void> updateMenuItem(MenuItem updatedItem) async {
    final items = await getMenuItems();
    final index = items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      items[index] = updatedItem;
      await _saveMenuItems(items);
      await _updateCategories(updatedItem.category);
    }
  }

  Future<void> deleteMenuItem(String itemId) async {
    final items = await getMenuItems();
    items.removeWhere((item) => item.id == itemId);
    await _saveMenuItems(items);
  }

  Future<void> toggleItemAvailability(String itemId) async {
    final items = await getMenuItems();
    final index = items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = items[index];
      items[index] = item.copyWith(isAvailable: !item.isAvailable);
      await _saveMenuItems(items);
    }
  }

  Future<void> _saveMenuItems(List<MenuItem> items) async {
    final itemsJson = items
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await _prefs.setStringList(_menuItemsKey, itemsJson);
  }

  Future<void> _updateCategories(String category) async {
    final categories = await getCategories();
    if (!categories.contains(category)) {
      categories.add(category);
      await _prefs.setStringList(_categoriesKey, categories);
    }
  }

  Future<void> clearMenu() async {
    await _prefs.remove(_menuItemsKey);
    await _prefs.remove(_categoriesKey);
  }
} 