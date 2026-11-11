# Arsitektur Sistem — RutinKu (Mobile Habit Tracker)

Dokumen ini menjelaskan rancangan arsitektur, tumpukan teknologi (*tech stack*), alur sistem, skema penyimpanan data, dan struktur proyek untuk aplikasi *mobile* **RutinKu**.

## 1. Tumpukan Teknologi (*Tech Stack*)
* **Frontend (Mobile):** Flutter (Material 3 UI Toolkit).
* **Bahasa Pemrograman:** Dart (`^3.13.4`, mendukung *Null Safety* & *Object-Oriented*).
* **State Management:** Riverpod (`flutter_riverpod` — `AsyncNotifier` & `Notifier` untuk manajemen *state* reaktif).
* **Penyimpanan Lokal:** `shared_preferences` (`SharedPreferences` untuk persistensi data kebiasaan harian di perangkat).
* **Backend & Database (BaaS):** Supabase (`supabase_flutter` — **Supabase Auth** untuk autentikasi pengguna & **PostgreSQL JSONB** pada tabel `user_data` untuk Cloud Sync).
* **Sistem Notifikasi Lokal:** `flutter_local_notifications` & `timezone` (penjadwalan pengingat harian sesuai zona waktu lokal pengguna).
* **Kamera & Penyimpanan Media:** `image_picker` & `path_provider` (fitur *Visual Habit Journal* / *"Abadikan Momen"*).
* **Kalender & Pengujian:** `table_calendar`, `intl`, serta `flutter_test` & `mocktail` untuk pengujian unit/widget terisolasi.
* **Visualisasi Data:** `fl_chart` (`BarChart` untuk grafik Komparasi Mingguan pada fitur *Habit Analytics*).

