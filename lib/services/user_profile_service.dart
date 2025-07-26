import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserProfileService {
  static const String _profileKey = 'user_profile';
  final SharedPreferences _prefs;

  UserProfileService(this._prefs);

  Future<UserProfile?> getProfile() async {
    final String? profileJson = _prefs.getString(_profileKey);
    if (profileJson == null) return null;
    return UserProfile.fromJson(json.decode(profileJson));
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_profileKey, json.encode(profile.toJson()));
  }

  Future<void> updateProfile(UserProfile profile) async {
    await saveProfile(profile);
  }

  Future<void> addAddress(DeliveryAddress address) async {
    final profile = await getProfile();
    if (profile == null) return;

    final updatedAddresses = List<DeliveryAddress>.from(profile.addresses);
    if (address.isDefault) {
      // Remove default status from other addresses
      for (var addr in updatedAddresses) {
        if (addr.isDefault) {
          updatedAddresses[updatedAddresses.indexOf(addr)] =
              addr.copyWith(isDefault: false);
        }
      }
    }
    updatedAddresses.add(address);

    await saveProfile(profile.copyWith(addresses: updatedAddresses));
  }

  Future<void> updateAddress(DeliveryAddress address) async {
    final profile = await getProfile();
    if (profile == null) return;

    final updatedAddresses = List<DeliveryAddress>.from(profile.addresses);
    final index = updatedAddresses.indexWhere((addr) => addr.id == address.id);
    if (index != -1) {
      if (address.isDefault) {
        // Remove default status from other addresses
        for (var addr in updatedAddresses) {
          if (addr.isDefault) {
            updatedAddresses[updatedAddresses.indexOf(addr)] =
                addr.copyWith(isDefault: false);
          }
        }
      }
      updatedAddresses[index] = address;
      await saveProfile(profile.copyWith(addresses: updatedAddresses));
    }
  }

  Future<void> deleteAddress(String addressId) async {
    final profile = await getProfile();
    if (profile == null) return;

    final updatedAddresses =
        profile.addresses.where((addr) => addr.id != addressId).toList();

    await saveProfile(profile.copyWith(addresses: updatedAddresses));
  }

  Future<void> setDefaultAddress(String addressId) async {
    final profile = await getProfile();
    if (profile == null) return;

    final updatedAddresses = profile.addresses.map((addr) {
      return addr.copyWith(isDefault: addr.id == addressId);
    }).toList();

    await saveProfile(profile.copyWith(addresses: updatedAddresses));
  }

  Future<void> addFavoriteItem(String itemId) async {
    final profile = await getProfile();
    if (profile == null) return;

    final updatedFavorites = List<String>.from(profile.favoriteItems);
    if (!updatedFavorites.contains(itemId)) {
      updatedFavorites.add(itemId);
      await saveProfile(profile.copyWith(favoriteItems: updatedFavorites));
    }
  }

  Future<void> removeFavoriteItem(String itemId) async {
    final profile = await getProfile();
    if (profile == null) return;

    final updatedFavorites =
        profile.favoriteItems.where((id) => id != itemId).toList();

    await saveProfile(profile.copyWith(favoriteItems: updatedFavorites));
  }

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    final profile = await getProfile();
    if (profile == null) return;

    final updatedPreferences = Map<String, dynamic>.from(profile.preferences);
    updatedPreferences.addAll(preferences);

    await saveProfile(profile.copyWith(preferences: updatedPreferences));
  }
}
