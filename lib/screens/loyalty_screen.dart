import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promotion.dart';
import '../models/loyalty_points.dart';
import '../services/loyalty_service.dart';

class LoyaltyScreen extends StatefulWidget {
  final String userId;

  const LoyaltyScreen({super.key, required this.userId});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  late LoyaltyService _loyaltyService;
  List<Promotion> _promotions = [];
  LoyaltyPoints? _loyaltyPoints;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loyaltyService = LoyaltyService(FirebaseFirestore.instance, widget.userId);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final promotions = await _loyaltyService.getActivePromotions();
      final loyaltyPoints = await _loyaltyService.getUserLoyaltyPoints();

      setState(() {
        _promotions = promotions;
        _loyaltyPoints = loyaltyPoints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Loyalty & Promotions'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Loyalty Points'),
              Tab(text: 'Promotions'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLoyaltyPointsTab(),
            _buildPromotionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyPointsTab() {
    if (_loyaltyPoints == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Your Points',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_loyaltyPoints!.points}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPointsStat('Total Earned', _loyaltyPoints!.totalPointsEarned),
                      _buildPointsStat('Total Redeemed', _loyaltyPoints!.totalPointsRedeemed),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._loyaltyPoints!.transactions.reversed.take(5).map((transaction) {
            return Card(
              child: ListTile(
                leading: Icon(
                  transaction.type == 'earn' ? Icons.add_circle : Icons.remove_circle,
                  color: transaction.type == 'earn' ? Colors.green : Colors.red,
                ),
                title: Text(transaction.description),
                subtitle: Text(
                  '${transaction.timestamp.day}/${transaction.timestamp.month}/${transaction.timestamp.year}',
                ),
                trailing: Text(
                  '${transaction.type == 'earn' ? '+' : '-'}${transaction.points}',
                  style: TextStyle(
                    color: transaction.type == 'earn' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPointsStat(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _promotions.isEmpty
          ? const Center(
              child: Text('No active promotions available'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _promotions.length,
              itemBuilder: (context, index) {
                final promotion = _promotions[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              promotion.code,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                promotion.discountType == 'percentage'
                                    ? '${promotion.discountAmount}% OFF'
                                    : '\$${promotion.discountAmount} OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(promotion.description),
                        const SizedBox(height: 8),
                        if (promotion.minimumOrderAmount != null)
                          Text(
                            'Minimum order: \$${promotion.minimumOrderAmount}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Valid until: ${promotion.endDate.day}/${promotion.endDate.month}/${promotion.endDate.year}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
} 