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

Layering under `lib/`: `screens/` + `widgets/` (UI) → `notifiers/` (Riverpod state) → `repositories/` (data access) → `services/` (Supabase Auth wrapper, local notifications, `AnalyticsService`). Supabase URL and publishable key are hardcoded in `main.dart`, which also initializes notifications before `runApp(ProviderScope(App()))`.

- **Startup/routing:** `App` (stateful) picks `LoginScreen` or `MainScreen` from `AuthService.currentUser` (`MaterialApp.home`, so `/` is intentionally not in `AppRoutes.routes`). `App(home:, authService:)` exist as test overrides. `App` owns a global `navigatorKey` and listens to `AuthService.onAuthStateChange` **for errors only**: link errors from emails (`otp_expired`/`access_denied`, missing PKCE code verifier) become a red SnackBar via `AuthService.linkErrorMessage()`; other errors are ignored. It deliberately does **not** navigate on `AuthChangeEvent.passwordRecovery` — `verifyOTP(type: recovery)` emits that event too, and `VerifyResetCodeScreen` already opens the new-password screen (navigating in both places opened it twice). Supabase's auth stream is a `ReplaySubject` (old events replay to new listeners). `MainScreen` is a bottom-nav shell (Tugas / Kalender / Analitik / Milikku → Dashboard, Calendar, Analytics, Profile) driven by a legacy `StateProvider` index.
- **Habits are local-first.** `HabitRepository` stores the whole habit list as one JSON string in `SharedPreferences` under `rutinku_habits`, and also (re)schedules reminders via the `NotificationService` singleton on save. `HabitNotifier` (`AsyncNotifier`) does optimistic updates. Streaks are computed on the fly in `HabitModel` from `HabitRecord`s (`status`: `completed` / `pending` / `skipped` / `rest`; `rest` preserves the streak, the current day has a grace period). "Done" always goes through `isCompletedOn()`: `targetValue == 1` → status `completed`; `targetValue > 1` (progressive habit) → `currentValue >= targetValue`.
- **Record mutations live in `HabitModel`** (`toggleCheckIn`, `incrementProgress`) and return a new model via `copyWith`. Both `HabitNotifier` (optimistic state) and `HabitRepository` (persistence) call the same method, so don't re-implement record logic in either layer, and never rebuild a `HabitRecord` from scratch (it drops `currentValue`/mood/photo).
- **Habit fields:** `HabitModel.targetValue` (default 1) and `unit` (nullable), `HabitRecord.currentValue` (default 0). `fromMap` falls back to these defaults so old JSON (and old cloud backups) still load — keep that when adding fields.
- **Analytics is pure Dart in `AnalyticsService`** (`services/analytics_service.dart`): most consistent habit (30-day completion rate, tie-break `streakCountOn(now)`), most missed weekday (28 days, `rest` and days without records not counted), weekly completion rates and their delta. It takes an injectable `now` so tests are date-independent; `AnalyticsScreen` (fl_chart `BarChart`) only renders its results. Put new statistics in the service, not in widgets.
- **Auth goes through `AuthService`** (`services/auth_service.dart`, `GoTrueClient` injectable via constructor): `login`, `register`, `resetPassword`, `verifyRecoveryCode` (`verifyOTP(type: OtpType.recovery)`), `updatePassword` (`updateUser(UserAttributes(password:))`), `onAuthStateChange`, plus static error mappers `linkErrorMessage` / `recoveryCodeErrorMessage`. Screens never call `Supabase.instance.client.auth` directly.
  - The Supabase project requires email confirmation (`mailer_autoconfirm: false`), so `signUp` returns no session: `RegisterScreen` shows the "cek email" dialog and routes to Login instead of the dashboard.
  - **Password reset uses a 6-digit email OTP, not a link** (links were consumed before the click and always failed with `otp_expired`). Flow: `ForgotPasswordScreen` → `VerifyResetCodeScreen(email:)` → `pushReplacement` `UpdatePasswordScreen` → dashboard. Screens are pushed with `MaterialPageRoute` so the injected `AuthService` is passed along; there is no `/update-password` named route.
  - **Dashboard-only config the code depends on** (not visible in the repo): the *Reset password* email template must contain `{{ .Token }}` and no `{{ .ConfirmationURL }}`; the OTP length must be 6 (`Validators.otpLength`); **Site URL** = `io.supabase.rutinku://login-callback/`, which must match the `intent-filter` in `android/app/src/main/AndroidManifest.xml` (used by signup-verification links). The default Supabase SMTP sends max 2 emails/hour, to team members only — keep that in mind when testing.
  - Debug auth on a device with `adb logcat | grep supabase` (look for `Notifying exception AuthException(...)`).
