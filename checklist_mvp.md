# Checklist MVP — RutinKu (Pertemuan Ke-7)

Finalisasi MVP, Integrasi Advanced Features, & Uji Regresi. Tanggal eksekusi terakhir: **30 Oktober 2026**.

## 1. Checklist Fitur Inti MVP

| No | Fitur Inti | Implementasi | Status |
|---|---|---|---|
| 1 | Manajemen Kebiasaan (CRUD) | `HabitRepository`, `HabitNotifier`, `AddHabitBottomSheet`, `EditHabitBottomSheet`, hapus + undo, templat & *habit stacking* | ✅ Selesai |
| 2 | Check-in Harian & Perhitungan Streak | `toggleCheckIn` (*optimistic UI*), `HabitModel.streakCount`, mode istirahat/refleksi mood | ✅ Selesai |
| 3 | Kalender / Riwayat Kebiasaan | `CalendarScreen` (`table_calendar`, marker check-in & pratinjau foto momen per hari) | ✅ Selesai |
| 4 | Penyimpanan Lokal `SharedPreferences` | `HabitRepository` — data bertahan setelah aplikasi dimulai ulang (`rutinku_habits`) | ✅ Selesai |
| 5 | Pengingat Notifikasi Lokal | `NotificationService` (`flutter_local_notifications` & `timezone`, jadwal harian, *cancel*, izin Android 13/14+ aman) | ✅ Selesai |
| 6 | Kamera / Visual Habit Journal ("Abadikan Momen") | `CameraHelper` (`image_picker` & `path_provider`), penyimpanan foto permanen ke `HabitRecord.momentImagePath` | ✅ Selesai |
| 7 | Autentikasi Pengguna 3 Halaman (Supabase Auth) | `AuthService` + `LoginScreen` (`/login`), `RegisterScreen` (`/register`), dan `ForgotPasswordScreen` (`/forgot-password` via `resetPasswordForEmail`) | ✅ Selesai |
| 8 | Cloud Sync Supabase JSONB (Fetch, Backup, & Restore) | `SyncRepository` (`fetchHabitsFromCloud`, `backupHabitsToCloud`, `restoreHabitsFromCloud` pada tabel PostgreSQL `user_data`) + `SyncNotifier` + `SyncScreen` | ✅ Selesai |

## 2. Checklist Penanganan Edge Cases

| No | Edge Case | Penanganan | Lokasi | Status |
|---|---|---|---|---|
| 1 | Input tidak valid — nama kosong | Validator `TextFormField`: *"Nama kebiasaan tidak boleh kosong"* | `add_habit_bottom_sheet.dart`, `edit_habit_bottom_sheet.dart` | ✅ |
| 2 | Input tidak valid — hanya spasi (*whitespace*) | `value.trim().isEmpty` → pesan yang sama | idem | ✅ |
| 3 | Input tidak valid — terlalu pendek | Validator: *"Minimal 3 karakter"* (setelah `trim`) | idem | ✅ |
| 4 | Validasi form Autentikasi (Login, Register, Reset) | Validasi format email, panjang password minimal 6 karakter, dan kecocokan *Password* dengan *Konfirmasi Password* | `login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart` | ✅ |
| 5 | Gagal simpan / ubah / autentikasi / sinkronisasi | `SnackBar` merah berisi pesan error, state dikembalikan (*rollback* pada operasi lokal) | layar Auth, `SyncScreen`, `HabitNotifier` | ✅ |
| 6 | Empty State — Dashboard | Ikon + teks *"Belum ada rutinitas. Yuk, buat kebiasaan pertamamu!"* + petunjuk tombol `+` | `dashboard_screen.dart` | ✅ |
| 7 | Empty State — Kalender | Ikon + teks *"Belum ada kebiasaan yang dibuat."* + petunjuk | `calendar_screen.dart` | ✅ |
| 8 | Empty State — Sync | *"Data di cloud masih kosong"* + tombol *Tarik Ulang Data* & tombol *Backup* tetap aktif | `sync_screen.dart` | ✅ |
| 9 | Loading State | `CircularProgressIndicator` (Dashboard, Kalender, tombol Auth/Backup) dan *"Menyinkronkan data..."* (Sync) | semua layar utama & autentikasi | ✅ |
| 10 | Error State | Ikon peringatan + pesan error (Dashboard, Kalender, Sync) | semua layar utama | ✅ |
| 11 | Fitur Retry | Tombol **Coba Lagi** (`retryFetch()` / `SyncNotifier.retry()`) | Dashboard, Kalender, Sync | ✅ |
| 12 | Izin notifikasi ditolak / error | Setiap `requestNotificationsPermission()` & `requestExactAlarmsPermission()` dibungkus `try-catch` terpisah; tidak *crash* dan tidak menghambat alur utama | `notification_service.dart` | ✅ |
| 13 | Kamera dibatalkan / izin kamera ditolak | `CameraHelper.takePicture()` mengembalikan `null` secara aman di dalam `try-catch` tanpa membuat aplikasi *crash* | `camera_helper.dart`, `dashboard_screen.dart` | ✅ |
| 14 | Layar pendek / *overflow* | Form autentikasi & *empty state* dibungkus `SingleChildScrollView` | layar Auth, Dashboard, Kalender | ✅ |

