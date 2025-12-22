# Smart POS & Full Inventory Management App

A comprehensive Point of Sale (POS) and Inventory Management system built with Flutter for the Mobile Application Development Final Lab Task.

## Overview

Smart POS is a mobile application designed to help businesses manage their inventory, process sales transactions, and track business analytics efficiently. The app features offline-first architecture with Firebase cloud synchronization.

## Features

### Implemented (Commit 1)
- ✅ **User Authentication**
  - Email/Password authentication with Firebase
  - Google Sign In integration
  - Password reset functionality
  - User session management
  - Remember me functionality
  
- ✅ **Modern UI/UX**
  - Professional POS-themed color scheme (blues and greens)
  - Custom splash screen
  - Responsive design
  - Loading states and error handling
  - Form validation with real-time feedback
  - Password strength indicator

- ✅ **Offline Support**
  - SQLite local database
  - Sync queue for offline operations
  - Connectivity detection

### Planned Features
- 📋 Product Management
  - Add, edit, delete products
  - Barcode scanning
  - Product categories
  - Stock management

- 💰 Point of Sale
  - Quick sale interface
  - Shopping cart
  - Multiple payment methods
  - Receipt generation

- 📊 Reports & Analytics
  - Sales reports
  - Inventory reports
  - Revenue analytics
  - Export functionality

- 👥 User Management
  - Role-based access control
  - Employee management
  - Activity logs

## Technology Stack

### Frontend
- **Flutter** - Cross-platform UI framework
- **Provider** - State management solution

### Backend & Database
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - Cloud database
- **SQLite** - Local offline database

### Additional Libraries
- `firebase_core` - Firebase SDK
- `firebase_auth` - Firebase authentication
- `cloud_firestore` - Firestore database
- `sqflite` - SQLite database
- `path` - File path utilities
- `connectivity_plus` - Network connectivity
- `google_sign_in` - Google authentication
- `flutter_spinkit` - Loading animations
- `fluttertoast` - Toast notifications
- `email_validator` - Email validation

## Project Structure

```
SmartPOS/lib/
├── main.dart                          # App entry point
├── config/
│   ├── routes.dart                    # App navigation routes
│   └── theme.dart                     # App theme configuration
├── models/
│   └── user_model.dart                # User data model
├── screens/
│   ├── splash_screen.dart             # Splash screen
│   ├── auth/
│   │   ├── login_screen.dart          # Login screen
│   │   ├── signup_screen.dart         # Sign up screen
│   │   └── forgot_password_screen.dart # Password reset screen
│   └── home/
│       └── home_screen.dart           # Home dashboard
├── services/
│   ├── auth_service.dart              # Authentication service
│   └── database_service.dart          # SQLite database service
├── providers/
│   └── auth_provider.dart             # Authentication state management
├── widgets/
│   ├── custom_text_field.dart         # Custom input field widget
│   ├── custom_button.dart             # Custom button widget
│   └── loading_widget.dart            # Loading indicator widget
└── utils/
    ├── constants.dart                 # App constants
    └── validators.dart                # Form validators
```

## Setup Instructions

### Prerequisites
- Flutter SDK (^3.9.2)
- Dart SDK
- Android Studio / VS Code
- Firebase account
- Android/iOS device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd FA23-BSE-030-Gulfam-Ali/SmartPOS
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration** (See detailed steps below)
   - Create a Firebase project
   - Add Android/iOS app to Firebase
   - Download configuration files
   - Enable Authentication and Firestore

4. **Run the app**
   ```bash
   flutter run
   ```

## Firebase Setup Instructions

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: "SmartPOS" (or your preferred name)
4. Follow the setup wizard

### Step 2: Add Android App
1. In Firebase Console, click "Add App" → Android
2. Enter package name: `com.example.smartpos` (from `android/app/build.gradle`)
3. Download `google-services.json`
4. Place it in `android/app/` directory

### Step 3: Add iOS App (Optional)
1. In Firebase Console, click "Add App" → iOS
2. Enter bundle ID from `ios/Runner.xcodeproj`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

### Step 4: Enable Authentication
1. In Firebase Console → Authentication → Sign-in method
2. Enable "Email/Password"
3. Enable "Google" (optional)

### Step 5: Create Firestore Database
1. In Firebase Console → Firestore Database
2. Click "Create Database"
3. Start in **test mode** (for development)
4. Choose a location

### Step 6: Update Android Build Configuration

**File: `android/build.gradle`**
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**File: `android/app/build.gradle`**
```gradle
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

## Development Guidelines

### Code Style
- Follow Flutter/Dart style guide
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

### State Management
- Use Provider for state management
- Separate business logic from UI
- Handle loading and error states

### Error Handling
- Catch and handle all exceptions
- Provide user-friendly error messages
- Log errors for debugging

## Building for Release

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Testing

Run tests:
```bash
flutter test
```

## Screenshots

*Screenshots will be added in future commits*

## Team/Author Information

- **Student Name**: Gulfam Ali
- **Registration**: FA23-BSE-030
- **Course**: Mobile Application Development
- **Project**: Final Lab Task - Smart POS System

## License

This project is created for educational purposes as part of the Mobile Application Development course.

## Acknowledgments

- Flutter Documentation
- Firebase Documentation
- Course instructors and teaching assistants

## Changelog

### Commit 1 - Project Setup & Authentication (Current)
- ✅ Created project structure
- ✅ Added dependencies
- ✅ Implemented authentication system
- ✅ Created custom widgets
- ✅ Setup Firebase integration
- ✅ Added offline database support
- ✅ Implemented splash screen
- ✅ Created README documentation

### Future Commits
- Product management features
- POS transaction system
- Reports and analytics
- User management
- Advanced features

## Contact

For queries or support, please contact through the course portal.

---

**Note**: This is a work in progress. Features will be added incrementally in future commits.
