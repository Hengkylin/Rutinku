# Laporan Praktikum Pertemuan 7 - Finalisasi MVP & Fitur Lanjutan
**Proyek:** RutinKu (Aplikasi Manajemen Kebiasaan)

## 1. Ringkasan Eksekutif
Dokumen ini menyajikan laporan finalisasi *Minimum Viable Product* (MVP) dari aplikasi RutinKu untuk memenuhi rubrik Pertemuan ke-7. Fokus utama pada iterasi ini adalah penyelesaian seluruh alur utama aplikasi (navigasi, form, validasi, dan penyimpanan persisten) serta pengintegrasian **3 Fitur Lanjutan (Advanced Features)** yang diuji ketat hingga mencapai **41/41 Unit Test PASSED**.

## 2. Implementasi 3 Fitur Lanjutan (Advanced Features)

### A. Autentikasi & Cloud Sync (BaaS Supabase)
*   **Teknologi:** `supabase_flutter` (Supabase Auth & PostgreSQL).
*   **Implementasi:** Aplikasi menggunakan arsitektur 3 halaman autentikasi terpisah (Login, Register, dan Lupa Password) untuk meminimalisasi *human error* dan memberikan pengalaman UI/UX berstandar industri. Penyimpanan *cloud* menggunakan strategi **Cloud Save JSONB**, di mana seluruh rekam jejak kebiasaan lokal di-*backup* secara utuh ke dalam satu kolom JSONB pada tabel `user_data` (dilindungi oleh *Row Level Security*).
*   **Manfaat bagi Pengguna:** Menjamin keamanan privasi data pengguna dan mencegah kehilangan progres kebiasaan saat pengguna berganti perangkat.

### B. Kamera & File System (Visual Habit Journal)
*   **Teknologi:** `image_picker` dan `path_provider`.
*   **Implementasi:** Pengguna tidak hanya melakukan *check-in* berbasis teks, tetapi juga dapat menekan ikon **Kamera** untuk "Mengabadikan Momen". Foto diambil secara langsung (native) dan disimpan secara permanen di dalam direktori dokumen lokal aplikasi.
*   **Manfaat bagi Pengguna:** Menciptakan elemen *gamification* dan memori visual yang membuktikan bahwa pengguna benar-benar melakukan rutinitas tersebut, sehingga secara psikologis meningkatkan motivasi harian.

### C. Pengingat Notifikasi Lokal (Local Push Notifications)
*   **Teknologi:** `flutter_local_notifications` dan `timezone`.
*   **Implementasi:** Aplikasi memanfaatkan API notifikasi *native* Android untuk menjadwalkan pengingat secara spesifik (jam dan menit) berdasarkan zona waktu lokal pengguna secara otomatis. 
*   **Manfaat bagi Pengguna:** Mendorong konsistensi pengguna secara proaktif tanpa memerlukan koneksi internet, memastikan pengguna tidak melewatkan rutinitas di tengah kesibukan.

## 3. Penanganan Edge Cases & Kestabilan Aplikasi
Guna memastikan aplikasi berjalan mulus layaknya aplikasi produksi, lapisan perlindungan (*safety nets*) berikut telah diimplementasikan:
*   **Form & Validasi:** Seluruh input pengguna pada pembuatan kebiasaan maupun autentikasi divalidasi dengan ketat (mencegah input kosong, hanya spasi, atau *password* yang tidak cocok).
*   **UI States Terkendali:** Lapisan antarmuka mampu menangani transisi dengan halus melalui status *Loading* (animasi indikator), *Empty State* (ilustrasi khusus saat data/kalender/cloud kosong), dan *Error State* (peringatan dengan tombol "Coba Lagi" untuk melakukan mekanisme *Retry* tanpa *crash*).
*   **Penanganan Izin Akses (Permissions):** Permintaan izin *native* ke sistem operasi (Kamera, Android 13+ *POST_NOTIFICATIONS*, dan *SCHEDULE_EXACT_ALARM*) dibungkus menggunakan blok `try-catch` terisolasi. Jika izin ditolak oleh pengguna, aplikasi tidak akan mengalami *Force Close*, melainkan tetap bisa digunakan untuk fitur inti lainnya.

## 4. Tautan Video Demonstrasi

Berikut adalah rekaman layar implementasi yang menunjukkan seluruh alur sistem (termasuk kelancaran 3 Advanced Features):

*   **Video Dokumentasi Utama (Alur Check-in, Kamera, & Cloud Sync):** 
    [Lihat Video Demonstrasi Utama](https://drive.google.com/file/d/1qr9AXgNDSae-URCUonM3G4VWyjAgiVTq/view?usp=sharing)
    
*   **Video Dokumentasi Fitur Lupa Password (Supabase Auth):** 
    [Lihat Video Reset Password](https://drive.google.com/file/d/1oUUuM8F_FV3gaMTiZe9spLRqv-4ss1mE/view?usp=sharing)
    *(Catatan: Sistem secara sukses mengirimkan email berisi link reset. Saat link ditekan, sistem sementara akan mengarah ke GitHub RutinKu sebagai placeholder tautan callback untuk pengembangan lebih lanjut).*
