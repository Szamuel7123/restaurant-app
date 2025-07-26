import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../models/user_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../models/table_booking_model.dart';

// Auth Providers
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getCurrentUser();
});

final userRoleProvider = FutureProvider<UserRole>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getUserRole();
});

// Theme Providers
final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService();
});

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier(ref.watch(themeServiceProvider));
});

final isDarkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier(ref.watch(themeServiceProvider));
});

// Menu Providers
final menuItemsProvider =
    StateNotifierProvider<MenuNotifier, AsyncValue<List<MenuItemModel>>>((ref) {
  return MenuNotifier();
});

final menuCategoriesProvider = Provider<List<MenuCategory>>((ref) {
  return MenuCategory.values;
});

final filteredMenuProvider =
    Provider.family<List<MenuItemModel>, MenuCategory?>((ref, category) {
  final menuItems = ref.watch(menuItemsProvider);
  return menuItems.when(
    data: (items) {
      if (category == null) return items;
      return items.where((item) => item.category == category).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Cart Providers
final cartProvider =
    StateNotifierProvider<CartNotifier, List<OrderItem>>((ref) {
  return CartNotifier();
});

final cartTotalProvider = Provider<double>((ref) {
  final cartItems = ref.watch(cartProvider);
  return cartItems.fold(0.0, (total, item) => total + item.totalPrice);
});

final cartItemCountProvider = Provider<int>((ref) {
  final cartItems = ref.watch(cartProvider);
  return cartItems.length;
});

// Order Providers
final ordersProvider =
    StateNotifierProvider<OrdersNotifier, AsyncValue<List<OrderModel>>>((ref) {
  return OrdersNotifier();
});

final userOrdersProvider =
    Provider.family<AsyncValue<List<OrderModel>>, String>((ref, userId) {
  final orders = ref.watch(ordersProvider);
  return orders.when(
    data: (allOrders) => AsyncValue.data(
        allOrders.where((order) => order.userId == userId).toList()),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Booking Providers
final bookingsProvider = StateNotifierProvider<BookingsNotifier,
    AsyncValue<List<TableBookingModel>>>((ref) {
  return BookingsNotifier();
});

final userBookingsProvider =
    Provider.family<AsyncValue<List<TableBookingModel>>, String>((ref, userId) {
  final bookings = ref.watch(bookingsProvider);
  return bookings.when(
    data: (allBookings) => AsyncValue.data(
        allBookings.where((booking) => booking.userId == userId).toList()),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Table Availability Provider
final tableAvailabilityProvider =
    StateNotifierProvider<TableAvailabilityNotifier, Map<String, bool>>((ref) {
  return TableAvailabilityNotifier();
});

// Notifiers
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final ThemeService _themeService;

  ThemeNotifier(this._themeService) : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final theme = await _themeService.getThemeMode();
    state = theme;
  }

  Future<void> setTheme(ThemeMode theme) async {
    await _themeService.setThemeMode(theme);
    state = theme;
  }

  Future<void> toggleTheme() async {
    final newTheme = await _themeService.toggleTheme();
    state = newTheme;
  }
}

class DarkModeNotifier extends StateNotifier<bool> {
  final ThemeService _themeService;

  DarkModeNotifier(this._themeService) : super(false) {
    _loadDarkMode();
  }

  Future<void> _loadDarkMode() async {
    final isDark = await _themeService.getIsDarkMode();
    state = isDark;
  }

  Future<void> setDarkMode(bool isDark) async {
    await _themeService.setIsDarkMode(isDark);
    state = isDark;
  }
}

class MenuNotifier extends StateNotifier<AsyncValue<List<MenuItemModel>>> {
  MenuNotifier() : super(const AsyncValue.loading());

  Future<void> loadMenu() async {
    state = const AsyncValue.loading();
    try {
      // TODO: Implement menu loading from Firebase
      state = const AsyncValue.data([]);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> addMenuItem(MenuItemModel item) async {
    try {
      // TODO: Implement adding menu item to Firebase
      final currentItems = state.value ?? [];
      state = AsyncValue.data([...currentItems, item]);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> updateMenuItem(MenuItemModel item) async {
    try {
      // TODO: Implement updating menu item in Firebase
      final currentItems = state.value ?? [];
      final index = currentItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        currentItems[index] = item;
        state = AsyncValue.data([...currentItems]);
      }
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> deleteMenuItem(String itemId) async {
    try {
      // TODO: Implement deleting menu item from Firebase
      final currentItems = state.value ?? [];
      state = AsyncValue.data(
          currentItems.where((item) => item.id != itemId).toList());
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

class CartNotifier extends StateNotifier<List<OrderItem>> {
  CartNotifier() : super([]);

  void addItem(OrderItem item) {
    final existingIndex =
        state.indexWhere((i) => i.menuItemId == item.menuItemId);
    if (existingIndex != -1) {
      final existingItem = state[existingIndex];
      final updatedItem = OrderItem(
        menuItemId: existingItem.menuItemId,
        name: existingItem.name,
        price: existingItem.price,
        quantity: existingItem.quantity + item.quantity,
        customizations: existingItem.customizations,
        specialInstructions: existingItem.specialInstructions,
        totalPrice:
            (existingItem.price * (existingItem.quantity + item.quantity)),
      );
      state = [
        ...state.sublist(0, existingIndex),
        updatedItem,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, item];
    }
  }

  void updateItemQuantity(String itemId, int quantity) {
    final index = state.indexWhere((item) => item.menuItemId == itemId);
    if (index != -1) {
      final item = state[index];
      if (quantity <= 0) {
        removeItem(itemId);
      } else {
        final updatedItem = OrderItem(
          menuItemId: item.menuItemId,
          name: item.name,
          price: item.price,
          quantity: quantity,
          customizations: item.customizations,
          specialInstructions: item.specialInstructions,
          totalPrice: item.price * quantity,
        );
        state = [
          ...state.sublist(0, index),
          updatedItem,
          ...state.sublist(index + 1),
        ];
      }
    }
  }

  void removeItem(String itemId) {
    state = state.where((item) => item.menuItemId != itemId).toList();
  }

  void clearCart() {
    state = [];
  }
}

class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  OrdersNotifier() : super(const AsyncValue.loading());

  Future<void> loadOrders() async {
    state = const AsyncValue.loading();
    try {
      // TODO: Implement orders loading from Firebase
      state = const AsyncValue.data([]);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> addOrder(OrderModel order) async {
    try {
      // TODO: Implement adding order to Firebase
      final currentOrders = state.value ?? [];
      state = AsyncValue.data([...currentOrders, order]);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      // TODO: Implement updating order status in Firebase
      final currentOrders = state.value ?? [];
      final index = currentOrders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final order = currentOrders[index];
        final updatedOrder = OrderModel(
          id: order.id,
          userId: order.userId,
          userName: order.userName,
          tableNumber: order.tableNumber,
          items: order.items,
          subtotal: order.subtotal,
          tax: order.tax,
          tip: order.tip,
          total: order.total,
          status: status,
          paymentStatus: order.paymentStatus,
          paymentMethod: order.paymentMethod,
          paymentTransactionId: order.paymentTransactionId,
          orderTime: order.orderTime,
          estimatedDeliveryTime: order.estimatedDeliveryTime,
          actualDeliveryTime: order.actualDeliveryTime,
          specialInstructions: order.specialInstructions,
          cancellationReason: order.cancellationReason,
          createdBy: order.createdBy,
          createdAt: order.createdAt,
          updatedAt: DateTime.now(),
        );
        currentOrders[index] = updatedOrder;
        state = AsyncValue.data([...currentOrders]);
      }
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

class BookingsNotifier
    extends StateNotifier<AsyncValue<List<TableBookingModel>>> {
  BookingsNotifier() : super(const AsyncValue.loading());

  Future<void> loadBookings() async {
    state = const AsyncValue.loading();
    try {
      // TODO: Implement bookings loading from Firebase
      state = const AsyncValue.data([]);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> addBooking(TableBookingModel booking) async {
    try {
      // TODO: Implement adding booking to Firebase
      final currentBookings = state.value ?? [];
      state = AsyncValue.data([...currentBookings, booking]);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> updateBookingStatus(
      String bookingId, BookingStatus status) async {
    try {
      // TODO: Implement updating booking status in Firebase
      final currentBookings = state.value ?? [];
      final index =
          currentBookings.indexWhere((booking) => booking.id == bookingId);
      if (index != -1) {
        final booking = currentBookings[index];
        final updatedBooking = TableBookingModel(
          id: booking.id,
          userId: booking.userId,
          userName: booking.userName,
          userPhone: booking.userPhone,
          tableNumber: booking.tableNumber,
          tableSize: booking.tableSize,
          numberOfGuests: booking.numberOfGuests,
          bookingDate: booking.bookingDate,
          bookingTime: booking.bookingTime,
          durationMinutes: booking.durationMinutes,
          status: status,
          specialRequests: booking.specialRequests,
          cancellationReason: booking.cancellationReason,
          createdAt: booking.createdAt,
          updatedAt: DateTime.now(),
          createdBy: booking.createdBy,
        );
        currentBookings[index] = updatedBooking;
        state = AsyncValue.data([...currentBookings]);
      }
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

class TableAvailabilityNotifier extends StateNotifier<Map<String, bool>> {
  TableAvailabilityNotifier() : super({});

  void setTableAvailability(String tableNumber, bool isAvailable) {
    state = {...state, tableNumber: isAvailable};
  }

  void setMultipleTables(Map<String, bool> availability) {
    state = {...state, ...availability};
  }

  bool isTableAvailable(String tableNumber) {
    return state[tableNumber] ?? true;
  }
}
