# Laporan Implementasi Praktikum

**Topik:** Pertemuan 6 - Integrasi API & Unit Testing
**Proyek:** RutinKu (Aplikasi Manajemen Kebiasaan)

---

## 1. Ringkasan Eksekutif
Dokumen ini menyajikan laporan implementasi teknis untuk tugas Pertemuan ke-6. Fokus utama pada iterasi pengembangan ini adalah menghubungkan aplikasi RutinKu dengan layanan *backend* publik (API) untuk mendemonstrasikan implementasi **Vertical Slice** yang utuh. Fitur inti yang dipilih untuk iterasi ini adalah **Cloud Sync** (Sinkronisasi Data), di mana pengguna dapat mengunduh rutinitas dari *cloud* dan melakukan cadangan (*backup*) data lokal ke server.

## 2. Arsitektur Vertical Slice (Cloud Sync)
Untuk memastikan kode bersih (*clean code*) dan memenuhi standar industri, fitur Cloud Sync dibangun menggunakan arsitektur berlapis yang memisahkan logika jaringan, manajemen *state*, dan antarmuka pengguna:

*   **Repository Layer (`SyncRepository`):** Bertanggung jawab penuh atas komunikasi HTTP. Menggunakan paket `http` untuk melakukan permintaan `GET` guna memuat data dari *Mock API* (JSONPlaceholder) dan permintaan `POST` untuk simulasi pengiriman data (*backup*). Lapisan ini juga menangani *parsing* JSON menjadi objek `HabitModel` secara aman.
*   **State Management (`SyncNotifier`):** Menggunakan **Riverpod** untuk mengelola *state* reaktif. Notifier ini memastikan antarmuka UI selalu sinkron dengan status jaringan terkini (seperti mengubah status menjadi *Loading* saat memanggil API, dan *Data* saat selesai).
*   **Presentation Layer (`SyncScreen`):** Halaman UI mandiri yang merender tampilan berdasarkan *state* yang diberikan oleh Riverpod. Halaman ini diakses melalui ikon sinkronisasi di `DashboardScreen` utama.

> **Catatan Pengembangan:**
> Infrastruktur jaringan aplikasi telah dikonfigurasi untuk menangani fitur *Desugaring* pada Java modern, serta resolusi konflik partisi lintas-direktori (*Incremental Kotlin Cache*) guna menjamin stabilitas *build* pada perangkat keras fisik (Android 14).

## 3. Penanganan State Antarmuka (UI States)
Sesuai dengan rubrik penilaian, aplikasi harus mampu menangani dan menampilkan berbagai kemungkinan respons dari server. Kelas `SyncScreen` memanfaatkan metode `.when()` dari Riverpod untuk merender lima (5) status *Vertical Slice* secara dinamis tanpa hambatan visual:

| Status (State) | Pemicu / Kondisi | Representasi Antarmuka (UI) |
| :--- | :--- | :--- |
| **Loading** | Terjadi saat aplikasi menunggu respons `GET` atau `POST` dari API. | Menampilkan `CircularProgressIndicator` berputar dan teks "Menyinkronkan data...". |
| **Empty** | API mengembalikan status 200 OK, tetapi array JSON kosong (`[]`). | Menampilkan ikon `cloud_off_rounded` dan pesan "Data di cloud masih kosong". |
| **Error** | HTTP gagal (misal 404/500) atau format JSON rusak/tidak valid. | Menampilkan ikon peringatan, pesan deskriptif *error*, dan tombol **Retry**. |
| **Success** | Data berhasil dipetakan ke dalam `List<HabitModel>`. | Menampilkan `ListView` daftar kebiasaan dan tombol "Backup Data". |
| **Retry** | Pengguna menekan tombol "Coba Lagi" saat berada di State Error. | Memicu ulang fungsi `fetchData()` dan mengembalikan UI ke State Loading. |

## 4. Pengujian Lingkungan Fisik (Physical Device)
Fitur integrasi API ini telah dikompilasi dan diuji secara langsung (*debug mode*) menggunakan perangkat keras fisik **Samsung Galaxy A56 (SM-A566B)** berbasis arsitektur ARM64. Hasil pengujian menunjukkan bahwa komunikasi jaringan berjalan lancar, dan seluruh transisi *state* (termasuk animasi *loading* dan notifikasi *SnackBar* saat proses *backup* selesai) dirender dengan sempurna pada layar fisik tanpa kendala latensi.

## 5. Validasi Uji Perangkat Lunak (Unit Testing)
Bagian esensial dari pengembangan pertemuan ini adalah penulisan skenario pengujian otomatis. Menggunakan paket `mockito` dan kelas klien HTTP kustom (`MockClient`), implementasi jaringan dievaluasi berdasarkan 6 parameter mutlak yang diwajibkan oleh rubrik. Seluruh tes dieksekusi melalui `test/api_sync_test.dart`.

| No | Skenario Uji (Kriteria) | Deskripsi Ekspektasi Internal | Status |
| :---: | :--- | :--- | :---: |
| 1 | **Model Valid** | `HabitModel.fromMap` berhasil melakukan instansiasi objek jika diberikan map JSON dengan struktur properti yang benar. | ✅ Passed |
| 2 | **Model Invalid** | `HabitModel.fromMap` secara proaktif melempar `TypeError` atau `Exception` saat menerima map dengan tipe data salah (misal *id* bertipe integer). | ✅ Passed |
| 3 | **API Sukses** | Fungsi memproses respons HTTP 200 berisikan JSON array valid dan mengembalikan struktur `List<HabitModel>` secara presisi. | ✅ Passed |
| 4 | **Data Kosong** | Fungsi memproses respons HTTP 200 berisikan array `[]` dan mengembalikan daftar dengan panjang nol. | ✅ Passed |
| 5 | **HTTP Gagal** | Fungsi melempar `Exception` terkontrol saat melakukan intersepsi kode status HTTP 404 (Not Found) atau 500 (Server Error). | ✅ Passed |
| 6 | **JSON Rusak** | Fungsi berhasil melempar `FormatException` ketika *body* respons HTTP membawa sintaks JSON yang terpotong atau rusak. | ✅ Passed |
| 7 | *Bonus: HTTP POST* | Fungsi `backupHabitsToCloud` sukses mengembalikan nilai boolean `true` jika menerima respons HTTP 201 (Created). | ✅ Passed |

> **Kesimpulan Pengujian Lintas-Sistem:**
> Eksekusi perintah komprehensif `flutter test` pada keseluruhan struktur repositori memberikan konfirmasi bahwa **32 dari 32 Unit Test telah lulus (All tests passed!)**, membuktikan tidak adanya regresi pada komponen lawas saat komponen API baru diintegrasikan. Proses analisis statis kode (`flutter analyze`) juga menunjukan nol peringatan (*No issues found*).