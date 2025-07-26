import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  // Check auth state and load user data
  Future<void> checkAuthState() async {
    final user = _auth.currentUser;
    if (user != null) {
      // User is logged in, ensure user data exists in Firestore
      await _ensureUserDataExists(user);
    }
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
      // Create user with Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user');
      }

      // Create user document in Firestore
      final userModel = UserModel(
        id: user.uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toFirestore());

      // Store user role in secure storage
      await _secureStorage.write(
        key: 'user_role',
        value: role.toString().split('.').last,
      );

      // Store user ID in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.uid);

      return userModel;
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
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in');
      }

      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final userModel = UserModel.fromFirestore(userDoc);

      // Update last login time
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });

      // Store user role in secure storage
      await _secureStorage.write(
        key: 'user_role',
        value: userModel.role.toString().split('.').last,
      );

      // Store user ID in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.uid);

      return userModel;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();

      // Clear secure storage
      await _secureStorage.deleteAll();

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
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
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final updates = <String, dynamic>{};
      if (fullName != null) updates['fullName'] = fullName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firestore.collection('users').doc(user.uid).update(updates);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Get user role
  Future<UserRole> getUserRole() async {
    try {
      final roleString = await _secureStorage.read(key: 'user_role');
      if (roleString == null) return UserRole.client;

      return UserRole.values.firstWhere(
        (role) => role.toString().split('.').last == roleString,
        orElse: () => UserRole.client,
      );
    } catch (e) {
      return UserRole.client;
    }
  }

  // Ensure user data exists in Firestore
  Future<void> _ensureUserDataExists(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        // Create basic user data if it doesn't exist
        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          fullName: user.displayName ?? 'User',
          phoneNumber: user.phoneNumber,
          role: UserRole.client,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toFirestore());
      }
    } catch (e) {
      // Handle error silently
      developer.log('Error ensuring user data exists: $e', name: 'AuthService');
    }
  }

  // Handle authentication errors
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        case 'operation-not-allowed':
          return 'This operation is not allowed.';
        default:
          return 'Authentication failed: ${error.message}';
      }
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
}
