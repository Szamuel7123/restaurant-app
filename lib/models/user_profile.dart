
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final List<DeliveryAddress> addresses;
  final List<String> favoriteItems;
  final Map<String, dynamic> preferences;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    this.addresses = const [],
    this.favoriteItems = const [],
    this.preferences = const {},
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImage: json['profileImage'],
      addresses: (json['addresses'] as List?)
          ?.map((addr) => DeliveryAddress.fromJson(addr))
          .toList() ?? [],
      favoriteItems: List<String>.from(json['favoriteItems'] ?? []),
      preferences: json['preferences'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'addresses': addresses.map((addr) => addr.toJson()).toList(),
      'favoriteItems': favoriteItems,
      'preferences': preferences,
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    List<DeliveryAddress>? addresses,
    List<String>? favoriteItems,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      addresses: addresses ?? this.addresses,
      favoriteItems: favoriteItems ?? this.favoriteItems,
      preferences: preferences ?? this.preferences,
    );
  }
}

class DeliveryAddress {
  final String id;
  final String label;
  final String address;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final String? additionalInfo;

  DeliveryAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
    this.additionalInfo,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['id'],
      label: json['label'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      isDefault: json['isDefault'] ?? false,
      additionalInfo: json['additionalInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
      'additionalInfo': additionalInfo,
    };
  }

  DeliveryAddress copyWith({
    String? id,
    String? label,
    String? address,
    double? latitude,
    double? longitude,
    bool? isDefault,
    String? additionalInfo,
  }) {
    return DeliveryAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
} 