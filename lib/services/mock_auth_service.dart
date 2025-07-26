import 'dart:async';
import 'dart:developer' as developer;
import '../models/user_model.dart';

class MockAuthService {
  // Mock user data for testing
  static final Map<String, UserModel> _mockUsers = {
    'admin@test.com': UserModel(
      id: 'admin-001',
      email: 'admin@test.com',
      fullName: 'Admin User',
      phoneNumber: '+1234567890',
      role: UserRole.admin,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLoginAt: DateTime.now(),
    ),
    'client@test.com': UserModel(
      id: 'client-001',
      email: 'client@test.com',
      fullName: 'Client User',
      phoneNumber: '+0987654321',
      role: UserRole.client,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      lastLoginAt: DateTime.now(),
    ),
  };

  static UserModel? _currentUser;
  static final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();

  // Get current user
  UserModel? get currentUser => _currentUser;

  // Auth state changes stream
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _currentUser != null;
  }

  // Check auth state and load user data
  Future<void> checkAuthState() async {
    // Simulate checking auth state
    await Future.delayed(const Duration(milliseconds: 500));
    developer.log('Mock auth state checked', name: 'MockAuthService');
  }

  // Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    UserRole role = UserRole.client,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));

      // Check if user already exists
      if (_mockUsers.containsKey(email)) {
        throw Exception('An account already exists with this email address.');
      }

      // Validate password
      if (password.length < 6) {
        throw Exception('The password provided is too weak.');
      }

      // Create new user
      final newUser = UserModel(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // Add to mock database
      _mockUsers[email] = newUser;
      _currentUser = newUser;

      // Notify auth state change
      _authStateController.add(_currentUser);

      developer.log('Mock user created: ${newUser.email}',
          name: 'MockAuthService');
      return newUser;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));

      // Check if user exists
      final user = _mockUsers[email];
      if (user == null) {
        throw Exception('No user found with this email address.');
      }

      // Mock password validation (in real app, this would be hashed)
      if (password != 'password123') {
        throw Exception('Wrong password provided.');
      }

      // Update last login time
      final updatedUser = user.copyWith(
        lastLoginAt: DateTime.now(),
      );
      _mockUsers[email] = updatedUser;
      _currentUser = updatedUser;

      // Notify auth state change
      _authStateController.add(_currentUser);

      developer.log('Mock user signed in: ${updatedUser.email}',
          name: 'MockAuthService');
      return updatedUser;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      _currentUser = null;
      _authStateController.add(null);

      developer.log('Mock user signed out', name: 'MockAuthService');
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));

      // Check if user exists
      if (!_mockUsers.containsKey(email)) {
        throw Exception('No user found with this email address.');
      }

      developer.log('Mock password reset email sent to: $email',
          name: 'MockAuthService');
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      if (_currentUser == null) {
        throw Exception('User not logged in');
      }

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Update user data
      final updatedUser = _currentUser!.copyWith(
        fullName: fullName ?? _currentUser!.fullName,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
      );

      _mockUsers[_currentUser!.email] = updatedUser;
      _currentUser = updatedUser;

      developer.log('Mock user profile updated', name: 'MockAuthService');
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      return _currentUser;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Get user role
  Future<UserRole> getUserRole() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 200));
      return _currentUser?.role ?? UserRole.client;
    } catch (e) {
      return UserRole.client;
    }
  }

  // Handle authentication errors
  String _handleAuthError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An unexpected error occurred. Please try again.';
  }

  // Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate password strength
  bool isValidPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$')
        .hasMatch(password);
  }

  // Check if password matches confirmation
  bool doPasswordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  // Mock data for testing
  static void addMockUser(UserModel user) {
    _mockUsers[user.email] = user;
  }

  static void clearMockUsers() {
    _mockUsers.clear();
    _currentUser = null;
    _authStateController.add(null);
  }

  static List<UserModel> getAllMockUsers() {
    return _mockUsers.values.toList();
  }

  // Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
