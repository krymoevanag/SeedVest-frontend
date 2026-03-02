# SeedVest Mobile

A premium micro-investment and savings management application built with Flutter.

## ✨ Features

- **🔒 Secure Session Termination**: Immediate logout with server-side token blacklisting.
- **⏲️ Inactivity Auto-Logout**: Automatic logout after 10 minutes of inactivity with a 60-second warning countdown.
- **☝️ Biometric Authentication**: Login securely using Fingerprint or Face ID.
- **📊 Financial Analytics**: Track your contributions and group investments with real-time insights.
- **🔔 Notification Center**: Stay updated with group broadcasts, contribution approvals, and system alerts.
- **💸 Contribution Management**: Propose and track contributions via M-Pesa or automated bank transfers.

## 🛠️ Tech Stack

- **Framework**: Flutter
- **State Management**: Provider
- **Networking**: Dio (with JWT interceptors)
- **Local Storage**: Flutter Secure Storage & Cache Service
- **Deep Linking**: AppLinks for password resets and activation.

## 🚀 Getting Started

1. **Clone the repository**
2. **Setup Environment**:
   Create a `.env` file in the root directory:
   ```env
   API_URL=https://your-api-url.com/api/
   ```
3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
4. **Run the App**:
   ```bash
   flutter run
   ```

## 🔐 Security Information

The application implements a robust security layer:
- **Sensitive Data**: All authentication tokens are stored in encrypted system storage.
- **Session Lifecycle**: Sessions are strictly managed both locally and on the server. Inactivity is monitored globally, and the `InactivityService` ensures that the app is locked down if left idle.
- **Navigation Safety**: Navigation history is purged upon logout to prevent backward access to protected routes.
