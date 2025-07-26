# Restaurant App

A comprehensive restaurant management application built with Flutter, featuring separate interfaces for clients and administrators with modern UI design and robust functionality.

## 🍽️ Features

### Client Features
- **User Authentication**: Secure login/signup with email and password
- **Menu Browsing**: Browse restaurant menu with categories and search
- **Order Management**: Add items to cart, modify quantities, and place orders
- **Table Booking**: Reserve tables with date and time selection
- **Order Tracking**: Real-time order status updates
- **Payment Integration**: Multiple payment methods support
- **Profile Management**: Update personal information and preferences
- **Theme Switching**: Light/Dark mode support
- **Responsive Design**: Works on Android, iOS, and Web

### Admin Features
- **Dashboard**: Overview of orders, bookings, and revenue
- **Menu Management**: Add, edit, and remove menu items
- **Order Management**: View and update order statuses
- **Table Management**: Manage table availability and bookings
- **User Management**: View customer information and order history
- **Analytics**: Sales reports and customer insights
- **Settings**: Restaurant configuration and preferences

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd retaurant
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication, Firestore, Storage, and Analytics
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the respective platform folders

4. **Configure Firebase**
   - Update Firebase configuration in `lib/firebase_options.dart`
   - Set up Firestore security rules
   - Configure Authentication providers

5. **Run the app**
   ```bash
   flutter run
   ```

## 📱 App Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── user_model.dart
│   ├── menu_item_model.dart
│   ├── order_model.dart
│   └── table_booking_model.dart
├── providers/                # State management
│   └── app_providers.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── theme_service.dart
│   └── hive_service.dart
├── screens/                  # UI screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── client/
│   │   └── client_main_screen.dart
│   ├── admin/
│   │   └── admin_main_screen.dart
│   └── splash_screen.dart
├── widgets/                  # Reusable components
│   ├── custom_button.dart
│   └── custom_text_field.dart
└── utils/                    # Utilities
    └── constants.dart
```

## 🎨 Design System

### Colors
- **Primary**: Orange (#E65100)
- **Secondary**: Green (#2E7D32)
- **Accent**: Deep Orange (#FF6F00)
- **Background**: Light Gray (#FAFAFA)
- **Surface**: White (#FFFFFF)

### Typography
- **Font Family**: Poppins
- **Weights**: Regular (400), Medium (500), SemiBold (600), Bold (700)

### Components
- **Custom Button**: Elevated and outlined variants with loading states
- **Custom Text Field**: Form inputs with validation and icons
- **Custom Search Field**: Search functionality with clear button
- **Animated Components**: Smooth transitions and micro-interactions

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:
```
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
STRIPE_PUBLISHABLE_KEY=your_stripe_key
```

### Firebase Security Rules
```javascript
// Firestore Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Menu items are readable by all authenticated users
    match /menu/{itemId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Orders
    match /orders/{orderId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Bookings
    match /bookings/{bookingId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
  }
}
```

## 📊 Database Schema

### Users Collection
```json
{
  "id": "user_id",
  "email": "user@example.com",
  "fullName": "John Doe",
  "phoneNumber": "+1234567890",
  "role": "client|admin",
  "createdAt": "timestamp",
  "lastLoginAt": "timestamp",
  "isActive": true,
  "profileImageUrl": "url",
  "preferences": {}
}
```

### Menu Items Collection
```json
{
  "id": "item_id",
  "name": "Grilled Salmon",
  "description": "Fresh salmon with herbs",
  "price": 24.99,
  "category": "mainCourse",
  "imageUrl": "url",
  "isAvailable": true,
  "isVegetarian": false,
  "isVegan": false,
  "isGlutenFree": true,
  "allergens": ["fish"],
  "customizations": {},
  "preparationTime": 15,
  "rating": 4.5,
  "reviewCount": 10,
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "createdBy": "admin_id"
}
```

### Orders Collection
```json
{
  "id": "order_id",
  "userId": "user_id",
  "userName": "John Doe",
  "tableNumber": "A1",
  "items": [
    {
      "menuItemId": "item_id",
      "name": "Grilled Salmon",
      "price": 24.99,
      "quantity": 2,
      "customizations": {},
      "specialInstructions": "No salt",
      "totalPrice": 49.98
    }
  ],
  "subtotal": 49.98,
  "tax": 4.99,
  "tip": 7.50,
  "total": 62.47,
  "status": "pending|confirmed|preparing|ready|delivered|cancelled|completed",
  "paymentStatus": "pending|paid|failed|refunded",
  "paymentMethod": "cash|card|mobilePayment|online",
  "orderTime": "timestamp",
  "estimatedDeliveryTime": "timestamp",
  "actualDeliveryTime": "timestamp",
  "specialInstructions": "Extra napkins",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "createdBy": "user_id"
}
```

### Bookings Collection
```json
{
  "id": "booking_id",
  "userId": "user_id",
  "userName": "John Doe",
  "userPhone": "+1234567890",
  "tableNumber": "A1",
  "tableSize": "medium",
  "numberOfGuests": 4,
  "bookingDate": "timestamp",
  "bookingTime": {
    "hour": 19,
    "minute": 30
  },
  "durationMinutes": 120,
  "status": "pending|confirmed|cancelled|completed|noShow",
  "specialRequests": "Window seat",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "createdBy": "user_id"
}
```

## 🔐 Security Features

- **Authentication**: Firebase Auth with email/password
- **Role-based Access**: Admin and client permissions
- **Secure Storage**: Sensitive data encrypted locally
- **Input Validation**: Form validation and sanitization
- **Session Management**: Automatic logout after inactivity
- **Audit Trail**: All actions logged for review

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support, email support@restaurantapp.com or create an issue in the repository.

## 🔄 Version History

- **v1.0.0** - Initial release with basic functionality
- **v1.1.0** - Added table booking feature
- **v1.2.0** - Enhanced admin dashboard
- **v1.3.0** - Payment integration
- **v1.4.0** - Real-time notifications
- **v1.5.0** - Web platform support

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Google Fonts for typography
- All contributors and testers

---

**Note**: This is a comprehensive restaurant management app with both client and admin interfaces. The app is designed to be scalable, secure, and user-friendly across multiple platforms.
"# restaurant-app" 
