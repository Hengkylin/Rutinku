# Rutinku - Mobile Habit Tracker App 🚀

## Deskripsi Masalah
Banyak orang kesulitan mempertahankan konsistensi saat mencoba membangun kebiasaan baru. Kegagalan ini sering terjadi karena mereka tidak memiliki alat pencatat progres yang praktis dan tidak adanya dorongan visual (seperti *streak*) untuk memotivasi mereka secara harian[cite: 2]. Selain itu, pengguna sering kali lupa membuka aplikasi jika tidak diingatkan, dan pencatatan yang hanya tersimpan di memori internal *smartphone* rawan hilang jika berganti perangkat[cite: 2].

## Profil Target Pengguna
- **Individu dengan Mobilitas Tinggi:** Pelajar, mahasiswa, dan pekerja yang selalu membawa *smartphone* setiap hari[cite: 2].
- **Pemula dalam Produktivitas:** Siapa saja yang ingin membangun rutinitas positif baru dan membutuhkan aplikasi pengingat yang otomatis dan datanya aman tersimpan secara *online*[cite: 2].

## Manfaat Aplikasi
- **Meningkatkan Konsistensi:** Memberikan motivasi visual berupa perhitungan *streak* (hari berturut-turut) yang mendorong pengguna agar tidak memutus rantai rutinitas[cite: 2].
- **Pengingat Aktif:** Mencegah pengguna lupa melakukan kebiasaan berkat adanya notifikasi *push* otomatis yang muncul langsung di layar Android mereka[cite: 2].
- **Data Aman & Fleksibel:** Memudahkan pengguna mengakses riwayat kedisiplinan mereka dari perangkat mana saja karena data diamankan melalui sistem *login* dan tersinkronisasi di *cloud*[cite: 2].

## Daftar Fitur Inti
> *Target penyelesaian dalam 12 pertemuan.*
1. **Autentikasi Pengguna Praktis:** Fitur pendaftaran akun baru dan *login* pribadi sederhana menggunakan layanan *Backend-as-a-Service* (BaaS)[cite: 2].
2. **Manajemen Kebiasaan (CRUD) & Sinkronisasi Cloud:** Fitur untuk menambah, membaca, mengedit, dan menghapus target kebiasaan harian yang datanya langsung tersimpan dan tersinkronisasi secara persisten di *Cloud Database*[cite: 2].
3. **Sistem *Daily Check-in* & Kalkulasi *Streak*:** Tombol di antarmuka utama untuk menandai kebiasaan yang sudah diselesaikan pada hari ini[cite: 2]. Logika aplikasi akan membaca histori *database* untuk menghitung jumlah *streak* atau meresetnya ke 0 jika terlewat satu hari[cite: 2].
4. **Android *Local Push Notifications*:** Sistem pengingat terjadwal yang diatur oleh aplikasi secara lokal di perangkat Android untuk memunculkan notifikasi pada jam tertentu, meskipun aplikasi sedang dalam keadaan tertutup (*background*)[cite: 2].
5. **Ringkasan Progres Mingguan:** Halaman statistik sederhana yang menarik histori 7 hari ke belakang dari *database* untuk menampilkan riwayat *check-in* pengguna[cite: 2].

## Fitur yang Tidak Dikerjakan
1. **Pembuatan API Backend dari Nol:** Aplikasi tidak menggunakan arsitektur *backend* tradisional (seperti Node.js/Express) atau server notifikasi (*Remote Push Notifications*), melainkan memanfaatkan layanan BaaS (seperti Firebase/Supabase) dan *Local Notifications* untuk mempercepat pengembangan[cite: 2].
2. Kompatibilitas dan pengaturan *Push Notification* khusus untuk sistem operasi iOS (Fokus pengembangan murni untuk Android terlebih dahulu)[cite: 2].
3. Integrasi dengan perangkat keras (seperti *Smartwatch* atau *Fitness Tracker*)[cite: 2].
4. Fitur jejaring sosial (seperti *leaderboard* antar pengguna atau berbagi progres ke media sosial)[cite: 2].
5. Mode murni *Offline* (karena aplikasi ini sekarang membutuhkan koneksi internet untuk sinkronisasi *database* dan validasi *Login*)[cite: 2].

## Kriteria Aplikasi Dinyatakan Berhasil
1. **Fungsi Autentikasi Berjalan:** Pengguna dapat mendaftar akun baru, melakukan *login*, dan sistem berhasil memberikan akses (*token/session*) hanya untuk melihat data kebiasaan miliknya sendiri[cite: 2].
2. **Sinkronisasi Database Sukses:** Operasi penambahan dan *check-in* kebiasaan berhasil dikirim dan tersimpan di *Cloud Database*, serta data tidak hilang ketika pengguna *login* di perangkat Android yang berbeda[cite: 2].
3. **Notifikasi *Background* Berfungsi:** *Push notification* (berbasis jadwal lokal) sukses muncul pada jam yang telah ditentukan di perangkat Android, meskipun aplikasi Rutinku sedang tidak dibuka oleh pengguna[cite: 2].
4. **Akurasi Logika Waktu:** Ketika pengguna melakukan *check-in* hari ini, angka *streak* bertambah +1[cite: 2]. Jika hari berganti tanpa *check-in*, sistem berhasil mereset nilai *streak* menjadi 0 saat aplikasi mendeteksi pergantian tanggal dari histori log *database*[cite: 2].
