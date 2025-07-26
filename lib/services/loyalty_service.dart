import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/promotion.dart';
import '../models/loyalty_points.dart';

class LoyaltyService {
  final FirebaseFirestore _firestore;
  final String _userId;

  LoyaltyService(this._firestore, this._userId);

  // Promotions
  Future<List<Promotion>> getActivePromotions() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('promotions')
        .where('isActive', isEqualTo: true)
        .where('endDate', isGreaterThan: now)
        .get();

    return snapshot.docs
        .map((doc) => Promotion.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<Promotion?> getPromotionByCode(String code) async {
    final snapshot = await _firestore
        .collection('promotions')
        .where('code', isEqualTo: code)
        .where('isActive', isEqualTo: true)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Promotion.fromJson({...snapshot.docs.first.data(), 'id': snapshot.docs.first.id});
  }

  // Loyalty Points
  Future<LoyaltyPoints> getUserLoyaltyPoints() async {
    final doc = await _firestore.collection('loyalty_points').doc(_userId).get();
    if (!doc.exists) {
      // Create new loyalty points record
      final newPoints = LoyaltyPoints(
        userId: _userId,
        points: 0,
        totalPointsEarned: 0,
        totalPointsRedeemed: 0,
        transactions: [],
      );
      await _firestore.collection('loyalty_points').doc(_userId).set(newPoints.toJson());
      return newPoints;
    }
    return LoyaltyPoints.fromJson(doc.data()!);
  }

  Future<void> addPoints(int points, String description, {String? orderId}) async {
    final doc = await _firestore.collection('loyalty_points').doc(_userId).get();
    final currentPoints = doc.exists
        ? LoyaltyPoints.fromJson(doc.data()!)
        : LoyaltyPoints(
            userId: _userId,
            points: 0,
            totalPointsEarned: 0,
            totalPointsRedeemed: 0,
            transactions: [],
          );

    final transaction = LoyaltyTransaction(
      id: const Uuid().v4(),
      points: points,
      type: 'earn',
      description: description,
      timestamp: DateTime.now(),
      orderId: orderId,
    );

    final updatedPoints = LoyaltyPoints(
      userId: _userId,
      points: currentPoints.points + points,
      totalPointsEarned: currentPoints.totalPointsEarned + points,
      totalPointsRedeemed: currentPoints.totalPointsRedeemed,
      transactions: [...currentPoints.transactions, transaction],
    );

    await _firestore.collection('loyalty_points').doc(_userId).set(updatedPoints.toJson());
  }

  Future<bool> redeemPoints(int points, String description) async {
    final doc = await _firestore.collection('loyalty_points').doc(_userId).get();
    if (!doc.exists) return false;

    final currentPoints = LoyaltyPoints.fromJson(doc.data()!);
    if (currentPoints.points < points) return false;

    final transaction = LoyaltyTransaction(
      id: const Uuid().v4(),
      points: points,
      type: 'redeem',
      description: description,
      timestamp: DateTime.now(),
    );

    final updatedPoints = LoyaltyPoints(
      userId: _userId,
      points: currentPoints.points - points,
      totalPointsEarned: currentPoints.totalPointsEarned,
      totalPointsRedeemed: currentPoints.totalPointsRedeemed + points,
      transactions: [...currentPoints.transactions, transaction],
    );

    await _firestore.collection('loyalty_points').doc(_userId).set(updatedPoints.toJson());
    return true;
  }

  // Calculate points for an order
  int calculateOrderPoints(double orderAmount) {
    // Example: 1 point for every $10 spent
    return (orderAmount / 10).floor();
  }
} 