# Budget Tracker

Offline-first Flutter starter for Android and iOS. Uses SQLite for records and SharedPreferences for the theme preference.

## Included
- Dashboard with month selector, income, expenses, balance, budget summary and recent transactions
- Add/edit/delete transactions with categories, date, payment method, notes and recurring flag
- Monthly budget records by category
- Six-month expense chart
- Light and dark themes persisted locally
- Local notification shown after a transaction is saved
- JSON backup export and local data clearing
- Privacy policy and terms pages in Settings

## Run
1. Install Flutter and Android Studio or Xcode.
2. Extract this folder and open it in VS Code.
3. Run `flutter pub get`.
4. Run `flutter doctor` and resolve platform setup issues.
5. Run `flutter run`.

## Important implementation notes
This is a functional starter, not a claim that every item in the supplied specification is complete. Bills and savings-goal tables are created but their management screens, automated recurring processing, scheduled daily/threshold notifications, CSV/PDF report export, backup restore, biometric lock, custom categories, transfer handling and full test coverage still need implementation before production release. The recurring field is stored as metadata only; it does not generate future transactions. Notification permissions and platform-specific setup must be tested on real devices.

Before publishing, replace the placeholder legal contact language with real publisher details and have the legal text reviewed. A mobile app does not need a website favicon; if you create a companion website, add its favicon and publish privacy/terms pages there too. No “Made with AI” label is included. App icon assets should be generated and configured for Android/iOS before release.
