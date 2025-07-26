import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import 'payment_screen.dart';
import 'delivery_map_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/promotion.dart';
import '../models/loyalty_points.dart';
import '../services/loyalty_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartScreen extends StatefulWidget {
  final String userId;

  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _orderType = 'Pickup';
  String _address = '';
  double _deliveryFee = 0.0;
  final List<Map<String, dynamic>> _cartItems = [
    {'name': 'Burger', 'price': 15.0, 'qty': 2},
    {'name': 'Fries', 'price': 8.0, 'qty': 1},
    {'name': 'Coke', 'price': 5.0, 'qty': 2},
  ];

  double get _subtotal => _cartItems.fold(
        0.0,
        (total, item) =>
            total + ((item['price'] as double) * (item['qty'] as int)),
      );

  double get _total => PaymentService.calculateTotal(
        subtotal: _subtotal,
        deliveryFee: _deliveryFee,
        orderType: _orderType,
      );

  final _promoCodeController = TextEditingController();
  Promotion? _selectedPromotion;
  LoyaltyPoints? _loyaltyPoints;
  bool _isLoading = false;
  String? _errorMessage;
  late LoyaltyService _loyaltyService;

  @override
  void initState() {
    super.initState();
    _loyaltyService = LoyaltyService(FirebaseFirestore.instance, widget.userId);
    _loadLoyaltyPoints();
  }

  Future<void> _loadLoyaltyPoints() async {
    try {
      final points = await _loyaltyService.getUserLoyaltyPoints();
      setState(() => _loyaltyPoints = points);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load loyalty points: $e');
    }
  }

  Future<void> _applyPromoCode() async {
    if (_promoCodeController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final promotion =
          await _loyaltyService.getPromotionByCode(_promoCodeController.text);
      setState(() {
        _selectedPromotion = promotion;
        _isLoading = false;
      });

      if (promotion == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid promotion code')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to apply promotion code: $e';
        _isLoading = false;
      });
    }
  }

  void _removePromoCode() {
    setState(() {
      _selectedPromotion = null;
      _promoCodeController.clear();
    });
  }

  double _calculateDiscount(double subtotal) {
    if (_selectedPromotion == null) return 0;
    return _selectedPromotion!.calculateDiscount(subtotal);
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  void _pickDeliveryLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeliveryMapScreen(
          initialLocation: LatLng(5.6037, -0.1870), // Example: Accra, Ghana
        ),
      ),
    );
    if (result != null && result is LatLng) {
      setState(() {
        // Calculate delivery fee based on distance (simplified for now)
        _deliveryFee = 5.0; // Fixed delivery fee
        // Format the address
        _address =
            '${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}';
      });
    }
  }

  void _proceedToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          amount: _total,
          orderType: _orderType,
          deliveryAddress: _address,
          items: _cartItems
              .map((item) => {
                    'id': item['id'],
                    'name': item['name'],
                    'price': item['price'],
                    'quantity': item['qty'],
                  })
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _cartItems.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Order Type Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Type',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Pickup'),
                                value: 'Pickup',
                                groupValue: _orderType,
                                onChanged: (value) {
                                  setState(() {
                                    _orderType = value!;
                                    _deliveryFee = 0.0;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Dine-in'),
                                value: 'Dine-in',
                                groupValue: _orderType,
                                onChanged: (value) {
                                  setState(() {
                                    _orderType = value!;
                                    _deliveryFee = 0.0;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Delivery'),
                                value: 'Delivery',
                                groupValue: _orderType,
                                onChanged: (value) {
                                  setState(() {
                                    _orderType = value!;
                                    _pickDeliveryLocation();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_orderType == 'Delivery') ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _pickDeliveryLocation,
                            icon: const Icon(Icons.location_on),
                            label: Text(_address.isEmpty
                                ? 'Select Delivery Location'
                                : 'Change Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          if (_address.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Delivery Address: $_address'),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cart Items
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Order',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Divider(),
                        ..._cartItems.map((item) => ListTile(
                              title: Text(item['name'] as String),
                              subtitle: Text('Qty: ${item['qty']}'),
                              trailing: Text(
                                '\u20b5${((item['price'] as double) * (item['qty'] as int)).toStringAsFixed(2)}',
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Promotion Code Input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoCodeController,
                        decoration: const InputDecoration(
                          hintText: 'Enter promo code',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _selectedPromotion == null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedPromotion == null)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _applyPromoCode,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Apply'),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _removePromoCode,
                      ),
                  ],
                ),
                if (_selectedPromotion != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Promo applied: ${_selectedPromotion!.code}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Order Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Summary',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Divider(),
                        _buildSummaryRow('Subtotal', _subtotal),
                        _buildSummaryRow('Tax (15%)',
                            PaymentService.calculateTax(_subtotal)),
                        if (_orderType == 'Delivery')
                          _buildSummaryRow('Delivery Fee', _deliveryFee),
                        const Divider(),
                        _buildSummaryRow(
                            'Discount', _calculateDiscount(_subtotal)),
                        const Divider(),
                        _buildSummaryRow('Total', _total, isTotal: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Loyalty Points
                if (_loyaltyPoints != null && _loyaltyPoints!.points > 0) ...[
                  const Text(
                    'Loyalty Points',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Available Points: ${_loyaltyPoints!.points}'),
                      TextButton(
                        onPressed: () async {
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);
                          if (_loyaltyPoints == null ||
                              _loyaltyPoints!.points < 100) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'You need at least 100 points to redeem'),
                              ),
                            );
                            return;
                          }

                          final pointsToRedeem =
                              (_subtotal * 0.1).floor(); // 10% discount
                          if (pointsToRedeem > _loyaltyPoints!.points) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Not enough points. You have ${_loyaltyPoints!.points} points'),
                              ),
                            );
                            return;
                          }

                          final success = await _loyaltyService.redeemPoints(
                            pointsToRedeem,
                            'Order discount',
                          );

                          if (success) {
                            setState(() {
                              _selectedPromotion = Promotion(
                                id: 'points_redemption',
                                code: 'POINTS',
                                description: 'Points redemption',
                                discountType: 'percentage',
                                discountAmount: 10.0,
                                isActive: true,
                                startDate: DateTime.now(),
                                endDate:
                                    DateTime.now().add(const Duration(days: 1)),
                              );
                            });
                            if (!mounted) return;
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Successfully redeemed $pointsToRedeem points'),
                              ),
                            );
                          } else {
                            if (!mounted) return;
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Failed to redeem points'),
                              ),
                            );
                          }
                        },
                        child: const Text('Redeem Points'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Checkout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _proceedToPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Proceed to Payment',
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
          Text(
            '\u20b5${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
