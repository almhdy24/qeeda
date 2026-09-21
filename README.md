# Qeeda / قيدة

Personal financial transaction journal for Android — offline-first, Arabic-first.

## What is Qeeda?

Qeeda is a lightweight local app for recording and reviewing personal financial transactions. Designed for everyday use with Arabic-first RTL UI.

You can:
- Manually enter income, expenses, and debt records
- Share a WhatsApp message or screenshot directly to Qeeda to review and save transactions
- Search and filter your transaction history
- View monthly income/expense summaries with category breakdown
- Export your data as CSV

## MVP Capabilities

- Manual transaction entry (income / expense / debt receivable / debt payable)
- Dashboard: total balance, income, expenses, recent transactions
- Transaction list grouped by date with search and filter
- Transaction detail, edit, delete (with confirmation dialog)
- Receive shared text → auto-extract amount, type, party, date → review screen
- Receive shared images → attempt Latin-script OCR → review screen
- Monthly statistics with category breakdown
- CSV export via Android share sheet
- App ID: `com.elmahdi.qeeda`

## Offline-First

All data is stored locally in SQLite. No internet connection is required. No data is sent anywhere.

## Privacy

No cloud sync. No analytics. No advertising. No accounts. All financial data stays on-device.

## Share / Import

### Text sharing (WhatsApp, SMS, etc.)

1. Open WhatsApp → share a message
2. Choose قيدة from the share sheet
3. Review extracted data, edit fields, save

Supported patterns: `150,000 جنيه`, `Received 150000 SDG from Ahmed`, `دفعت 25,000`, etc.

### Image sharing

1. Share a screenshot to Qeeda
2. OCR attempts to extract numbers and Latin text (Arabic text not reliably recognized)
3. Review, fill missing fields, save

## OCR Limitations

- Uses Google ML Kit Latin-script OCR (bundled, no internet needed)
- **Arabic text in images is NOT reliably recognized** — amounts and Latin text extracted where possible
- If OCR fails, shows image and allows full manual entry

## How to Run

```bash
flutter pub get
flutter run
```

Requires Flutter 3.41.9+ and Android device/emulator (minSdk 23).

## How to Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## flutter analyze

```
flutter analyze   # No issues found
```

## Known Limitations

1. Arabic OCR in images not supported (Latin/numbers only)
2. `flutter test` fails on Termux host (missing `libvk_swiftshader.so` Vulkan renderer — environment limitation, not a code issue)
3. Currency fixed at SDG for MVP
4. Export only (no CSV import/restore)
5. No app lock / biometric authentication in MVP
6. Physical share-sheet testing requires real Android device

## Next Steps

1. App lock with `local_auth` (biometric/PIN)
2. Arabic OCR support via a compatible ML model
3. CSV import/restore
