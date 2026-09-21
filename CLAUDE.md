# CLAUDE.md — Qeeda Project Rules

## Project

Flutter Android app: personal financial transaction journal.
App ID: `com.elmahdi.qeeda`
App name: قيدة (Qeeda)
Min SDK: 23

## Core Rules

- **Offline-first**: no network calls for any core feature
- **No AI APIs**: no LLM, no cloud AI
- **No Firebase, no analytics, no ads, no cloud sync**
- **No accounts or authentication required for basic use**
- **All data in local SQLite** via sqflite
- **Arabic RTL**: primary UI language is Arabic, locale = ar
- **No unnecessary dependencies**: only add a package if it cannot be done simply with Flutter SDK

## Architecture

- State management: `ChangeNotifier` + `QeedaScope` (InheritedNotifier) — no Riverpod/Bloc/GetX
- Database: `DatabaseHelper` singleton, sqflite
- Share receiving: native Android `MethodChannel` in `MainActivity.kt`
- Text parsing: `ParserService` — deterministic, no LLM
- OCR: `OcrService` wrapping `google_mlkit_text_recognition` (Arabic + Latin, graceful fallback to manual entry)
- Export: `ExportService` → CSV via `share_plus`

## Important Constraints

- `Transaction` model name conflicts with sqflite's `Transaction`. Always use `hide Transaction` when importing sqflite.
- Import intl with `show DateFormat` to avoid `TextDirection` conflict with Flutter's TextDirection.
- `DropdownButtonFormField` uses `initialValue` (not `value` — deprecated in Flutter 3.33+).
- Monetary amounts are always `int` (SDG, no decimals in MVP).
- Debt transactions (debtReceivable/debtPayable) do NOT affect cash balance.

## Test Environment Limitation

`flutter test` fails on Termux/Android host because `flutter_tester` requires `libvk_swiftshader.so` (Vulkan renderer) which is unavailable. Use `flutter analyze` for static validation. Physical device testing required for widget/integration tests.

## Before Declaring Completion

1. `flutter analyze` — must pass with no issues
2. `flutter build apk --release` — must succeed
3. No secrets or keystores committed
4. README.md and CLAUDE.md present
