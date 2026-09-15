# Rutinku - Mobile Habit Tracker

## Deskripsi Masalah
Banyak orang kesulitan mempertahankan konsistensi saat mencoba membangun kebiasaan baru (seperti minum air 2 liter sehari, olahraga ringan, atau membaca buku). Kegagalan ini sering terjadi karena mereka tidak memiliki alat pencatat progres yang praktis dan tidak adanya dorongan visual untuk memotivasi mereka secara harian. Penggunaan catatan manual seringkali merepotkan dan mudah dilupakan.

## Profil Target Pengguna
- **Individu dengan Mobilitas Tinggi:** Pelajar, mahasiswa, dan pekerja yang selalu membawa *smartphone* setiap hari.
- **Pemula dalam Produktivitas:** Siapa saja yang ingin membangun rutinitas positif baru dan membutuhkan antarmuka yang sangat sederhana tanpa pengaturan yang rumit.

## Manfaat Aplikasi
- **Meningkatkan Konsistensi:** Memberikan motivasi visual berupa perhitungan *streak* (hari berturut-turut) yang mendorong pengguna agar tidak memutus rantai rutinitas.
- **Aksesibilitas Cepat:** Memudahkan pengguna untuk mencatat (*check-in*) kebiasaan harian mereka secara instan langsung dari genggaman ponsel sesaat setelah aktivitas selesai dilakukan.
- **Evaluasi Diri:** Membantu pengguna memantau pola kedisiplinan mereka melalui ringkasan progres mingguan.

## Daftar Fitur Inti
> *Target penyelesaian dalam 12 pertemuan.*
1. **Manajemen Kebiasaan (CRUD):** Fitur antarmuka untuk menambah, membaca, mengedit, dan menghapus target kebiasaan harian.
2. **Sistem *Daily Check-in*:** Tombol interaktif (centang) di layar utama untuk menandai kebiasaan yang sudah diselesaikan pada hari ini.
3. **Kalkulasi *Streak* Otomatis:** Sistem logika yang menghitung berapa hari berturut-turut sebuah kebiasaan berhasil dilakukan. Jika terlewat satu hari (pergantian tanggal tanpa *check-in*), angka *streak* akan otomatis di-reset menjadi 0.
4. **Ringkasan Progres Mingguan:** Halaman statistik sederhana yang menunjukkan grafik atau deretan ikon riwayat *check-in* pengguna selama 7 hari terakhir.
5. **Penyimpanan Data Lokal:** Menggunakan `AsyncStorage` (atau SQLite lokal) agar data kebiasaan persisten dan aplikasi dapat langsung digunakan secara *offline*.

## Fitur yang Tidak Dikerjakan
1. Sistem Autentikasi Pengguna (*Login/Register*).
2. Sinkronisasi *Cloud Database* dan pembuatan API *Backend* (aplikasi berjalan murni *offline*).
3. Notifikasi *Push* berbasis sistem operasi (Android/iOS) yang berjalan di *background*.
4. Fitur jejaring sosial (seperti berbagi progres ke media sosial atau papan peringkat antar pengguna).

## Kriteria Aplikasi Dinyatakan Berhasil
1. **Dapat Dijalankan (Runnable):** Aplikasi dapat dijalankan di *emulator* atau ponsel fisik melalui *Expo Go*, dan dapat di-*build* menjadi file instalasi (misal: APK).
2. **Penyimpanan Lokal Berfungsi:** Pengguna sukses melakukan operasi CRUD pada daftar kebiasaan, dan data tersebut tidak hilang ketika aplikasi ditutup dan dibuka kembali.
3. **Akurasi Logika Waktu:** Aplikasi berhasil membaca tanggal di sistem ponsel. Ketika pengguna melakukan *check-in* hari ini, *streak* bertambah +1. Jika sistem mendeteksi hari sudah berganti dan tidak ada *check-in* di hari sebelumnya, *streak* kembali menjadi 0 secara otomatis.
4. **Alur Pengguna Lancar:** Pengguna dapat berpindah dari layar *Dashboard* ke layar *Statistik* tanpa ada *error* (navigasi berjalan baik).
