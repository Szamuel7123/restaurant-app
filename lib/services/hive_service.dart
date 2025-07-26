import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String userBox = 'user_box';
  static const String menuBox = 'menu_box';
  static const String cartBox = 'cart_box';
  static const String ordersBox = 'orders_box';
  static const String bookingsBox = 'bookings_box';
  static const String settingsBox = 'settings_box';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Open boxes
    await Hive.openBox(userBox);
    await Hive.openBox(menuBox);
    await Hive.openBox(cartBox);
    await Hive.openBox(ordersBox);
    await Hive.openBox(bookingsBox);
    await Hive.openBox(settingsBox);
  }

  // User operations
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final box = Hive.box(userBox);
    await box.put('current_user', userData);
  }

  static Map<String, dynamic>? getUser() {
    final box = Hive.box(userBox);
    return box.get('current_user');
  }

  static Future<void> deleteUser() async {
    final box = Hive.box(userBox);
    await box.delete('current_user');
  }

  // Menu operations
  static Future<void> saveMenuItems(List<Map<String, dynamic>> items) async {
    final box = Hive.box(menuBox);
    await box.put('menu_items', items);
  }

  static List<Map<String, dynamic>> getMenuItems() {
    final box = Hive.box(menuBox);
    final items = box.get('menu_items');
    return items != null ? List<Map<String, dynamic>>.from(items) : [];
  }

  static Future<void> clearMenu() async {
    final box = Hive.box(menuBox);
    await box.clear();
  }

  // Cart operations
  static Future<void> saveCartItems(List<Map<String, dynamic>> items) async {
    final box = Hive.box(cartBox);
    await box.put('cart_items', items);
  }

  static List<Map<String, dynamic>> getCartItems() {
    final box = Hive.box(cartBox);
    final items = box.get('cart_items');
    return items != null ? List<Map<String, dynamic>>.from(items) : [];
  }

  static Future<void> clearCart() async {
    final box = Hive.box(cartBox);
    await box.clear();
  }

  static int getCartItemCount() {
    final box = Hive.box(cartBox);
    final items = box.get('cart_items');
    return items != null ? (items as List).length : 0;
  }

  // Order operations
  static Future<void> saveOrders(List<Map<String, dynamic>> orders) async {
    final box = Hive.box(ordersBox);
    await box.put('orders', orders);
  }

  static List<Map<String, dynamic>> getOrders() {
    final box = Hive.box(ordersBox);
    final orders = box.get('orders');
    return orders != null ? List<Map<String, dynamic>>.from(orders) : [];
  }

  static Future<void> addOrder(Map<String, dynamic> order) async {
    final box = Hive.box(ordersBox);
    final orders = getOrders();
    orders.add(order);
    await box.put('orders', orders);
  }

  // Booking operations
  static Future<void> saveBookings(List<Map<String, dynamic>> bookings) async {
    final box = Hive.box(bookingsBox);
    await box.put('bookings', bookings);
  }

  static List<Map<String, dynamic>> getBookings() {
    final box = Hive.box(bookingsBox);
    final bookings = box.get('bookings');
    return bookings != null ? List<Map<String, dynamic>>.from(bookings) : [];
  }

  static Future<void> addBooking(Map<String, dynamic> booking) async {
    final box = Hive.box(bookingsBox);
    final bookings = getBookings();
    bookings.add(booking);
    await box.put('bookings', bookings);
  }

  // Settings operations
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(settingsBox);
    await box.put(key, value);
  }

  static T? getSetting<T>(String key) {
    final box = Hive.box(settingsBox);
    return box.get(key) as T?;
  }

  static Future<void> deleteSetting(String key) async {
    final box = Hive.box(settingsBox);
    await box.delete(key);
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await Hive.box(userBox).clear();
    await Hive.box(menuBox).clear();
    await Hive.box(cartBox).clear();
    await Hive.box(ordersBox).clear();
    await Hive.box(bookingsBox).clear();
    await Hive.box(settingsBox).clear();
  }

  // Close all boxes
  static Future<void> closeAllBoxes() async {
    await Hive.close();
  }
}
