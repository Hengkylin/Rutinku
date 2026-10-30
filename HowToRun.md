# HowToRun — RutinKu

## 1. Deskripsi Aplikasi

**RutinKu** adalah aplikasi *habit tracker* berbasis Flutter (fokus Android) untuk membantu pengguna membangun konsistensi kebiasaan harian. Fitur utama:

- **Autentikasi 3 Halaman (Supabase Auth)** — alur autentikasi terpisah yang bersih mencakup **Login** (`/login`), **Register** (`/register` dengan validasi konfirmasi password), dan **Lupa Password** (`/forgot-password` untuk mengirim tautan reset password ke email).
- **Manajemen kebiasaan (CRUD)** — tambah, ubah, hapus (dengan *undo*), serta *habit stacking* dan templat kebiasaan.
- **Check-in harian, mood refleksi, & streak** — tandai kebiasaan selesai, atur mode istirahat/refleksi mood, dan lihat perhitungan *streak* beruntun secara dinamis.
- **Kamera / Visual Habit Journal ("Abadikan Momen")** — ambil foto bukti atau kenangan penyelesaian kebiasaan harian menggunakan kamera perangkat (`image_picker` & `path_provider`) yang disimpan ke penyimpanan aplikasi dan dapat dilihat pada riwayat kalender.
- **Kalender / riwayat** — lihat riwayat check-in, catatan refleksi, dan foto momen per tanggal (`table_calendar`).
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
1. **Autentikasi (`LoginScreen` / `RegisterScreen` / `ForgotPasswordScreen`):**
   - Jika belum masuk (`currentUser == null`), aplikasi otomatis menampilkan halaman **Login**.
   - Pilih **"Belum punya akun? Daftar"** untuk membuat akun baru di halaman **Register**, atau pilih **"Lupa Password?"** untuk mengirim tautan reset password ke email terdaftar.
2. **Manajemen Kebiasaan & Abadikan Momen (`DashboardScreen`):**
   - Tekan tombol **`+`** untuk memilih templat kebiasaan atau membuat kebiasaan kustom (beserta jam pengingat opsional).
   - Ketuk ikon kamera pada kartu kebiasaan untuk menjalankan fitur **Abadikan Momen** (*Visual Habit Journal*) menggunakan kamera perangkat.
3. **Cloud Sync (`SyncScreen`):**
   - Ketuk ikon *cloud sync* di bagian atas Dashboard untuk melihat data di Supabase, melakukan **Backup Data Lokal ke Cloud**, **Restore Cloud ke Perangkat Ini**, atau **Logout**.

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

---

## 6. Pengujian Otomatis & Analisis Kode

```bash
# Seluruh unit test & widget test (41 test)
flutter test

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
| Kamera tidak terbuka pada emulator | Pastikan konfigurasi kamera emulator Android disetel ke *VirtualizedScene* atau *Webcam0*, serta izin kamera diizinkan. |
