import 'package:cloud_firestore/cloud_firestore.dart';

enum MenuCategory {
  appetizers,
  mainCourse,
  desserts,
  beverages,
  salads,
  soups,
  sides,
  specials
}

class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final MenuCategory category;
  final String? imageUrl;
  final bool isAvailable;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final List<String> allergens;
  final Map<String, double> customizations;
  final int preparationTime; // in minutes
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.isAvailable = true,
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
    this.allergens = const [],
    this.customizations = const {},
    this.preparationTime = 15,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      category: MenuCategory.values.firstWhere(
        (category) =>
            category.toString() ==
            'MenuCategory.${data['category'] ?? 'mainCourse'}',
        orElse: () => MenuCategory.mainCourse,
      ),
      imageUrl: data['imageUrl'],
      isAvailable: data['isAvailable'] ?? true,
      isVegetarian: data['isVegetarian'] ?? false,
      isVegan: data['isVegan'] ?? false,
      isGlutenFree: data['isGlutenFree'] ?? false,
      allergens: List<String>.from(data['allergens'] ?? []),
      customizations: Map<String, double>.from(data['customizations'] ?? {}),
      preparationTime: data['preparationTime'] ?? 15,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category.toString().split('.').last,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
      'allergens': allergens,
      'customizations': customizations,
      'preparationTime': preparationTime,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  MenuItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    MenuCategory? category,
    String? imageUrl,
    bool? isAvailable,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    List<String>? allergens,
    Map<String, double>? customizations,
    int? preparationTime,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
      allergens: allergens ?? this.allergens,
      customizations: customizations ?? this.customizations,
      preparationTime: preparationTime ?? this.preparationTime,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  String get categoryDisplayName {
    switch (category) {
      case MenuCategory.appetizers:
        return 'Appetizers';
      case MenuCategory.mainCourse:
        return 'Main Course';
      case MenuCategory.desserts:
        return 'Desserts';
      case MenuCategory.beverages:
        return 'Beverages';
      case MenuCategory.salads:
        return 'Salads';
      case MenuCategory.soups:
        return 'Soups';
      case MenuCategory.sides:
        return 'Side Dishes';
      case MenuCategory.specials:
        return 'Chef Specials';
    }
  }

  String get formattedPrice {
    return '\$${price.toStringAsFixed(2)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MenuItemModel(id: $id, name: $name, price: $price, category: $category)';
  }
}
