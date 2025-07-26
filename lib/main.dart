import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart';
import 'providers/app_providers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/client/client_main_screen.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/constants.dart';
import 'utils/performance_monitor.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  developer.log('Handling a background message: ${message.messageId}',
      name: 'FirebaseMessaging');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PerformanceMonitor.startTimer('App Initialization');

  // Initialize Firebase (this is required and blocking)
  try {
    PerformanceMonitor.startTimer('Firebase Initialization');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    PerformanceMonitor.endTimer('Firebase Initialization');
    developer.log('Firebase initialized successfully', name: 'Main');
  } catch (e) {
    PerformanceMonitor.endTimer('Firebase Initialization');
    developer.log('Firebase initialization failed: $e', name: 'Main');
  }

  // Initialize Firebase Messaging (non-blocking)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Hive (this is required and blocking)
  try {
    PerformanceMonitor.startTimer('Hive Initialization');
    await HiveService.initialize();
    PerformanceMonitor.endTimer('Hive Initialization');
    developer.log('Hive initialized successfully', name: 'Main');
  } catch (e) {
    PerformanceMonitor.endTimer('Hive Initialization');
    developer.log('Hive initialization failed: $e', name: 'Main');
  }

  // Initialize Notification Service (non-blocking)
  try {
    final notificationService = NotificationService();
    notificationService.initialize().catchError((e) {
      developer.log('Notification service initialization failed: $e',
          name: 'Main');
    });
  } catch (e) {
    developer.log('Notification service setup failed: $e', name: 'Main');
  }

  PerformanceMonitor.endTimer('App Initialization');
  PerformanceMonitor.printSummary();

  runApp(const ProviderScope(child: RestaurantApp()));
}

class RestaurantApp extends ConsumerWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Restaurant App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      PerformanceMonitor.startTimer('Auth Check');
      // Check if user is logged in (with timeout)
      final authService = ref.read(authServiceProvider);
      await authService.checkAuthState().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          developer.log('Auth check timed out, continuing...',
              name: 'AuthWrapper');
        },
      );
      PerformanceMonitor.endTimer('Auth Check');

      PerformanceMonitor.startTimer('Theme Loading');
      // Load theme preference (with timeout)
      final themeService = ref.read(themeServiceProvider);
      await themeService.loadThemePreference().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          developer.log('Theme loading timed out, using default...',
              name: 'AuthWrapper');
        },
      );
      PerformanceMonitor.endTimer('Theme Loading');

      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      developer.log('App initialization error: $e', name: 'AuthWrapper');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    if (_hasError) {
      return ErrorScreen(
        error: _errorMessage,
        onRetry: () {
          setState(() {
            _isLoading = true;
            _hasError = false;
          });
          _initializeApp();
        },
      );
    }

    final authState = ref.watch(authStateProvider);
    final currentUser = ref.watch(currentUserProvider);

    return authState.when(
      data: (firebaseUser) {
        if (firebaseUser == null) {
          return const LoginScreen();
        }

        // Use currentUserProvider to get UserModel with role
        return currentUser.when(
          data: (userModel) {
            if (userModel == null) {
              return const LoginScreen();
            }

            // Redirect to admin if user has the admin role (e.g., email ends with @admin.com)
            if (userModel.email.endsWith('@admin.com')) {
              return const AdminMainScreen();
            } else {
              return const ClientMainScreen();
            }
          },
          loading: () => const SplashScreen(),
          error: (error, stack) => ErrorScreen(
            error: error.toString(),
            onRetry: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _initializeApp();
            },
          ),
        );
      },
      loading: () => const SplashScreen(),
      error: (error, stack) => ErrorScreen(
        error: error.toString(),
        onRetry: () {
          setState(() {
            _isLoading = true;
            _hasError = false;
          });
          _initializeApp();
        },
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorScreen({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
