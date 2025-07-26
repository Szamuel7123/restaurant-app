import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String orderType;
  final String? deliveryAddress;
  final List<Map<String, dynamic>> items;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.orderType,
    this.deliveryAddress,
    required this.items,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final PaymentService _paymentService;
  late final OrderService _orderService;
  bool _isProcessing = false;
  String? _errorMessage;
  String _selectedPaymentMethod = 'Card';
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedNetwork = 'MTN';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _orderService = OrderService(prefs);
    _paymentService = PaymentService();
    await _initializePayment();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _initializePayment() async {
    try {
      await _paymentService.initializePayment(widget.amount);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize payment: $e';
        });
      }
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      if (_selectedPaymentMethod == 'Mobile Money') {
        await _processMobileMoneyPayment();
      } else {
        await _processCardPayment();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Payment failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processMobileMoneyPayment() async {
    try {
      final result = await _paymentService.processMobileMoneyPayment(
        amount: widget.amount,
        phoneNumber: _phoneController.text,
        network: _selectedNetwork,
        email: _emailController.text,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Payment initiated successfully. Please complete the payment on your phone.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        await _createOrder('Mobile Money');
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _processCardPayment() async {
    await _paymentService.processPayment(amount: widget.amount);
    await _createOrder('Card');
  }

  Future<void> _createOrder(String paymentMethod) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'default_user';

    final order = Order(
      id: OrderService.generateOrderId(),
      userId: userId,
      items: widget.items
          .map((item) => OrderItem(
                id: item['id'],
                name: item['name'],
                price: item['price'],
                quantity: item['quantity'],
              ))
          .toList(),
      subtotal: widget.amount,
      deliveryFee: widget.orderType == 'Delivery' ? 5.0 : 0.0,
      total: widget.amount + (widget.orderType == 'Delivery' ? 5.0 : 0.0),
      status: OrderStatus.confirmed,
      createdAt: DateTime.now(),
      orderType: widget.orderType,
      deliveryAddress: widget.deliveryAddress,
      paymentMethod: paymentMethod,
      paymentStatus: 'Paid',
    );

    await _orderService.createOrder(order);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/order-confirmation',
          arguments: order);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text('Order Type: ${widget.orderType}'),
                      if (widget.deliveryAddress != null)
                        Text('Delivery Address: ${widget.deliveryAddress}'),
                      const Divider(),
                      Text(
                        'Total Amount: \u20b5${widget.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedPaymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Select Payment Method',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Card',
                            child: Text('Credit/Debit Card'),
                          ),
                          DropdownMenuItem(
                            value: 'Mobile Money',
                            child: Text('Mobile Money'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
                      ),
                      if (_selectedPaymentMethod == 'Mobile Money') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedNetwork,
                          decoration: const InputDecoration(
                            labelText: 'Select Network',
                            border: OutlineInputBorder(),
                          ),
                          items: PaymentService.mobileMoneyNetworks.keys
                              .map((network) => DropdownMenuItem(
                                    value: network,
                                    child: Text(network),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedNetwork = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                            prefixText: '+233 ',
                            hintText: 'Enter your mobile money number',
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.length < 9) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            hintText: 'Enter your email address',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Note: You will receive a prompt on your phone to complete the payment.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepOrange,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Pay \u20b5${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
