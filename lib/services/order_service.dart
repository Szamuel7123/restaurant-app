import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';

class OrderService {
  final SharedPreferences _prefs;
  static const String _ordersKey = 'orders';

  OrderService(this._prefs);

  static Future<OrderService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return OrderService(prefs);
  }

  Future<List<Order>> getOrderHistory() async {
    final ordersJson = _prefs.getStringList(_ordersKey) ?? [];
    return ordersJson
        .map((json) => Order.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Order> getOrder(String orderId) async {
    final orders = await getOrderHistory();
    return orders.firstWhere((order) => order.id == orderId);
  }

  Future<void> createOrder(Order order) async {
    final orders = await getOrderHistory();
    orders.add(order);
    await _saveOrders(orders);
  }

  Future<void> updateOrder(Order updatedOrder) async {
    final orders = await getOrderHistory();
    final index = orders.indexWhere((order) => order.id == updatedOrder.id);
    if (index != -1) {
      orders[index] = updatedOrder;
      await _saveOrders(orders);
    }
  }

  Future<void> cancelOrder(String orderId) async {
    final orders = await getOrderHistory();
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final order = orders[index];
      orders[index] = order.copyWith(
        status: OrderStatus.cancelled,
        updatedAt: DateTime.now(),
      );
      await _saveOrders(orders);
    }
  }

  Future<void> reorder(Order order) async {
    // Create a new order with the same items but new ID and timestamps
    final newOrder = Order(
      id: const Uuid().v4(),
      userId: order.userId,
      items: order.items,
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      total: order.total,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      orderType: order.orderType,
      deliveryAddress: order.deliveryAddress,
      deliveryNotes: order.deliveryNotes,
      paymentMethod: order.paymentMethod,
    );

    await createOrder(newOrder);
  }

  Future<void> _saveOrders(List<Order> orders) async {
    final ordersJson = orders
        .map((order) => jsonEncode(order.toJson()))
        .toList();
    await _prefs.setStringList(_ordersKey, ordersJson);
  }

  Future<void> clearOrderHistory() async {
    await _prefs.remove(_ordersKey);
  }

  static String generateOrderId() {
    return const Uuid().v4();
  }

  static Map<String, dynamic> createOrderFromMap({
    required String orderId,
    required List<Map<String, dynamic>> items,
    required String orderType,
    required String paymentMethod,
    required double total,
    required String address,
  }) {
    final now = DateTime.now();
    return {
      'orderId': orderId,
      'items': items,
      'orderType': orderType,
      'paymentMethod': paymentMethod,
      'total': total,
      'address': address,
      'status': OrderStatus.pending.toString().split('.').last,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'estimatedDeliveryTime': _calculateEstimatedDeliveryTime(now, orderType),
    };
  }

  static DateTime _calculateEstimatedDeliveryTime(DateTime now, String orderType) {
    switch (orderType) {
      case 'Pickup':
        return now.add(const Duration(minutes: 20));
      case 'Dine-in':
        return now.add(const Duration(minutes: 15));
      case 'Delivery':
        return now.add(const Duration(minutes: 45));
      default:
        return now.add(const Duration(minutes: 30));
    }
  }

  static String getStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Order received';
      case OrderStatus.confirmed:
        return 'Order confirmed';
      case OrderStatus.preparing:
        return 'Preparing your order';
      case OrderStatus.ready:
        return 'Ready for pickup';
      case OrderStatus.delivering:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Order cancelled';
    }
  }

  static String getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return '⏳';
      case OrderStatus.confirmed:
        return '✅';
      case OrderStatus.preparing:
        return '👨‍🍳';
      case OrderStatus.ready:
        return '📦';
      case OrderStatus.delivering:
        return '🚚';
      case OrderStatus.delivered:
        return '🎉';
      case OrderStatus.cancelled:
        return '❌';
    }
  }
} 