import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivered,
  cancelled,
  completed
}

enum PaymentStatus { pending, paid, failed, refunded }

enum PaymentMethod { cash, card, mobilePayment, online }

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final Map<String, dynamic> customizations;
  final String? specialInstructions;
  final double totalPrice;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.customizations = const {},
    this.specialInstructions,
    required this.totalPrice,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItemId: map['menuItemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      customizations: Map<String, dynamic>.from(map['customizations'] ?? {}),
      specialInstructions: map['specialInstructions'],
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'customizations': customizations,
      'specialInstructions': specialInstructions,
      'totalPrice': totalPrice,
    };
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String? tableNumber;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double tip;
  final double total;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final String? paymentTransactionId;
  final DateTime orderTime;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final String? specialInstructions;
  final String? cancellationReason;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.tableNumber,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.tip,
    required this.total,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    this.paymentTransactionId,
    required this.orderTime,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.specialInstructions,
    this.cancellationReason,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      tableNumber: data['tableNumber'],
      items: (data['items'] as List<dynamic>?)
              ?.map(
                  (item) => OrderItem.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      tax: (data['tax'] ?? 0.0).toDouble(),
      tip: (data['tip'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (status) =>
            status.toString() == 'OrderStatus.${data['status'] ?? 'pending'}',
        orElse: () => OrderStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (status) =>
            status.toString() ==
            'PaymentStatus.${data['paymentStatus'] ?? 'pending'}',
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: data['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (method) =>
                  method.toString() == 'PaymentMethod.${data['paymentMethod']}',
              orElse: () => PaymentMethod.cash,
            )
          : null,
      paymentTransactionId: data['paymentTransactionId'],
      orderTime: (data['orderTime'] as Timestamp).toDate(),
      estimatedDeliveryTime: data['estimatedDeliveryTime'] != null
          ? (data['estimatedDeliveryTime'] as Timestamp).toDate()
          : null,
      actualDeliveryTime: data['actualDeliveryTime'] != null
          ? (data['actualDeliveryTime'] as Timestamp).toDate()
          : null,
      specialInstructions: data['specialInstructions'],
      cancellationReason: data['cancellationReason'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'tableNumber': tableNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'tip': tip,
      'total': total,
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'paymentMethod': paymentMethod?.toString().split('.').last,
      'paymentTransactionId': paymentTransactionId,
      'orderTime': Timestamp.fromDate(orderTime),
      'estimatedDeliveryTime': estimatedDeliveryTime != null
          ? Timestamp.fromDate(estimatedDeliveryTime!)
          : null,
      'actualDeliveryTime': actualDeliveryTime != null
          ? Timestamp.fromDate(actualDeliveryTime!)
          : null,
      'specialInstructions': specialInstructions,
      'cancellationReason': cancellationReason,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.completed:
        return 'Completed';
    }
  }

  String get formattedTotal {
    return '\$${total.toStringAsFixed(2)}';
  }

  bool get canBeCancelled {
    return status == OrderStatus.pending || status == OrderStatus.confirmed;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
