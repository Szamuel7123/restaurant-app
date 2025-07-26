import 'package:cloud_firestore/cloud_firestore.dart';

class LoyaltyPoints {
  final String userId;
  final int points;
  final int totalPointsEarned;
  final int totalPointsRedeemed;
  final List<LoyaltyTransaction> transactions;

  LoyaltyPoints({
    required this.userId,
    required this.points,
    required this.totalPointsEarned,
    required this.totalPointsRedeemed,
    required this.transactions,
  });

  factory LoyaltyPoints.fromJson(Map<String, dynamic> json) {
    return LoyaltyPoints(
      userId: json['userId'] as String,
      points: json['points'] as int,
      totalPointsEarned: json['totalPointsEarned'] as int,
      totalPointsRedeemed: json['totalPointsRedeemed'] as int,
      transactions: (json['transactions'] as List<dynamic>)
          .map((e) => LoyaltyTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'points': points,
      'totalPointsEarned': totalPointsEarned,
      'totalPointsRedeemed': totalPointsRedeemed,
      'transactions': transactions.map((e) => e.toJson()).toList(),
    };
  }
}

class LoyaltyTransaction {
  final String id;
  final int points;
  final String type; // 'earn' or 'redeem'
  final String description;
  final DateTime timestamp;
  final String? orderId;

  LoyaltyTransaction({
    required this.id,
    required this.points,
    required this.type,
    required this.description,
    required this.timestamp,
    this.orderId,
  });

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: json['id'] as String,
      points: json['points'] as int,
      type: json['type'] as String,
      description: json['description'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      orderId: json['orderId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points,
      'type': type,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'orderId': orderId,
    };
  }
} 