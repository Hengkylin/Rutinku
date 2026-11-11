# HowToRun — RutinKu

## 1. Deskripsi Aplikasi

**RutinKu** adalah aplikasi *habit tracker* berbasis Flutter (fokus Android) untuk membantu pengguna membangun konsistensi kebiasaan harian. Fitur utama:

- **Autentikasi Penuh (Supabase Auth)** — **Login** (`/login`), **Register + Verifikasi Email** (`/register`, menampilkan dialog cek email alih-alih langsung masuk; link verifikasi membuka aplikasi lewat *deep link*), **Lupa Password** (`/forgot-password`, mengirim **kode 6 digit** ke email), **Masukkan Kode** (verifikasi kode OTP, bisa kirim ulang), dan **Password Baru**.
- **Manajemen kebiasaan (CRUD)** — tambah, ubah, hapus (dengan *undo*), serta *habit stacking* dan templat kebiasaan.
- **Check-in harian, mood refleksi, & streak** — tandai kebiasaan selesai, atur mode istirahat/refleksi mood, dan lihat perhitungan *streak* beruntun secara dinamis.
- **Progressive Habit Tracking** — beri target angka harian & satuan (mis. 8 gelas); tambah progres dengan tombol **[+]** sampai target tercapai.
- **Kamera / Visual Habit Journal ("Abadikan Momen")** — ambil foto bukti atau kenangan penyelesaian kebiasaan harian menggunakan kamera perangkat (`image_picker` & `path_provider`) yang disimpan ke penyimpanan aplikasi dan dapat dilihat pada riwayat kalender.
- **Kalender / riwayat** — lihat riwayat check-in, catatan refleksi, dan foto momen per tanggal (`table_calendar`).
- **Habit Analytics** — kebiasaan paling konsisten (30 hari), hari yang paling sering terlewat (4 minggu), dan grafik batang komparasi minggu ini vs minggu lalu (`fl_chart`).
- **Profil pengguna** — ubah nama (wajib, minimal 3 karakter) dan nomor telepon (opsional, angka minimal 10 digit); disimpan ke tabel Supabase `users` dan di-cache di perangkat.
- **Penyimpanan lokal** — data kebiasaan disimpan secara persisten di perangkat dengan `SharedPreferences`.
- **Pengingat notifikasi lokal** — notifikasi terjadwal harian sesuai zona waktu lokal pengguna (`flutter_local_notifications` & `timezone`).
- **Supabase Cloud Sync (JSONB)** — pratinjau data cloud (*Fetch*), pencadangan data lokal ke cloud (*Backup* `upsert`), dan pemulihan data cloud ke perangkat (*Restore*) pada tabel PostgreSQL `user_data`, lengkap dengan penanganan *loading*, *empty*, *error*, dan tombol *retry*.

State management: **Riverpod**. Detail arsitektur ada di [ARCHITECTURE.md](ARCHITECTURE.md).

---

## 2. Prasyarat (Prerequisites)

| Kebutuhan | Versi / Keterangan |
|---|---|
| Flutter SDK | Stable, Dart SDK `^3.13.4` (diuji dengan Flutter 3.47.5 / Dart 3.13.4) |
| Android SDK | Android SDK Platform + Build-Tools + Platform-Tools (via Android Studio) |
| Android NDK | **28.2.13676358** (install lewat *SDK Manager → SDK Tools → NDK (Side by side)*) |
| Java (JDK) | **Java 17** (`JAVA_HOME` harus mengarah ke JDK 17) |
| Perangkat | Emulator Android atau perangkat fisik (USB debugging aktif, koneksi internet untuk autentikasi & sinkronisasi Supabase) |

Verifikasi lingkungan:

```bash
flutter doctor -v
java -version
```

---

## 3. Instalasi Dependensi

Seluruh perintah dijalankan dari folder project Flutter:

```bash
cd rutinku_flutter
flutter pub get
```

