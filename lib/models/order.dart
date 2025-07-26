
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivering,
  delivered,
  cancelled,
}

class OrderItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? notes;

  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as double,
      quantity: json['quantity'] as int,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'notes': notes,
    };
  }

  OrderItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? notes,
  }) {
    return OrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? deliveryAddress;
  final String? deliveryNotes;
  final String? paymentMethod;
  final String? paymentStatus;
  final String orderType;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.orderType,
    this.updatedAt,
    this.deliveryAddress,
    this.deliveryNotes,
    this.paymentMethod,
    this.paymentStatus,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: json['subtotal'] as double,
      deliveryFee: json['deliveryFee'] as double,
      total: json['total'] as double,
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${json['status']}',
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      orderType: json['orderType'] as String,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      deliveryAddress: json['deliveryAddress'] as String?,
      deliveryNotes: json['deliveryNotes'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'orderType': orderType,
      'updatedAt': updatedAt?.toIso8601String(),
      'deliveryAddress': deliveryAddress,
      'deliveryNotes': deliveryNotes,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? total,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deliveryAddress,
    String? deliveryNotes,
    String? paymentMethod,
    String? paymentStatus,
    String? orderType,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      orderType: orderType ?? this.orderType,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
} 