- **Cloud sync is a snapshot, not live sync.** `SyncRepository` upserts `{ "habits": "<local JSON string>" }` into the `sync_data` JSONB column of Supabase table `user_data` (`onConflict: 'user_id'`). Restore writes it back to `SharedPreferences`, then `SyncNotifier` calls `ref.invalidate(habitNotifierProvider)` so the dashboard reloads.
- **Profile feature does not use Riverpod.** Responsibilities are split deliberately and should stay that way:
  - `ProfileForm` (widget): input fields + loading/error UI only; normalizes input with `Validators` before calling the repository.
  - `Validators` (`utils/validators.dart`): pure input rules. No validation belongs in the repository.
  - `ProfileRepository`: Supabase `users` table update + local cache; maps errors to user-facing `Exception`s. If the table is missing (`42P01` / `PGRST205`) the request is simulated with a delay.
  - Repositories are injected via constructor (`ProfileScreen(repository:)`, `ProfileForm(repository:)`).
- **Single source for input rules:** `Validators` holds every rule (name, phone, target value, email, password ≥ 6 chars and not trimmed, password confirmation, 6-digit OTP code). Screens pass `Validators.validateX` as `validator:` — don't inline regexes or length checks again.
- **Shared UI helpers:** use `showAppSnackBar` (`widgets/app_snackbar.dart`) for snackbars instead of building `SnackBar`s inline; `authInputDecoration()` (`widgets/auth_input_decoration.dart`) for auth text fields; `AuthHeader` (`widgets/auth_header.dart`) for the icon/title/subtitle header on auth screens. Colors (e.g. navy `0xFF1E293B`, lime `0xFFD9F99D`) are currently redeclared per file; there is no central theme/color class yet.

## Testing patterns

Tests must never hit real Supabase or device plugins:
- Call `SharedPreferences.setMockInitialValues({})` in `setUp` for anything touching local storage.
- Riverpod-backed features: override providers, e.g. `syncRepositoryProvider.overrideWithValue(MockSyncRepository())` (mocktail) in a `ProviderContainer` or `ProviderScope`.
- Non-Riverpod features (profile): pass a fake subclass through the constructor (see `FakeProfileRepository` in `test/profile_form_test.dart`).
- Auth: inject `MockAuthService` into screens/`App`, or `MockGoTrueClient` into `AuthService(client:)` (both mocktail). Drive auth events with a `StreamController<AuthState>` returned from the mocked `onAuthStateChange` (see `test/auth_screens_test.dart`). A route that should show a SnackBar after navigation must have a `Scaffold`.
- Date-dependent logic: pass a fixed `now` (see `test/analytics_service_test.dart`, reference date Wed 2026-11-11) instead of relying on `DateTime.now()`.
- Bottom sheets are taller than the 800×600 test viewport; call `tester.ensureVisible(...)` before tapping their save buttons.
- Widgets are located by `Key`s such as `profile_name_field`, `profile_save_button`, `habit_increment_<id>`, `analytics_weekly_delta`, `forgot_password_submit_button`, `reset_code_field`, `reset_code_resend_button`, `update_password_field`, `register_verify_email_ok`; keep these stable.
