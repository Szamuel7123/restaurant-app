import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  static const double taxRate = 0.15; // 15% tax rate
  static const double deliveryBaseFee = 5.0; // Base delivery fee
  static const double deliveryFeePerKm = 2.0; // Additional fee per kilometer
  static const _uuid = Uuid();

  // USSD-specific constants
  static const int maxVerificationAttempts = 10;
  static const Duration verificationInterval = Duration(seconds: 5);

  // Paystack configuration
  // ============================================
  // IMPORTANT: Replace these with your actual keys from Paystack Dashboard
  // Test Key: Get from https://dashboard.paystack.com/#/settings/developer
  // Live Key: Get from https://dashboard.paystack.com/#/settings/developer
  // ============================================
  static const String paystackTestSecretKey =
      'sk_test_6bdc56f6c5c31e2598e19f761c0f87ba3cbdc1a5'; // Test key for development
  static const String paystackLiveSecretKey =
      'sk_live_...'; // 👈 Replace with your live key when going to production
  static const bool isProduction = false; // Keep false for testing
  // ============================================

  static String get paystackSecretKey =>
      isProduction ? paystackLiveSecretKey : paystackTestSecretKey;

  static Future<void> initializePaystack() async {
    // This method is no longer used in the new implementation
  }

  static double calculateDeliveryFee(double distanceInKm) {
    return deliveryBaseFee + (distanceInKm * deliveryFeePerKm);
  }

  static double calculateTax(double subtotal) {
    return subtotal * taxRate;
  }

  static double calculateTotal({
    required double subtotal,
    required double deliveryFee,
    required String orderType,
  }) {
    double tax = calculateTax(subtotal);
    // No delivery fee for pickup or dine-in
    if (orderType == 'Pickup' || orderType == 'Dine-in') {
      return subtotal + tax;
    }
    return subtotal + tax + deliveryFee;
  }

  static Map<String, dynamic> getPaymentMethods() {
    return {
      'Card': {
        'icon': Icons.credit_card,
        'description': 'Pay with credit/debit card',
        'enabled': true,
        'type': 'card',
      },
      'Paystack': {
        'icon': Icons.payment,
        'description': 'Pay with Paystack',
        'enabled': true,
        'type': 'paystack',
      },
      'Mobile Money': {
        'icon': Icons.phone_android,
        'description': 'Pay with mobile money',
        'enabled': true,
        'type': 'mobile_money',
      },
      'Cash': {
        'icon': Icons.money,
        'description': 'Pay with cash on delivery',
        'enabled': true,
        'type': 'cash',
      },
      'PayPal': {
        'icon': Icons.payment,
        'description': 'Pay with PayPal',
        'enabled': true,
        'type': 'paypal',
      },
      'Apple Pay': {
        'icon': Icons.apple,
        'description': 'Pay with Apple Pay',
        'enabled': true,
        'type': 'apple_pay',
      },
      'Google Pay': {
        'icon': Icons.g_mobiledata,
        'description': 'Pay with Google Pay',
        'enabled': true,
        'type': 'google_pay',
      },
    };
  }

  Future<void> initializePayment(double amount) async {
    try {
      await Stripe.instance.applySettings();
    } catch (e) {
      throw Exception('Failed to initialize payment: $e');
    }
  }

  Future<void> processPayment({required double amount}) async {
    try {
      // Create payment intent on your backend
      final paymentIntent = await _createPaymentIntent(amount: amount);

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Restaurant App',
          style: ThemeMode.system,
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(
      {required double amount}) async {
    try {
      final response = await http.post(
        Uri.parse('YOUR_BACKEND_URL/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY',
        },
        body: jsonEncode({
          'amount': (amount * 100).toInt(), // Convert to cents
          'currency': 'usd',
          'payment_method_types': ['card'],
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  static const Map<String, String> mobileMoneyNetworks = {
    'MTN': 'mtn',
    'Telecel': 'tel',
    'AirtelTigo': 'tgo',
  };

  Future<Map<String, dynamic>> processMobileMoneyPayment({
    required double amount,
    required String phoneNumber,
    required String network,
    required String email,
  }) async {
    try {
      // Generate a unique reference for the transaction
      final reference = _uuid.v4();

      // Initialize the transaction
      final initResult = await initializeMobileMoneyTransaction(
        amount: amount,
        phoneNumber: phoneNumber,
        network: network,
        email: email,
        reference: reference,
      );

      if (!initResult['success']) {
        throw Exception(initResult['error']);
      }

      // Start verification process
      final verificationResult = await _verifyMobileMoneyTransaction(
        reference: reference,
        network: network,
      );

      if (!verificationResult['success']) {
        throw Exception(verificationResult['error']);
      }

      return {
        'success': true,
        'reference': reference,
        'amount': amount,
        'network': network,
        'phoneNumber': phoneNumber,
        'verification_data': verificationResult['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': _getUserFriendlyErrorMessage(e.toString()),
      };
    }
  }

  Future<Map<String, dynamic>> initializeMobileMoneyTransaction({
    required double amount,
    required String phoneNumber,
    required String network,
    required String email,
    required String reference,
  }) async {
    final url = Uri.parse('https://api.paystack.co/transaction/initialize');
    final headers = {
      'Authorization': 'Bearer $paystackSecretKey',
      'Content-Type': 'application/json',
    };

    // Format phone number to ensure it starts with country code
    String formattedPhone = phoneNumber;
    if (!phoneNumber.startsWith('233')) {
      formattedPhone =
          '233${phoneNumber.startsWith('0') ? phoneNumber.substring(1) : phoneNumber}';
    }

    final body = jsonEncode({
      'email': email,
      'amount': (amount * 100).toInt(), // Convert to pesewas
      'reference': reference,
      'currency': 'GHS',
      'channels': ['mobile_money'],
      'mobile_money': {
        'phone': formattedPhone,
        'provider': mobileMoneyNetworks[network]?.toLowerCase(),
      },
      'callback_url':
          'https://your-callback-url.com/verify', // Replace with your callback URL
    });

    final response = await http.post(url, headers: headers, body: body);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      return {
        'success': true,
        'reference': data['data']['reference'],
        'authorization_url': data['data']['authorization_url'],
        'access_code': data['data']['access_code'],
      };
    } else {
      return {
        'success': false,
        'error':
            data['message'] ?? 'Failed to initialize mobile money transaction',
      };
    }
  }

  Future<Map<String, dynamic>> _verifyMobileMoneyTransaction({
    required String reference,
    required String network,
  }) async {
    final url =
        Uri.parse('https://api.paystack.co/transaction/verify/$reference');
    final headers = {
      'Authorization': 'Bearer $paystackSecretKey',
      'Content-Type': 'application/json',
    };

    int attempts = 0;
    while (attempts < maxVerificationAttempts) {
      final response = await http.get(url, headers: headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final status = data['data']['status'];
        if (status == 'success') {
          return {
            'success': true,
            'data': {
              'status': status,
              'reference': reference,
              'network': network,
              'amount': data['data']['amount'] / 100, // Convert from pesewas
              'timestamp': data['data']['paid_at'],
              'gateway_response': data['data']['gateway_response'],
            },
          };
        } else if (status == 'failed') {
          return {
            'success': false,
            'error': data['data']['gateway_response'] ?? 'Payment failed',
          };
        }
      }

      attempts++;
      if (attempts < maxVerificationAttempts) {
        await Future.delayed(verificationInterval);
      }
    }

    return {
      'success': false,
      'error':
          'Payment verification timed out. Please check your order status.',
    };
  }

  Future<Map<String, dynamic>> processPayPalPayment({
    required double amount,
    required String currency,
  }) async {
    // Implement PayPal payment logic
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    return {
      'success': true,
      'transactionId': _uuid.v4(),
      'amount': amount,
    };
  }

  Future<Map<String, dynamic>> processPaystackPayment({
    required double amount,
    required String email,
    required String reference,
    required BuildContext context,
  }) async {
    try {
      // Initialize the transaction
      final initResult = await initializePaystackTransaction(
        amount: amount,
        email: email,
        reference: reference,
        paystackSecretKey: paystackSecretKey,
      );

      if (!initResult['success']) {
        throw Exception(initResult['error']);
      }

      // Launch the authorization URL
      final authorizationUrl = initResult['authorization_url'];
      if (authorizationUrl != null) {
        final uri = Uri.parse(authorizationUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch payment URL');
        }
      }

      // Start verification process
      final verificationResult = await _verifyTransactionWithRetry(
        reference: reference,
        paystackSecretKey: paystackSecretKey,
      );

      if (!verificationResult['success']) {
        throw Exception(verificationResult['error']);
      }

      return {
        'success': true,
        'reference': reference,
        'amount': amount,
        'verification_data': verificationResult['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': _getUserFriendlyErrorMessage(e.toString()),
      };
    }
  }

  Future<Map<String, dynamic>> initializePaystackTransaction({
    required double amount,
    required String email,
    required String reference,
    required String paystackSecretKey,
  }) async {
    final url = Uri.parse('https://api.paystack.co/transaction/initialize');
    final headers = {
      'Authorization': 'Bearer $paystackSecretKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'email': email,
      'amount': (amount * 100).toInt(), // Paystack expects amount in kobo
      'reference': reference,
      'currency': 'GHS',
    });

    final response = await http.post(url, headers: headers, body: body);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      return {
        'success': true,
        'authorization_url': data['data']['authorization_url'],
        'access_code': data['data']['access_code'],
        'reference': data['data']['reference'],
      };
    } else {
      return {
        'success': false,
        'error': data['message'] ?? 'Failed to initialize transaction',
      };
    }
  }

  Future<Map<String, dynamic>> verifyPaystackTransaction({
    required String reference,
    required String paystackSecretKey,
  }) async {
    final url =
        Uri.parse('https://api.paystack.co/transaction/verify/$reference');
    final headers = {
      'Authorization': 'Bearer $paystackSecretKey',
      'Content-Type': 'application/json',
    };
    final response = await http.get(url, headers: headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      return {
        'success': true,
        'data': data['data'],
      };
    } else {
      return {
        'success': false,
        'error': data['message'] ?? 'Failed to verify transaction',
      };
    }
  }

  Future<Map<String, dynamic>> initializePaystackUSSD({
    required double amount,
    required String email,
    required String reference,
    required String paystackSecretKey,
  }) async {
    final url = Uri.parse('https://api.paystack.co/transaction/initialize');
    final headers = {
      'Authorization': 'Bearer $paystackSecretKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'email': email,
      'amount': (amount * 100).toInt(), // Paystack expects amount in kobo
      'reference': reference,
      'currency': 'GHS',
      'channels': ['ussd'], // Specify USSD as the payment channel
    });

    final response = await http.post(url, headers: headers, body: body);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      final ussdCode = data['data']['authorization']['ussd_code'];
      return {
        'success': true,
        'ussd_code': ussdCode,
        'reference': data['data']['reference'],
        'access_code': data['data']['access_code'],
      };
    } else {
      return {
        'success': false,
        'error': data['message'] ?? 'Failed to initialize USSD payment',
      };
    }
  }

  Future<Map<String, dynamic>> processPaystackUSSD({
    required double amount,
    required String email,
    required String reference,
  }) async {
    try {
      // Initialize USSD payment
      final initResult = await initializePaystackUSSD(
        amount: amount,
        email: email,
        reference: reference,
        paystackSecretKey: paystackSecretKey,
      );

      if (!initResult['success']) {
        throw Exception(initResult['error']);
      }

      // Launch USSD code
      final launched = await launchUSSDCode(initResult['ussd_code']);
      if (!launched) {
        throw Exception('Failed to launch USSD code. Please try again.');
      }

      // Start verification process
      final verificationResult = await _verifyTransactionWithRetry(
        reference: initResult['reference'],
        paystackSecretKey: paystackSecretKey,
      );

      if (!verificationResult['success']) {
        throw Exception(verificationResult['error']);
      }

      return {
        'success': true,
        'reference': initResult['reference'],
        'amount': amount,
        'verification_data': verificationResult['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': _getUserFriendlyErrorMessage(e.toString()),
      };
    }
  }

  Future<Map<String, dynamic>> _verifyTransactionWithRetry({
    required String reference,
    required String paystackSecretKey,
  }) async {
    int attempts = 0;
    while (attempts < maxVerificationAttempts) {
      final result = await verifyPaystackTransaction(
        reference: reference,
        paystackSecretKey: paystackSecretKey,
      );

      if (result['success']) {
        final status = result['data']['status'];
        if (status == 'success') {
          return result;
        } else if (status == 'failed') {
          return {
            'success': false,
            'error': 'Payment failed. Please try again.',
          };
        }
      }

      attempts++;
      if (attempts < maxVerificationAttempts) {
        await Future.delayed(verificationInterval);
      }
    }

    return {
      'success': false,
      'error':
          'Payment verification timed out. Please check your order status.',
    };
  }

  String _getUserFriendlyErrorMessage(String error) {
    if (error.contains('network')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (error.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (error.contains('USSD')) {
      return 'USSD service unavailable. Please try again later.';
    } else if (error.contains('insufficient')) {
      return 'Insufficient funds. Please try a different payment method.';
    } else {
      return 'Payment failed. Please try again or use a different payment method.';
    }
  }

  Future<bool> launchUSSDCode(String ussdCode) async {
    try {
      // Format the USSD code for launching
      final formattedCode = ussdCode.replaceAll('#', '%23');
      final uri = Uri.parse('tel:$formattedCode');

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch USSD code');
      }
    } catch (e) {
      throw Exception('Failed to launch USSD code: ${e.toString()}');
    }
  }
}