## 2. Alur Sistem (*System Flow*)
1. **Autentikasi Penuh (Supabase Auth):** Aplikasi memeriksa sesi aktif (`AuthService.currentUser`). Jika pengguna belum masuk (`currentUser == null`), aplikasi menampilkan `LoginScreen` (`/login`). Sesi login dikelola otomatis oleh SDK `supabase_flutter`. Semua pemanggilan Supabase Auth lewat **`AuthService`** (`services/auth_service.dart`), yang menerima `GoTrueClient` lewat konstruktor agar bisa diganti *mock* saat pengujian.
   * **Register + Verifikasi Email** — `RegisterScreen` (`/register`) memanggil `signUp`. Project Supabase mewajibkan konfirmasi email (`mailer_autoconfirm: false`), sehingga `signUp` tidak mengembalikan sesi; layar menampilkan dialog wajib *"Silakan cek email Anda untuk verifikasi"* lalu mengarahkan ke Login (bukan ke Beranda). Jika suatu saat "Confirm email" dimatikan di Supabase, sesi langsung aktif dan pengguna masuk ke Beranda.
   * **Lupa Password** — `ForgotPasswordScreen` (`/forgot-password`) memanggil `AuthService.resetPassword(email)` → `resetPasswordForEmail(email, redirectTo: AuthService.authRedirectUrl)`, lalu menampilkan SnackBar hijau *"Link reset telah dikirim ke email Anda"*.
   * **Reset Password via Deep Link** — link di email membuka aplikasi lewat `io.supabase.rutinku://login-callback/` (lihat [bagian 5](#5-konfigurasi-deep-link--supabase-dashboard)). SDK menukar kode PKCE menjadi sesi recovery dan memancarkan `AuthChangeEvent.passwordRecovery`. `App` (`app.dart`) berlangganan `AuthService.onAuthStateChange` dan, saat event tersebut datang, mendorong rute `/update-password` lewat `navigatorKey` global. Stream Supabase adalah `ReplaySubject` (event lama diputar ulang), sehingga `App` menjaga agar layar tidak dibuka dua kali; error pada stream diabaikan agar aplikasi tidak *crash*.
   * **Password Baru** — `UpdatePasswordScreen` (`/update-password`) memvalidasi password baru (minimal 6 karakter) dan konfirmasinya (harus sama), memanggil `AuthService.updatePassword()` → `updateUser(UserAttributes(password: ...))`, menampilkan SnackBar sukses, lalu ke Beranda (sesi recovery sudah login).
2. **Manajemen Kebiasaan Lokal (CRUD & Optimistic UI):** Seluruh operasi pembuatan, pembaruan, *check-in* harian, pencatatan refleksi mood/istirahat, dan penghapusan kebiasaan dikelola secara reaktif oleh `HabitNotifier` dan disimpan secara persisten di penyimpanan lokal menggunakan `SharedPreferences` (key: `rutinku_habits`).
3. **Sinkronisasi Cloud (Supabase JSONB):** Melalui `SyncScreen` → `SyncNotifier` → `SyncRepository`, pengguna dapat menarik pratinjau data dari *cloud* (**Fetch**), mencadangkan seluruh JSON kebiasaan lokal ke tabel PostgreSQL `user_data` menggunakan operasi `upsert` (**Backup**), atau memulihkan data dari *cloud* ke `SharedPreferences` lokal (**Restore**).
4. **Kalkulasi Streak Dinamis:** `HabitModel` menghitung jumlah *streak* harian secara dinamis berdasarkan riwayat `records` (`HabitRecord`), termasuk toleransi hari berjalan (*grace period*) dan pelestarian *streak* pada hari istirahat (`status: 'rest'`). Satu hari dianggap selesai lewat `isCompletedOn()`: target 1 → status `'completed'`; target > 1 → `currentValue >= targetValue`.
   * **Progressive Habit Tracking:** logika perubahan record ditulis sekali di `HabitModel` (`incrementProgress` dan `toggleCheckIn`, keduanya memakai `copyWith` sehingga mood/catatan/foto/progres tidak hilang), lalu dipakai bersama oleh `HabitNotifier` (*optimistic UI*) dan `HabitRepository` (persisten). Tombol **[+]** di `HabitCard` memanggil `incrementHabitProgress`; record baru berstatus `'pending'` dan otomatis menjadi `'completed'` saat target tercapai. `toggleCheckIn` membalik status `completed` ↔ `pending` dan menolak menandai selesai habit progresif yang belum mencapai target.
5. **Notifikasi Lokal & Visual Habit Journal:**
   * `NotificationService` menjadwalkan pengingat harian pada sistem operasi Android berdasarkan jam `reminderTime` tanpa bergantung pada *server push* eksternal.
   * `CameraHelper` menangkap foto melalui kamera perangkat dan menyimpannya secara permanen di direktori dokumen aplikasi, lalu menautkan path file ke `HabitRecord.momentImagePath`.
6. **Profil Pengguna:** `ProfileScreen` (tab keempat **Milikku** di `MainScreen` / `/profile`) memuat nilai awal dari cache lokal lalu menampilkan `ProfileForm`. Fitur ini tidak memakai Riverpod; repository dikirim lewat konstruktor agar mudah diganti saat pengujian. Tanggung jawab dipisah menjadi tiga bagian:
   * **`ProfileForm`** — hanya mengurus input dan status UI (validasi field, *loading*, SnackBar error via `showAppSnackBar`).
   * **`Validators`** — aturan input murni (lihat poin 8): nama wajib minimal 3 karakter, telepon opsional berupa angka minimal 10 digit.
   * **`ProfileRepository`** — hanya request API: `UPDATE` kolom `name` & `phone` pada tabel Supabase `users` untuk pengguna yang sedang login, lalu menyimpan cache lokal. Jika tabel `users` belum tersedia (kode `42P01` / `PGRST205`), request disimulasikan dengan `Future.delayed`. Error Auth/Postgrest diubah menjadi pesan `Exception` yang siap ditampilkan.
7. **Habit Analytics (*Exploratory Data Analysis*):** `AnalyticsScreen` (tab ketiga **Analitik** di `MainScreen`) membaca daftar kebiasaan dari `habitNotifierProvider`, lalu menyerahkan seluruh perhitungan statistik ke **`AnalyticsService`** (`services/analytics_service.dart`). Layar hanya menampilkan hasil; tidak ada rumus statistik di widget.
   * **`AnalyticsService(habits, now: ...)`** — kelas Dart murni (tanpa UI, Riverpod, maupun penyimpanan). Tanggal acuan `now` dapat diinjeksi (default: hari ini) sehingga hasil uji tidak bergantung pada tanggal dijalankan. Definisi "selesai" selalu memakai `HabitModel.isCompletedOn()`, jadi habit progresif ikut dihitung dengan benar.
   * `getMostConsistentHabit()` — habit dengan persentase hari selesai tertinggi dalam 30 hari terakhir; jika seri, dipilih *streak* tertinggi (`HabitModel.streakCountOn(now)`).
   * `getMostMissedDay()` — nama hari (mis. `"Selasa"`) dengan record gagal terbanyak dalam 4 minggu terakhir. Hari libur (`'rest'`) tidak dihitung gagal; hari tanpa record juga tidak dihitung.
   * `getWeeklyCompletionRates()` & `getWeeklyProgressComparison()` — persentase penyelesaian gabungan (hari selesai ÷ jumlah habit × 7) untuk hari ke-1..7 dan ke-8..14 mundur dari hari ini, serta selisihnya (positif = membaik).
   * Tampilan: 2 kartu ringkasan (Paling Konsisten & Hari Sering Terlewat), `BarChart` (`fl_chart`) dua batang "Minggu Lalu" vs "Minggu Ini" (skala 0–100%), dan teks selisih berwarna hijau/merah.
8. **Aturan Input & Komponen UI Bersama (DRY):** aturan dan tampilan yang sebelumnya disalin di beberapa layar kini ditulis sekali:
   * **`Validators`** (`utils/validators.dart`) — satu-satunya sumber aturan input: `normalize`/`normalizeOptional`, `validateName`, `validatePhone`, `validateTargetValue`/`parseTargetValue`, `validateEmail`, `validatePassword` (minimal 6 karakter, tidak di-trim), dan `validatePasswordConfirmation`. Dipakai oleh Login, Register, Lupa Password, Password Baru, `ProfileForm`, dan `HabitTargetFields`; tidak ada regex atau aturan panjang yang ditulis ulang di layar.
   * **`authInputDecoration()`** (`widgets/auth_input_decoration.dart`) — gaya `TextFormField` seragam untuk keempat layar autentikasi.
   * **`AuthHeader`** (`widgets/auth_header.dart`) — header ikon + judul + deskripsi untuk layar Lupa Password dan Password Baru.
   * **`showAppSnackBar()`** (`widgets/app_snackbar.dart`) — SnackBar seragam (merah untuk error, hijau untuk sukses) di semua layar.

## 3. Skema Penyimpanan Data

### A. Penyimpanan Lokal (`SharedPreferences`)
Key utama: `rutinku_habits` (berisi string JSON array dari daftar `HabitModel`).

* **`HabitModel`:**
  * `id` (`String`) — Identitas unik kebiasaan.
  * `title` (`String`) — Nama rutinitas/kebiasaan.
  * `category` (`String?`) — Kategori kebiasaan (mis. Kesehatan, Belajar, Kehidupan).
  * `reminderTime` (`String?`) — Jam pengingat harian dalam format `"HH:mm"`.
  * `parentHabitId` (`String?`) — Referensi ID kebiasaan induk untuk fitur *Habit Stacking*.
  * `targetValue` (`int`, default `1`) — Target angka harian (*Progressive Habit*); data lama tanpa field ini dibaca sebagai `1`.
  * `unit` (`String?`) — Satuan target (mis. `"gelas"`, `"menit"`, `"halaman"`).
  * `records` (`List<HabitRecord>`) — Riwayat pelaksanaan harian.
* **`HabitRecord`:**
  * `date` (`String`) — Tanggal pencatatan (`yyyy-MM-dd`).
  * `status` (`String`) — Status pelaksanaan (`'completed'`, `'pending'`, `'skipped'`, atau `'rest'`).
  * `currentValue` (`int`, default `0`) — Progres angka pada tanggal tersebut.
  * `mood` (`String?`) — Emoji suasana hati saat refleksi.
  * `note` (`String?`) — Catatan jurnal singkat pengguna.
  * `momentImagePath` (`String?`) — Path lokal foto hasil fitur *"Abadikan Momen"*.

Cache profil: `rutinku_profile_name` dan `rutinku_profile_phone` (dihapus jika telepon dikosongkan).

### B. Database Cloud (Supabase PostgreSQL — Tabel `user_data`)
Menggunakan strategi **Cloud Save JSONB** per pengguna:
* `user_id` (`UUID`, Primary Key / Unique, berelasi dengan pengguna pada **Supabase Auth**).
* `sync_data` (`JSONB`) — Menyimpan objek `{ "habits": "<localJsonString>" }` yang disinkronkan melalui `upsert(..., onConflict: 'user_id')`.

### C. Database Cloud (Supabase PostgreSQL — Tabel `users`)
Dipakai oleh fitur Profil:
* `id` (`UUID`) — ID pengguna Supabase Auth (filter `eq('id', userId)`).
* `name` (`text`) — Nama pengguna (sudah di-trim).
* `phone` (`text`, *nullable*) — Nomor telepon; `null` jika dikosongkan.

## 4. Struktur Direktori Proyek

Proyek ini mengadopsi arsitektur modular Flutter dengan pemisahan tanggung jawab (*Separation of Concerns*) berbasis Riverpod:

```text
rutinku_flutter/
│
├── lib/
│   ├── main.dart                         # Entri utama, inisialisasi Supabase, Notifikasi, & ProviderScope
│   ├── app.dart                          # Root MaterialApp, pengecekan sesi awal, navigatorKey, & listener passwordRecovery
│   │
│   ├── routes/                           # Manajemen navigasi terpusat
│   │   └── app_routes.dart               # Definisi rute (/login, /register, /forgot-password, /update-password, /dashboard, dll.)
│   │
│   ├── models/                           # Struktur cetak biru data & serialisasi JSON
│   │   ├── habit_model.dart              # HabitModel & HabitRecord (streak, progress, momentImagePath)
│   │   └── user_model.dart               # UserModel
│   │
│   ├── repositories/                     # Lapisan akses data (Lokal & Cloud)
│   │   ├── habit_repository.dart         # Operasi CRUD lokal di SharedPreferences & pemicu jadwal pengingat
│   │   ├── profile_repository.dart       # Request UPDATE profil ke tabel Supabase `users` & cache lokal
│   │   └── sync_repository.dart          # Operasi Fetch, Backup (upsert), & Restore JSONB ke Supabase
│   │
│   ├── notifiers/                        # Logika bisnis & State Management (Riverpod)
│   │   ├── habit_notifier.dart           # AsyncNotifier kebiasaan (Optimistic UI, check-in, foto momen)
│   │   └── sync_notifier.dart            # Notifier sinkronisasi cloud (Loading, Empty, Data, Error, Retry)
│   │
│   ├── services/                         # Layanan eksternal, sistem perangkat, & logika statistik
│   │   ├── analytics_service.dart        # AnalyticsService: statistik kebiasaan (konsistensi, hari terlewat, komparasi mingguan)
│   │   ├── auth_service.dart             # Pembungkus Supabase Auth (login, register, resetPassword, updatePassword, onAuthStateChange, logout)
│   │   └── notification_service.dart     # Singleton flutter_local_notifications & konfigurasi timezone
│   │
│   ├── utils/                            # Utilitas pembantu (perangkat keras & aturan input)
│   │   ├── camera_helper.dart            # Pengambilan & penyimpanan foto permanen (image_picker & path_provider)
│   │   └── validators.dart               # Aturan input terpusat (nama, telepon, target, email, password, konfirmasi)
│   │
│   ├── screens/                          # Halaman antarmuka utama (Presentation Layer)
│   │   ├── analytics_screen.dart         # Halaman Analitik (kartu ringkasan & BarChart komparasi mingguan)
│   │   ├── login_screen.dart             # Halaman Login (/login)
│   │   ├── register_screen.dart          # Halaman Registrasi akun baru + dialog verifikasi email (/register)
│   │   ├── forgot_password_screen.dart   # Halaman Lupa Password, kirim link reset (/forgot-password)
│   │   ├── update_password_screen.dart   # Halaman Password Baru dari link reset (/update-password)
│   │   ├── main_screen.dart              # Kerangka navigasi bawah (Tugas, Kalender, Analitik, Milikku)
│   │   ├── dashboard_screen.dart         # Halaman utama daftar kebiasaan, metrik harian, & Abadikan Momen
│   │   ├── calendar_screen.dart          # Halaman kalender riwayat check-in & galeri momen harian
│   │   ├── profile_screen.dart           # Halaman Profil (email akun & wadah ProfileForm)
│   │   ├── sync_screen.dart              # Halaman Cloud Sync (status akun, Backup, Restore, & Logout)
│   │   └── template_screen.dart          # Halaman katalog templat kebiasaan siap pakai
│   │
│   └── widgets/                          # Komponen UI modular yang reusable
│       ├── add_habit_bottom_sheet.dart   # Bottom sheet tambah kebiasaan & habit stacking
│       ├── edit_habit_bottom_sheet.dart  # Bottom sheet ubah/hapus kebiasaan
│       ├── reflection_bottom_sheet.dart  # Bottom sheet refleksi mood & mode istirahat
│       ├── habit_card.dart               # Kartu item kebiasaan harian (check-in / progres [+] untuk target > 1)
│       ├── habit_target_fields.dart      # Input Target harian & Satuan (dipakai form tambah & edit)
│       ├── app_text_field.dart           # Komponen input teks kustom
│       ├── app_snackbar.dart             # Helper SnackBar seragam (error merah / sukses hijau)
│       ├── auth_header.dart              # Header bersama layar autentikasi (ikon, judul, deskripsi)
│       ├── auth_input_decoration.dart    # Gaya input bersama keempat layar autentikasi
│       ├── profile_form.dart             # Form profil: input & status UI (loading, error)
│       └── primary_button.dart           # Komponen tombol aksi utama
│
├── android/app/src/main/AndroidManifest.xml  # intent-filter deep link io.supabase.rutinku://login-callback/
│
├── test/                                 # Pengujian otomatis (102 Unit & Widget Test)
│   ├── analytics_service_test.dart       # Unit test AnalyticsService (data mock, tanggal acuan tetap, hitungan matematis)
│   ├── analytics_screen_test.dart        # Widget test layar Analitik (empty state, kartu, grafik, warna selisih)
│   ├── auth_service_test.dart            # Unit test AuthService (resetPassword, updatePassword, stream) dengan mock GoTrueClient
│   ├── auth_screens_test.dart            # Widget test Login→Lupa Password, Password Baru, dialog verifikasi, & listener passwordRecovery
│   ├── api_sync_test.dart                # Unit test Cloud Sync & validasi model (MockSyncRepository / mocktail)
│   ├── sync_screen_test.dart             # Widget test state UI SyncScreen
│   ├── checkin_test.dart                 # Unit test CRUD, SharedPreferences, streak, mood, & habit stacking
│   ├── edge_cases_test.dart              # Widget/unit test validasi input, empty state, & izin notifikasi aman
│   ├── template_screen_test.dart         # Widget test alur pemilihan templat kebiasaan
│   ├── validators_test.dart              # Unit test aturan input terpusat (nama, telepon, target, email, password)
│   ├── profile_form_test.dart            # Widget test ProfileForm (validasi, loading, sukses, error) dengan FakeProfileRepository
│   ├── progressive_habit_test.dart       # Unit test Progressive Habit (model, repository, notifier, toggle)
│   ├── progressive_habit_ui_test.dart    # Widget test HabitCard [+] & form Target/Satuan
│   └── widget_test.dart                  # Widget test Dashboard loading, empty state, & validasi form
│
└── pubspec.yaml                          # Konfigurasi dependensi package Flutter
```

## 5. Konfigurasi Deep Link & Supabase Dashboard

Alur reset password bergantung pada satu URL *deep link* yang harus sama di tiga tempat:

| Tempat | Nilai | Keterangan |
|---|---|---|
| `AuthService.authRedirectUrl` (`lib/services/auth_service.dart`) | `io.supabase.rutinku://login-callback/` | Dikirim sebagai `redirectTo` saat `resetPassword`. |
| `android/app/src/main/AndroidManifest.xml` | `<data android:scheme="io.supabase.rutinku" android:host="login-callback"/>` | `intent-filter` (`VIEW`, `DEFAULT`, `BROWSABLE`) di MainActivity agar Android membuka aplikasi saat link diketuk. |
| **Supabase Dashboard → Authentication → URL Configuration → Redirect URLs** | `io.supabase.rutinku://login-callback/` | **Langkah manual wajib.** Tanpa ini, Supabase menolak `redirectTo` dan link mengarah ke *Site URL* di browser. |

Catatan operasional:
* Supabase memakai alur **PKCE**: kode verifikasi disimpan di perangkat yang meminta reset, sehingga link harus dibuka di HP yang sama.
* Link **verifikasi pendaftaran** belum memakai deep link; link tersebut mengarah ke *Site URL* Supabase, lalu pengguna login manual di aplikasi.
* Jika skema deep link diganti, ubah ketiga tempat di atas sekaligus.
