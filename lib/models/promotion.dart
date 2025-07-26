import 'package:cloud_firestore/cloud_firestore.dart';

class Promotion {
  final String id;
  final String code;
  final String description;
  final double discountAmount;
  final String discountType; // 'percentage' or 'fixed'
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int? minimumOrderAmount;
  final int? maximumDiscount;
  final List<String>? applicableItems;

  Promotion({
    required this.id,
    required this.code,
    required this.description,
    required this.discountAmount,
    required this.discountType,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.minimumOrderAmount,
    this.maximumDiscount,
    this.applicableItems,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String,
      discountAmount: (json['discountAmount'] as num).toDouble(),
      discountType: json['discountType'] as String,
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool,
      minimumOrderAmount: json['minimumOrderAmount'] as int?,
      maximumDiscount: json['maximumDiscount'] as int?,
      applicableItems: (json['applicableItems'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discountAmount': discountAmount,
      'discountType': discountType,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'minimumOrderAmount': minimumOrderAmount,
      'maximumDiscount': maximumDiscount,
      'applicableItems': applicableItems,
    };
  }

  double calculateDiscount(double orderAmount) {
    if (!isActive || DateTime.now().isAfter(endDate)) {
      return 0;
    }

    if (minimumOrderAmount != null && orderAmount < minimumOrderAmount!) {
      return 0;
    }

    double discount = 0;
    if (discountType == 'percentage') {
      discount = orderAmount * (discountAmount / 100);
    } else {
      discount = discountAmount;
    }

    if (maximumDiscount != null) {
      discount = discount.clamp(0, maximumDiscount!.toDouble());
    }

    return discount;
  }
} 