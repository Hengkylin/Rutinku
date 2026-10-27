# HowToRun — RutinKu

## 1. Deskripsi Aplikasi

**RutinKu** adalah aplikasi *habit tracker* berbasis Flutter (fokus Android) untuk membantu pengguna membangun konsistensi kebiasaan harian. Fitur utama:

- **Manajemen kebiasaan (CRUD)** — tambah, ubah, hapus (dengan *undo*), serta *habit stacking* dan templat kebiasaan.
- **Check-in harian & streak** — tandai kebiasaan selesai dan lihat perhitungan *streak* beruntun.
- **Kalender / riwayat** — lihat riwayat check-in per tanggal.
- **Penyimpanan lokal** — data disimpan persisten dengan `SharedPreferences`.
- **Pengingat notifikasi lokal** — notifikasi terjadwal harian (`flutter_local_notifications`).
- **Cloud Sync** — tarik data (HTTP GET) dan backup data (HTTP POST) ke API, lengkap dengan *loading*, *empty*, *error*, dan tombol *retry*.

State management: **Riverpod**. Detail arsitektur ada di [ARCHITECTURE.md](ARCHITECTURE.md).

---

## 2. Prasyarat (Prerequisites)

| Kebutuhan | Versi / Keterangan |
|---|---|
| Flutter SDK | Stable, Dart SDK `^3.13.4` (diuji dengan Flutter 3.47.5 / Dart 3.13.4) |
| Android SDK | Android SDK Platform + Build-Tools + Platform-Tools (via Android Studio) |
| Android NDK | **28.2.13676358** (install lewat *SDK Manager → SDK Tools → NDK (Side by side)*) |
| Java (JDK) | **Java 17** (`JAVA_HOME` harus mengarah ke JDK 17) |
| Perangkat | Emulator Android atau perangkat fisik (USB debugging aktif) |

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

---

## 4. Menjalankan Aplikasi

```bash
# Lihat perangkat/emulator yang tersedia
flutter devices

# Jalankan pada perangkat default
flutter run

# Atau pilih perangkat tertentu
flutter run -d <device_id>
```

> Saat pertama kali dibuka, aplikasi meminta izin notifikasi (Android 13+) dan izin alarm presisi (Android 12+/14+). Jika izin **ditolak**, aplikasi tetap berjalan normal — hanya pengingat yang tidak muncul.

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
# Seluruh unit test & widget test
flutter test

# Hanya pengujian Cloud Sync API (GET / POST, data kosong, HTTP gagal, JSON rusak)
flutter test test/api_sync_test.dart

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
