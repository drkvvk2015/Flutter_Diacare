# 🏥 DiaCare - Advanced Healthcare Management Platform

<div align="center">

**Enterprise-grade diabetes care and telemedicine solution**

[![Flutter](https://img.shields.io/badge/Flutter-3.3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

</div>

---

## 📋 Overview

**DiaCare** is a comprehensive healthcare management platform built with Flutter, specifically designed for diabetes care. It provides seamless telemedicine capabilities, health monitoring, and patient management for healthcare professionals and patients.

### 🎯 Key Highlights

- 🏥 **Multi-Role Support**: Doctor, Patient, Admin, and Pharmacy dashboards
- 📹 **Video Consultations**: Real-time video calls with Agora RTC
- 💊 **E-Prescriptions**: Digital prescription generation with PDF export
- 📊 **Health Analytics**: Advanced charting and health data visualization
- 🔐 **Enterprise Security**: End-to-end encryption and biometric authentication
- 📱 **Cross-Platform**: Android, iOS, and Web support
- 🌐 **Offline Support**: Local caching with Hive database

---

## ✨ Features

### 👨‍⚕️ Doctor Features
- **Patient Management**: Comprehensive patient list with medical history
- **Video Consultations**: HD video calls with screen sharing
- **E-Prescriptions**: Create, edit, and share digital prescriptions
- **Appointment Scheduling**: Advanced calendar management
- **Health Analytics**: Patient health trends and insights
- **Payment Tracking**: Razorpay integration for consultation fees

### 🤒 Patient Features
- **Quick Appointment Booking**: Book consultations in seconds
- **Health Monitoring**: Track vitals, steps, blood glucose, blood pressure
- **Device Integration**: Connect Bluetooth health devices
- **Video Consultations**: Join secure video calls with doctors
- **Prescription Access**: View and download prescriptions
- **Exercise Library**: Video-guided exercise programs

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.3.0 or higher
- Firebase CLI
- Android Studio / Xcode

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/diacare.git
cd flutter_diacare

# Install dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Configuration

1. **Firebase Setup**: Copy your `firebase_options.dart` or run `flutterfire configure`
2. **Environment Variables**: Create `.env` file from `.env.example`
3. **API Keys**: Add Agora, Razorpay, and other API keys to `.env`

---

## 🏗️ Architecture

```
lib/
├── features/          # Feature modules (auth, telemedicine, payments)
├── models/           # Data models (Hive & Firebase)
├── providers/        # State management (Provider pattern)
├── screens/          # UI screens (35+ screens)
├── services/         # Business logic services
├── utils/            # Utilities and helpers
├── widgets/          # Reusable widgets
└── main.dart         # App entry point
```

---

## 🔐 Security

- End-to-end encryption for sensitive data
- Biometric authentication support
- Firebase Authentication with secure token management
- HIPAA-compliant data handling
- ProGuard obfuscation for Android

---

## 📦 Build for Production

### Android
```bash
# Configure signing in android/key.properties
flutter build appbundle --release
```

### iOS
```bash
flutter build ipa --release
```

### Web
```bash
flutter build web --release
```

---

## 📄 License

This project is proprietary software. All rights reserved.

Copyright © 2025 DiaCare Health Solutions

---

## 📞 Support

For support, email support@diacare.health

---

**Made with ❤️ using Flutter**