## 3. Daftar Lengkap Unit & Widget Test

Pengujian Cloud Sync dan layar sinkronisasi dijalankan secara terisolasi menggunakan `MockSyncRepository` berbasis paket **`mocktail`** sehingga tidak menembak server Supabase sungguhan saat pengujian otomatis.

| No | File | Skenario | Status |
|---|---|---|---|
| **checkin_test.dart** (16 test) | | | |
| 1 | `checkin_test.dart` | HabitModel supports records, isCompletedOn, and copyWith | ✅ PASSED |
| 2 | `checkin_test.dart` | HabitModel serialization toMap, fromMap, toJson, and fromJson | ✅ PASSED |
| 3 | `checkin_test.dart` | HabitModel streakCount dynamic calculation with today grace period | ✅ PASSED |
| 4 | `checkin_test.dart` | HabitModel weeklyProgress dynamic calculation | ✅ PASSED |
| 5 | `checkin_test.dart` | HabitModel parses legacy completedDates gracefully | ✅ PASSED |
| 6 | `checkin_test.dart` | HabitRepository persists data across restarts in SharedPreferences | ✅ PASSED |
| 7 | `checkin_test.dart` | HabitRepository toggleCheckIn & updateHabit with copyWith & restoreHabit | ✅ PASSED |
| 8 | `checkin_test.dart` | toggleCheckIn performs optimistic update and toggles check-in status | ✅ PASSED |
| 9 | `checkin_test.dart` | deleteHabit and restoreHabit work in HabitNotifier | ✅ PASSED |
| 10 | `checkin_test.dart` | NotificationService is a singleton | ✅ PASSED |
| 11 | `checkin_test.dart` | HabitRepository schedules and cancels reminders gracefully | ✅ PASSED |
| 12 | `checkin_test.dart` | HabitModel streakCount preserves streak when a day is marked as rest | ✅ PASSED |
| 13 | `checkin_test.dart` | HabitRepository updateRecordDetails adds and modifies mood/status/note | ✅ PASSED |
| 14 | `checkin_test.dart` | HabitNotifier updateHabitRecord updates state optimistically | ✅ PASSED |
| 15 | `checkin_test.dart` | HabitRepository supports adding and updating habit with parentHabitId | ✅ PASSED |
| 16 | `checkin_test.dart` | HabitNotifier supports parentHabitId in addHabit and updateHabit | ✅ PASSED |
| **api_sync_test.dart** (7 test — `MockSyncRepository` dengan `mocktail`) | | | |
| 17 | `api_sync_test.dart` | 1. Model Valid: `HabitModel.fromMap` dengan map JSON benar | ✅ PASSED |
| 18 | `api_sync_test.dart` | 2. Model Invalid: tipe data salah melempar TypeError/Exception | ✅ PASSED |
| 19 | `api_sync_test.dart` | 3. Cloud Sync Sukses: `fetchData` memanggil `fetchHabitsFromCloud` → state berisi `List<HabitModel>` dari cloud | ✅ PASSED |
| 20 | `api_sync_test.dart` | 4. Data Kosong: `fetchData` dengan cloud kosong menghasilkan `AsyncData` list kosong (panjang 0) | ✅ PASSED |
| 21 | `api_sync_test.dart` | 5. Request Gagal: `MockSyncRepository` melempar Exception (mis. belum login / server error) → state menjadi `AsyncError` & `retry()` memanggil ulang repository | ✅ PASSED |
| 22 | `api_sync_test.dart` | 6. JSON Rusak: `MockSyncRepository` melempar `FormatException` saat data JSONB cloud rusak → state menjadi `AsyncError` berisi `FormatException` | ✅ PASSED |
| 23 | `api_sync_test.dart` | Bonus: `backupData` memanggil `backupHabitsToCloud` (`true` jika sukses) dan `restoreData` menimpa data lokal via `restoreHabitsFromCloud` serta memuat ulang state | ✅ PASSED |
| **sync_screen_test.dart** (4 test — `MockSyncRepository` dengan `mocktail`) | | | |
| 24 | `sync_screen_test.dart` | SyncScreen renders loading state initially when fetching | ✅ PASSED |
| 25 | `sync_screen_test.dart` | SyncScreen renders Empty State when cloud returns empty list & Backup button triggers refresh | ✅ PASSED |
| 26 | `sync_screen_test.dart` | SyncScreen renders Success State with ListView, active account email, and Backup button | ✅ PASSED |
| 27 | `sync_screen_test.dart` | SyncScreen renders Error State with warning icon and Coba Lagi button | ✅ PASSED |
| **template_screen_test.dart** (4 test) | | | |
| 28 | `template_screen_test.dart` | renders categories, items, and custom option correctly | ✅ PASSED |
| 29 | `template_screen_test.dart` | tapping template item returns Map with title and category | ✅ PASSED |
| 30 | `template_screen_test.dart` | tapping Buat Kebiasaan Sendiri returns custom string | ✅ PASSED |
| 31 | `template_screen_test.dart` | selecting template pre-fills AddHabitBottomSheet on DashboardScreen | ✅ PASSED |
| **widget_test.dart** (1 test) | | | |
| 32 | `widget_test.dart` | Dashboard UI States (loading → empty state) & Form Validation (nama kosong) | ✅ PASSED |
| **edge_cases_test.dart** (9 test — Pertemuan Ke-7) | | | |
| 33 | `edge_cases_test.dart` | AddHabit: menolak nama kebiasaan kosong | ✅ PASSED |
| 34 | `edge_cases_test.dart` | AddHabit: menolak nama yang hanya berisi spasi | ✅ PASSED |
| 35 | `edge_cases_test.dart` | AddHabit: menolak nama kurang dari 3 karakter | ✅ PASSED |
| 36 | `edge_cases_test.dart` | AddHabit: nama valid tidak menampilkan pesan error | ✅ PASSED |
| 37 | `edge_cases_test.dart` | EditHabit: menolak ketika nama dikosongkan | ✅ PASSED |
| 38 | `edge_cases_test.dart` | EditHabit: menolak ketika nama hanya berisi spasi | ✅ PASSED |
| 39 | `edge_cases_test.dart` | CalendarScreen menampilkan empty state saat data kosong | ✅ PASSED |
| 40 | `edge_cases_test.dart` | NotificationService.requestPermission tidak melempar exception | ✅ PASSED |
| 41 | `edge_cases_test.dart` | init lalu requestPermission berulang tetap aman | ✅ PASSED |

**Total: 41 test — 41 PASSED, 0 FAILED.**

## 4. Hasil Eksekusi Terminal Terbaru

Dijalankan dari folder `rutinku_flutter` (Flutter 3.47.5 / Dart 3.13.4):

```text
$ flutter analyze
Analyzing rutinku_flutter...
No issues found! (ran in 5.4s)

$ flutter test
00:06 +41: All tests passed!
```

| Perintah | Hasil |
|---|---|
| `flutter analyze` | ✅ No issues found! |
| `flutter test` | ✅ 41 / 41 PASSED (All tests passed!) |
