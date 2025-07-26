import 'package:flutter/material.dart';
import '../models/order.dart' as models;
import '../services/order_service.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late OrderService _orderService;
  final NotificationService _notificationService = NotificationService();
  List<models.Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  models.OrderStatus _selectedStatus = models.OrderStatus.pending;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    final prefs = await SharedPreferences.getInstance();
    _orderService = OrderService(prefs);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _orderService.getOrderHistory();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading orders: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(models.Order order, models.OrderStatus newStatus) async {
    try {
      final updatedOrder = order.copyWith(status: newStatus);
      await _orderService.updateOrder(updatedOrder);
      await _notificationService.sendOrderStatusNotification(
        orderId: order.id,
        status: newStatus,
      );
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order status: $e')),
        );
      }
    }
  }

  Widget _buildStatusFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: models.OrderStatus.values.map((status) {
          final isSelected = status == _selectedStatus;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status.toString()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedStatus = status);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderCard(models.Order order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text('Order #${order.id}'),
        subtitle: Text(
          'Status: ${order.status}\nTotal: \$${order.total.toStringAsFixed(2)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${order.userId}'),
                Text('Order Type: ${order.orderType}'),
                if (order.deliveryAddress != null)
                  Text('Delivery Address: ${order.deliveryAddress}'),
                Text('Payment Method: ${order.paymentMethod}'),
                Text('Payment Status: ${order.paymentStatus}'),
                const Divider(),
                const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...order.items.map((item) => ListTile(
                      title: Text(item.name),
                      subtitle: Text('Qty: ${item.quantity}'),
                      trailing: Text(
                        '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (order.status != models.OrderStatus.delivered &&
                        order.status != models.OrderStatus.cancelled)
                      ElevatedButton(
                        onPressed: () {
                          final nextStatus = _getNextStatus(order.status, order);
                          if (nextStatus != null) {
                            _updateOrderStatus(order, nextStatus);
                          }
                        },
                        child: const Text('Update Status'),
                      ),
                    if (order.status != models.OrderStatus.cancelled)
                      ElevatedButton(
                        onPressed: () {
                          _updateOrderStatus(order, models.OrderStatus.cancelled);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Cancel Order'),
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

  models.OrderStatus? _getNextStatus(models.OrderStatus currentStatus, models.Order order) {
    switch (currentStatus) {
      case models.OrderStatus.pending:
        return models.OrderStatus.confirmed;
      case models.OrderStatus.confirmed:
        return models.OrderStatus.preparing;
      case models.OrderStatus.preparing:
        return models.OrderStatus.ready;
      case models.OrderStatus.ready:
        return order.orderType == 'Delivery'
            ? models.OrderStatus.delivering
            : models.OrderStatus.delivered;
      case models.OrderStatus.delivering:
        return models.OrderStatus.delivered;
      default:
        return null;
    }
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
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrders,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredOrders = _orders
        .where((order) => order.status == _selectedStatus)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: filteredOrders.isEmpty
                ? const Center(
                    child: Text('No orders found for this status'),
                  )
                : ListView.builder(
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(filteredOrders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 