# DriveLog - Drive Tracking Flutter App

A modern Flutter application for tracking driving trips with real-time statistics and drive scoring.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── theme/
│   ├── app_colors.dart      # Color definitions
│   └── app_theme.dart       # Theme configuration
├── models/
│   ├── app_user.dart        # User model
│   └── trip.dart            # Trip model
├── services/
│   ├── auth_service.dart    # Firebase authentication
│   ├── auth_provider.dart   # Auth state management
│   ├── trip_service.dart    # Trip Firestore operations
│   └── trip_provider.dart   # Trip state management
├── screens/
│   ├── login_screen.dart    # Authentication screen
│   ├── home_screen.dart     # Main home with live tracking
│   ├── trip_detail_screen.dart  # Trip details
│   ├── stats_screen.dart    # Statistics view
│   ├── history_screen.dart  # Trip history
│   └── profile_screen.dart  # User profile
└── widgets/
    ├── live_card.dart       # Live tracking card component
    └── trip_card.dart       # Trip list card component
```

## Features

- 🔐 Firebase Authentication (Email/Password)
- 📍 Real-time trip tracking
- 📊 Drive statistics and scoring
- 💾 Firestore database for trip storage
- 🎨 Modern dark theme UI
- 📱 Bottom navigation for easy access

## Setup Instructions

### 1. Firebase Configuration

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication (Email/Password)
3. Create a Firestore database in test mode
4. Get your Firebase configuration and update `lib/firebase_options.dart`

### 2. Android Setup

1. Add your `google-services.json` to `android/app/`
2. Update `firebase_options.dart` with Android credentials

### 3. iOS Setup

1. Add your `GoogleService-Info.plist` to `ios/Runner/`
2. Update `firebase_options.dart` with iOS credentials

### 4. Install Dependencies

```bash
flutter pub get
```

### 5. Run the App

```bash
flutter run
```

## Firebase Firestore Structure

### Users Collection
```
users/
  {uid}/
    - email: string
    - displayName: string
    - photoUrl: string
    - createdAt: timestamp
    - updatedAt: timestamp
```

### Trips Collection
```
trips/
  {tripId}/
    - userId: string
    - date: timestamp
    - distanceKm: number
    - durationMinutes: number
    - maxSpeedKmh: number
    - avgSpeedKmh: number
    - hardBrakes: number
    - driveScore: string (A, B, C, etc.)
    - createdAt: timestamp
```

## State Management

The app uses Provider for state management:

- **AuthProvider**: Handles authentication state and user info
- **TripProvider**: Manages trip data and Firestore operations

## Theme

The app uses a dark theme with custom colors:
- Primary: `#2A5CFF` (Blue)
- Background: `#0D0D0D` (Black)
- Surface: `#1A1A1A` (Dark Gray)
- Success: `#4ADE80` (Green)
- Warning: `#FACC15` (Yellow)
- Error: `#F87171` (Red)

## Next Steps

- [ ] Implement GPS tracking for real-time location
- [ ] Add map view for trip routes
- [ ] Implement drive scoring algorithm
- [ ] Add photo sharing for trips
- [ ] Implement push notifications
- [ ] Add trip filtering and search
- [ ] Create detailed analytics dashboard

