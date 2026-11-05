# Laporan Praktikum Pertemuan 8 - UX Review & Accessibility
**Proyek:** RutinKu (Aplikasi Manajemen Kebiasaan)

## 1. Ringkasan Eksekutif
Dokumen ini menyajikan hasil tinjauan antarmuka pengguna (UX Review) dan aksesibilitas (Accessibility) untuk aplikasi RutinKu, sesuai dengan kriteria penilaian Pertemuan 8. Tinjauan ini memastikan bahwa aplikasi tidak hanya berfungsi secara teknis (berdasarkan MVP Pertemuan 7), tetapi juga memberikan pengalaman yang aman, nyaman, dan inklusif bagi pengguna akhir.

## 2. Hasil Evaluasi Kriteria UX & Aksesibilitas

Berdasarkan pengujian langsung pada aplikasi yang sedang berjalan (*RUN*), berikut adalah pemenuhan kriteria yang diminta:

### 01. Layout Adaptif (Layar Besar / Layar Kecil)
*   **Status:** ✅ **BAGUS**
*   **Implementasi:** Antarmuka aplikasi, khususnya pada daftar rutinitas (*Habit Card*), dirancang menggunakan tata letak yang fleksibel (`Wrap` dan pembatasan `maxLines`).


*   **Bukti Visual:** Pada tangkapan layar daftar tugas (103815.jpg) dan Cloud Sync (103817.jpg), teks judul kebiasaan yang panjang (seperti "Minum air putih, jaga kesehatan") akan terpotong rapi dengan *ellipsis* (`...`) apabila ruang layar menyempit. Elemen navigasi dan tombol aksi di sebelah kanan (seperti Edit, Kamera, Check-in) tetap pada posisinya tanpa memicu *error* batas layar (*Right Overflowed*).

### 02. Keyboard-Safe UI
*   **Status:** ✅ **BAGUS**
*   **Implementasi:** Form masukan pengguna (seperti *Bottom Sheet* untuk menambah kebiasaan) menggunakan *padding* dinamis yang mendeteksi intrusi *keyboard* virtual (`MediaQuery.of(context).viewInsets.bottom`).
*   **Bukti Visual:** Saat *keyboard* virtual aktif untuk mengisi "Nama Kebiasaan" (103834.jpg dan 103832.jpg), seluruh tampilan *Bottom Sheet* akan terdorong ke atas. Hal ini memastikan bahwa kotak input (*input box*) tetap terlihat sepenuhnya dan pengguna dapat mengetik dengan nyaman tanpa terhalang *keyboard*.

### 03. Accessibility Dasar
*   **Status:** ✅ **BAGUS**
*   **Implementasi:** Aplikasi mematuhi standar aksesibilitas dasar visual dan interaksi.
*   **Bukti Visual:** 
    *   **Kontras Warna (Gambar 5 & 6):** Desain menggunakan teks gelap (Navy) di atas latar belakang terang (Putih/Abu-abu muda), memastikan keterbacaan yang tinggi.
    *   **Area Sentuh (Touch Target):** Tombol-tombol utama dan daftar pilihan pada *Template* (Gambar 5) dirancang dengan jarak dan ukuran yang memadai, sehingga mudah disentuh dan meminimalisasi kesalahan ketukan jari pengguna.

### 04. Feedback Aksi
*   **Status:** ✅ **BAGUS**
*   **Implementasi:** Setiap aksi yang membutuhkan waktu atau bersifat destruktif selalu disertai dengan umpan balik visual (*visual feedback*) yang jelas kepada pengguna.
*   **Bukti Visual:**
    *   **Dialog Konfirmasi (103828.jpg):** Sebelum menghapus rutinitas, sistem memunculkan pop-up peringatan "Hapus Kebiasaan?" untuk mencegah penghapusan yang tidak disengaja.
    *   **Notifikasi SnackBar (103830.jpg):** Setelah aksi berhasil (contoh: menghapus kebiasaan), muncul *SnackBar* di bagian bawah layar ("Makan buah-buahan berhasil dihapus") lengkap dengan opsi "Batal" (*Undo*).
    *   **Indikator Loading (103832.jpg
):** Saat proses sinkronisasi *cloud* berjalan, aplikasi menampilkan *Circular Progress Indicator* berputar beserta teks "Menyinkronkan data...", sehingga pengguna tahu bahwa sistem sedang memproses permintaan dan tidak diam membeku (*freeze*).


---
*Laporan ini disusun berdasarkan pengujian pada *repository* cabang `main` (*Commit hash*: `fa08f3bda078e009093a967edb4b29b27c0c2c4a`).*