> Konfigurasi URL dan *publishable key* Supabase telah diinisialisasi di `lib/main.dart`, sehingga aplikasi dapat langsung dijalankan tanpa konfigurasi `.env` tambahan.

> ⚠️ **Wajib di Supabase Dashboard** (sekali per project): template email **Reset password** harus berisi kode `{{ .Token }}`, dan **Site URL** diisi `io.supabase.rutinku://login-callback/`. Langkah lengkap ada di [bagian 5](#5-catatan-konfigurasi-khusus-android) poin 4–5.

---

## 4. Menjalankan Aplikasi & Panduan Alur Singkat

```bash
# Lihat perangkat/emulator yang tersedia
flutter devices

# Jalankan pada perangkat default
flutter run

# Atau pilih perangkat tertentu
flutter run -d <device_id>
```

### Alur Penggunaan Fitur Utama:
1. **Autentikasi (`LoginScreen` / `RegisterScreen` / `ForgotPasswordScreen` / `VerifyResetCodeScreen` / `UpdatePasswordScreen`):**
   - Jika belum masuk (`currentUser == null`), aplikasi otomatis menampilkan halaman **Login**.
   - **Daftar & verifikasi email:** pilih **"Belum punya akun? Daftar"**, isi email, password (minimal 6 karakter), dan konfirmasi password. Setelah berhasil, muncul dialog **"Cek Email Anda"**; tekan **Ke Halaman Login**, buka link verifikasi di email (link membuka aplikasi), lalu login. Jika link sudah kedaluwarsa atau sudah pernah dipakai, muncul SnackBar merah yang menjelaskannya.
   - **Lupa password:** pilih **"Lupa Password?"** di halaman Login, isi email, lalu tekan **Kirim Kode Reset**. SnackBar hijau *"Kode reset telah dikirim ke email Anda"* muncul dan aplikasi pindah ke layar **Masukkan Kode**.
   - **Masukkan kode:** ketik **kode 6 digit** dari email terbaru, lalu tekan **Verifikasi Kode**. Kode salah/kedaluwarsa menampilkan SnackBar merah; tekan **Kirim ulang kode** untuk meminta kode baru (kode lama tidak berlaku lagi).
   - **Password baru:** isi **Password Baru** dan **Konfirmasi Password Baru** (minimal 6 karakter dan harus sama), tekan **Simpan Password**, lalu aplikasi kembali ke Beranda.
2. **Manajemen Kebiasaan & Abadikan Momen (`DashboardScreen`):**
   - Tekan tombol **`+`** untuk memilih templat kebiasaan atau membuat kebiasaan kustom (beserta jam pengingat opsional).
   - Isi **Target harian** (default 1) dan **Satuan** (opsional, mis. "gelas") untuk kebiasaan progresif. Kebiasaan dengan target > 1 menampilkan progres `n / target satuan` dan tombol **[+]** di kartunya; setelah target tercapai tombol berganti menjadi centang hijau. Target 1 tetap memakai tombol centang biasa.
   - Ketuk ikon kamera pada kartu kebiasaan untuk menjalankan fitur **Abadikan Momen** (*Visual Habit Journal*) menggunakan kamera perangkat.
3. **Cloud Sync (`SyncScreen`):**
   - Ketuk ikon *cloud sync* di bagian atas Dashboard untuk melihat data di Supabase, melakukan **Backup Data Lokal ke Cloud**, **Restore Cloud ke Perangkat Ini**, atau **Logout**.
4. **Analitik (`AnalyticsScreen`):**
   - Buka tab **Analitik** di navigasi bawah untuk melihat kartu **Kebiasaan Paling Konsisten** dan **Hari Sering Terlewat**, serta grafik **Komparasi Mingguan** dengan teks selisih (mis. `+17,9% dari minggu lalu`, hijau jika naik dan merah jika turun).
   - Jika belum ada kebiasaan, halaman menampilkan pesan kosong.
5. **Profil (`ProfileScreen`):**
   - Buka tab **Milikku** di navigasi bawah, isi **Nama Lengkap** dan **Nomor Telepon (Opsional)**, lalu tekan **Simpan**.
   - Input yang tidak valid langsung ditandai di bawah field; jika penyimpanan gagal, pesan error tampil di SnackBar merah.

> Saat pertama kali dibuka atau saat fitur terkait digunakan, aplikasi meminta izin notifikasi (Android 13+), izin alarm presisi (Android 12+/14+), serta izin kamera ketika mengambil foto momen. Jika izin **ditolak**, aplikasi tetap berjalan normal tanpa *crash*.

---

## 5. Catatan Konfigurasi Khusus Android

Konfigurasi berikut sudah diterapkan di project (tidak perlu diubah manual):

1. **Core library desugaring v2.1.4** — dibutuhkan oleh `flutter_local_notifications`.
   File: `android/app/build.gradle.kts`
   ```kotlin
   compileOptions {
       sourceCompatibility = JavaVersion.VERSION_17
       targetCompatibility = JavaVersion.VERSION_17
       isCoreLibraryDesugaringEnabled = true
   }
   dependencies {
       coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
   }
   ```
2. **`kotlin.incremental=false`** — menghindari error *incremental compilation* Kotlin (mis. konflik path cache lintas drive pada Windows).
   File: `android/gradle.properties`
   ```properties
   kotlin.incremental=false
   ```
3. **Java 17** dipakai untuk `sourceCompatibility`, `targetCompatibility`, dan `jvmTarget` Kotlin.
4. **Deep Link Supabase Auth** (`io.supabase.rutinku://login-callback/`) — agar link **verifikasi pendaftaran** di email membuka aplikasi.
   File: `android/app/src/main/AndroidManifest.xml` (di dalam `<activity>` MainActivity)
   ```xml
   <intent-filter>
       <action android:name="android.intent.action.VIEW"/>
       <category android:name="android.intent.category.DEFAULT"/>
       <category android:name="android.intent.category.BROWSABLE"/>
       <data
           android:scheme="io.supabase.rutinku"
           android:host="login-callback"/>
   </intent-filter>
   ```
   > ⚠️ **Langkah manual wajib:** di **Supabase Dashboard → Authentication → URL Configuration**, isi **Site URL** dengan `io.supabase.rutinku://login-callback/` (disarankan juga menambahkannya di **Redirect URLs**). Link verifikasi pendaftaran diarahkan ke Site URL, sehingga tanpa langkah ini link akan membuka browser, bukan aplikasi. Jika skema diubah, ubah AndroidManifest dan Site URL sekaligus.
5. **Template email Reset Password berisi kode 6 digit** — reset password **tidak memakai link**, karena link sekali pakai bisa hangus lebih dulu oleh pemindai keamanan email (gejalanya: error `otp_expired` saat link diklik).

   > ⚠️ **Langkah manual wajib:** buka **Supabase Dashboard → Authentication → Email Templates** (`https://supabase.com/dashboard/project/_/auth/templates`) → **Reset password**. Ganti *Subject* menjadi `Kode Reset Password RutinKu` dan seluruh *Message body* dengan:
   > ```html
   > <h2>Reset Password RutinKu</h2>
   > <p>Masukkan kode berikut di aplikasi RutinKu untuk membuat password baru:</p>
   > <p style="font-size:28px;font-weight:bold;letter-spacing:6px">{{ .Token }}</p>
   > <p>Kode hanya bisa dipakai sekali. Abaikan email ini jika Anda tidak meminta reset password.</p>
   > ```
   > Pastikan **tidak ada** `{{ .ConfirmationURL }}` di template (jika link ikut terkirim dan dipindai, kodenya ikut hangus), lalu klik **Save**. Panjang kode di aplikasi adalah 6 digit (`Validators.otpLength`), sehingga pengaturan panjang OTP email di Supabase juga harus 6.

   Catatan: layanan email **bawaan** Supabase hanya mengirim **2 email per jam** dan hanya ke alamat anggota tim project. Untuk pemakaian nyata, pasang **SMTP sendiri** (mis. Resend atau Gmail SMTP) di pengaturan SMTP project Supabase.

---

## 6. Pengujian Otomatis & Analisis Kode

```bash
# Seluruh unit test & widget test (116 test)
flutter test

# Pengujian Autentikasi: AuthService (mock GoTrueClient), Lupa Password, Masukkan Kode (OTP), Password Baru, dialog verifikasi email, & pesan error link
flutter test test/auth_service_test.dart test/auth_screens_test.dart

# Pengujian Habit Analytics: perhitungan AnalyticsService (data mock, tanggal acuan tetap) & layar Analitik
flutter test test/analytics_service_test.dart test/analytics_screen_test.dart

# Pengujian Progressive Habit Tracking: model, repository, notifier, HabitCard [+], & form target/satuan
flutter test test/progressive_habit_test.dart test/progressive_habit_ui_test.dart

# Pengujian aturan input terpusat (Validators: nama, telepon, target, email, password, kode OTP) & form Profil menggunakan FakeProfileRepository
flutter test test/validators_test.dart test/profile_form_test.dart

# Pengujian Supabase Cloud Sync (Fetch, Backup, Restore, data kosong, error, & JSON rusak) menggunakan MockSyncRepository (mocktail)
flutter test test/api_sync_test.dart

# Pengujian UI states SyncScreen (Loading, Empty, Success, Error) menggunakan MockSyncRepository (mocktail)
flutter test test/sync_screen_test.dart

# Pengujian validasi input tidak valid, empty state, dan izin notifikasi aman
flutter test test/edge_cases_test.dart

# Pemeriksaan kode statis (target: "No issues found!")
flutter analyze
```

Daftar lengkap skenario pengujian dan hasil terakhir ada di [checklist_mvp.md](checklist_mvp.md).

---

## 7. Troubleshooting Singkat

| Masalah | Solusi |
|---|---|
| `NDK not found` / versi NDK tidak cocok | Install NDK `28.2.13676358` lewat SDK Manager. |
| Error `Unsupported class file major version` | Pastikan `JAVA_HOME` memakai JDK 17. |
| Error Kotlin incremental cache | Pastikan `kotlin.incremental=false` ada di `android/gradle.properties`, lalu `flutter clean && flutter pub get`. |
| Notifikasi tidak muncul | Aktifkan izin notifikasi & alarm presisi untuk RutinKu di pengaturan perangkat. |
| Email reset password berisi link, bukan kode 6 digit | Template **Reset password** di Supabase belum diganti/disimpan. Ikuti [bagian 5](#5-catatan-konfigurasi-khusus-android) poin 5, lalu minta kode baru. |
| Kode ditolak: *"Kode salah atau sudah kedaluwarsa"* | Pakai kode dari **email terbaru** (meminta kode baru membatalkan kode lama), masukkan sebelum kedaluwarsa, atau tekan **Kirim ulang kode**. |
| *"email rate limit exceeded"* / *"you can only request this after N seconds"* | Batas layanan email bawaan Supabase (2 email/jam). Tunggu, atau pasang SMTP sendiri. |
| Link verifikasi pendaftaran membuka browser, bukan aplikasi | Pastikan **Site URL** di Supabase berisi `io.supabase.rutinku://login-callback/`. |
| SnackBar merah *"Link dari email tidak valid…"* setelah link verifikasi dibuka | Link sudah kedaluwarsa atau sudah dipakai (atau dipindai sistem keamanan email lebih dulu). Login saja jika akun sudah terverifikasi, atau daftar/minta email verifikasi baru. |
| Kamera tidak terbuka pada emulator | Pastikan konfigurasi kamera emulator Android disetel ke *VirtualizedScene* atau *Webcam0*, serta izin kamera diizinkan. |
