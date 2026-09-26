# SeedVest Mobile

The mobile application is the Flutter client for SeedVest and provides access to the platform’s group, finance, profile, and notification workflows.

## Core mobile capabilities

- Member authentication and session persistence
- Biometric login and local security controls
- Group dashboard and membership experience
- Contribution, loan, and repayment tracking
- Savings history and member financial profile views
- Statement PDF download for member financial reporting
- Notification center and account settings

## Tech stack

- Flutter
- Provider state management
- Dio for networking
- Flutter Secure Storage for session data
- App links and platform deep linking support

## Getting started

```bash
cd seedvest_mobile
flutter pub get
flutter run
```

The app expects the backend API base URL to be configured through the app config layer and platform build definitions.

## Financial profile flow

The app currently includes a member financial profile screen and API client methods that consume backend endpoints such as:

- `finance/members/<member_id>/financial-profile/`
- `finance/members/<member_id>/savings-history/`
- `finance/reports/member-statement-pdf/`

This is the mobile-side contract for the financial profile module already implemented on the backend.

## Security notes

- Access tokens are stored securely.
- Session timeout and logout handling are enforced in the app lifecycle.
- Sensitive finance screens must keep their API access aligned with the backend permission rules.

## Notes for contributors

When changing finance payloads or member profile data, ensure the API serializer contract and Flutter model parsing remain aligned. The app relies on stable response keys and permissions to render accurate profile, history, and report data.
