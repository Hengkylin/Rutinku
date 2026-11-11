# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

RutinKu is an Android-focused Flutter habit tracker (Dart `^3.13.4`). The Flutter project lives in `rutinku_flutter/`; the repo root only holds docs (`README.md`, `HowToRun.md`, `ARCHITECTURE.md`, `checklist_mvp.md`, `docs/` practicum reports). `rutinku_flutter/Architecture.md` is a copy of the root `ARCHITECTURE.md` — keep both in sync if you edit one.

UI strings, code comments, docs and commit messages are written in **Indonesian**. Commits follow Conventional Commits with an Indonesian subject, e.g. `refactor(profile): ProfileRepository fokus ke request API`.

## Commands

Run everything from `rutinku_flutter/`:

```bash
flutter pub get
flutter run                                   # or: flutter run -d <device_id>
flutter analyze                               # expected: "No issues found!"
flutter test                                  # full suite
flutter test test/profile_form_test.dart      # single file
flutter test --plain-name "nama kosong"       # single test by name substring
```

Android build needs JDK 17 and NDK `28.2.13676358`; `android/gradle.properties` sets `kotlin.incremental=false` (works around cross-drive Kotlin cache errors on Windows) and core library desugaring is enabled for `flutter_local_notifications`. Lints: `flutter_lints` with platform folders excluded.

## Architecture

Layering under `lib/`: `screens/` + `widgets/` (UI) → `notifiers/` (Riverpod state) → `repositories/` (data access) → `services/` (Supabase Auth wrapper, local notifications). Supabase URL and publishable key are hardcoded in `main.dart`, which also initializes notifications before `runApp(ProviderScope(App()))`.

- **Startup/routing:** `App` picks `LoginScreen` or `MainScreen` from `Supabase.instance.client.auth.currentUser` (`MaterialApp.home`, so `/` is intentionally not in `AppRoutes.routes`). `App(home: ...)` exists as a test override. `MainScreen` is a bottom-nav shell (Dashboard / Calendar / Profile) driven by a legacy `StateProvider`.
- **Habits are local-first.** `HabitRepository` stores the whole habit list as one JSON string in `SharedPreferences` under `rutinku_habits`, and also (re)schedules reminders via the `NotificationService` singleton on save. `HabitNotifier` (`AsyncNotifier`) does optimistic updates. Streaks are computed on the fly in `HabitModel` from `HabitRecord`s (`status`: `completed` / `skipped` / `rest`; `rest` preserves the streak, the current day has a grace period).
- **Cloud sync is a snapshot, not live sync.** `SyncRepository` upserts `{ "habits": "<local JSON string>" }` into the `sync_data` JSONB column of Supabase table `user_data` (`onConflict: 'user_id'`). Restore writes it back to `SharedPreferences`, then `SyncNotifier` calls `ref.invalidate(habitNotifierProvider)` so the dashboard reloads.
- **Profile feature does not use Riverpod.** Responsibilities are split deliberately and should stay that way:
  - `ProfileForm` (widget): input fields + loading/error UI only; normalizes input with `Validators` before calling the repository.
  - `Validators` (`utils/validators.dart`): pure input rules (normalize, name/phone validation). No validation belongs in the repository.
  - `ProfileRepository`: Supabase `users` table update + local cache; maps errors to user-facing `Exception`s. If the table is missing (`42P01` / `PGRST205`) the request is simulated with a delay.
  - Repositories are injected via constructor (`ProfileScreen(repository:)`, `ProfileForm(repository:)`).
- **Shared UI helpers:** use `showAppSnackBar` (`widgets/app_snackbar.dart`) for snackbars instead of building `SnackBar`s inline. Colors (e.g. navy `0xFF1E293B`, lime `0xFFD9F99D`) are currently redeclared per file; there is no central theme/color class yet.

## Testing patterns

Tests must never hit real Supabase or device plugins:
- Call `SharedPreferences.setMockInitialValues({})` in `setUp` for anything touching local storage.
- Riverpod-backed features: override providers, e.g. `syncRepositoryProvider.overrideWithValue(MockSyncRepository())` (mocktail) in a `ProviderContainer` or `ProviderScope`.
- Non-Riverpod features (profile): pass a fake subclass through the constructor (see `FakeProfileRepository` in `test/profile_form_test.dart`).
- Widgets are located by `Key`s such as `profile_name_field`, `profile_save_button`; keep these stable.
