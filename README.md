# Rutinku - Mobile Habit Tracker App 🚀

## Deskripsi Masalah
Banyak orang kesulitan mempertahankan konsistensi saat mencoba membangun kebiasaan baru. Kegagalan ini sering terjadi karena mereka tidak memiliki alat pencatat progres yang praktis dan tidak adanya dorongan visual (seperti *streak*) untuk memotivasi mereka secara harian. Selain itu, pengguna sering kali lupa membuka aplikasi jika tidak diingatkan, dan pencatatan yang hanya tersimpan di memori internal *smartphone* rawan hilang jika berganti perangkat.

## Profil Target Pengguna
- **Individu dengan Mobilitas Tinggi:** Pelajar, mahasiswa, dan pekerja yang selalu membawa *smartphone* setiap hari.
- **Pemula dalam Produktivitas:** Siapa saja yang ingin membangun rutinitas positif baru dan membutuhkan aplikasi pengingat yang otomatis dan datanya aman tersimpan secara *online*.

## Manfaat Aplikasi
- **Meningkatkan Konsistensi:** Memberikan motivasi visual berupa perhitungan *streak* (hari berturut-turut) yang mendorong pengguna agar tidak memutus rantai rutinitas.
- **Pengingat Aktif:** Mencegah pengguna lupa melakukan kebiasaan berkat adanya notifikasi *push* otomatis yang muncul langsung di layar Android mereka.
- **Data Aman & Fleksibel:** Memudahkan pengguna mengakses riwayat kedisiplinan mereka dari perangkat mana saja karena data diamankan melalui sistem *login* dan tersinkronisasi di *cloud*.

## Daftar Fitur Inti
> *Target penyelesaian dalam 12 pertemuan.*
1. Autentikasi Pengguna: Fitur pendaftaran dan login akun pribadi sederhana.
2. **Manajemen Kebiasaan (CRUD) & Sinkronisasi Cloud:** Fitur untuk menambah, membaca, mengedit, dan menghapus target kebiasaan harian yang langsung tersinkronisasi dengan *API Backend*.
3. **Sistem *Daily Check-in* & Kalkulasi *Streak*:** Tombol untuk menandai kebiasaan yang sudah diselesaikan pada hari ini. Logika *backend* akan menghitung jumlah *streak* dan otomatis mereset ke 0 jika terlewat satu hari.
4. **Android *Background Push Notifications*:** Sistem pengingat harian yang dikirimkan oleh sistem (OS Android) meskipun aplikasi sedang dalam keadaan tertutup (*background*).
5. **Ringkasan Progres Mingguan:** Halaman statistik sederhana yang menunjukkan riwayat *check-in* pengguna selama 7 hari terakhir.

## Fitur yang Tidak Dikerjakan
1. Kompatibilitas dan pengaturan *Push Notification* khusus untuk sistem operasi iOS (Fokus pengembangan murni untuk Android terlebih dahulu).
2. Integrasi dengan perangkat keras (seperti *Smartwatch* atau *Fitness Tracker*).
3. Fitur jejaring sosial (seperti *leaderboard* antar pengguna atau berbagi progres ke media sosial).
4. Mode murni *Offline* (karena aplikasi ini sekarang membutuhkan koneksi internet untuk sinkronisasi API dan validasi *Login*).

## Kriteria Aplikasi Dinyatakan Berhasil
1. **Fungsi Autentikasi Berjalan:** Pengguna dapat mendaftar akun baru, melakukan login, dan sistem berhasil memberikan akses (token/session) hanya untuk melihat data kebiasaan miliknya sendiri.
2. **Sinkronisasi Database Sukses:** Operasi penambahan dan *check-in* kebiasaan berhasil dikirim ke *backend* dan data tidak hilang ketika aplikasi dihapus lalu diinstal ulang di perangkat lain.
3. **Notifikasi *Background* Berfungsi:** *Push notification* sukses muncul pada jam yang telah ditentukan di perangkat Android, meskipun aplikasi Rutinku sedang tidak dibuka oleh pengguna.
4. **Akurasi Logika Waktu:** Ketika pengguna melakukan check-in hari ini, angka streak bertambah +1. Jika hari berganti tanpa check-in, sistem berhasil mereset nilai streak menjadi 0.
