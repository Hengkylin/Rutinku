# RutinKu - Mobile Habit Tracker App 🚀

## Deskripsi Masalah
Banyak orang kesulitan mempertahankan konsistensi saat mencoba membangun kebiasaan baru. Kegagalan ini sering terjadi karena mereka tidak memiliki alat pencatat progres yang praktis dan tidak adanya dorongan visual (seperti *streak* maupun dokumentasi momen) untuk memotivasi mereka secara harian. Selain itu, pengguna sering kali lupa membuka aplikasi jika tidak diingatkan, dan pencatatan yang hanya tersimpan di memori internal *smartphone* rawan hilang jika berganti perangkat tanpa fitur pencadangan *cloud*.

## Profil Target Pengguna
- **Individu dengan Mobilitas Tinggi:** Pelajar, mahasiswa, dan pekerja yang selalu membawa *smartphone* setiap hari.
- **Pemula dalam Produktivitas:** Siapa saja yang ingin membangun rutinitas positif baru dan membutuhkan aplikasi pengingat otomatis dengan dukungan penyimpanan lokal yang responsif sekaligus pencadangan data aman di *cloud*.

## Manfaat Aplikasi
- **Meningkatkan Konsistensi:** Memberikan motivasi visual berupa perhitungan *streak* (hari berturut-turut) dan jurnal foto harian yang mendorong pengguna agar tidak memutus rantai rutinitas.
- **Pengingat Aktif:** Mencegah pengguna lupa melakukan kebiasaan berkat adanya notifikasi terjadwal otomatis yang muncul langsung di layar Android mereka sesuai zona waktu perangkat.
- **Data Aman & Fleksibel:** Menyimpan aktivitas harian secara instan di perangkat (`SharedPreferences`) serta memudahkan pencadangan (*Backup*) dan pemulihan (*Restore*) lintas perangkat melalui sistem **Supabase Auth** dan **Supabase Cloud Sync (PostgreSQL JSONB)**.

## Daftar Fitur Inti
1. **Autentikasi Pengguna 3 Halaman (Supabase Auth):** Alur perlindungan akun modern dengan 3 layar terpisah — **Login** (`/login`), **Register** (`/register` dengan validasi konfirmasi password), dan **Lupa Password** (`/forgot-password` melalui pengiriman tautan reset via email).
2. **Manajemen Kebiasaan (CRUD), Templat, & *Habit Stacking*:** Fitur untuk menambah, membaca, mengedit, dan menghapus (beserta *undo*) target kebiasaan harian yang disimpan secara persisten di penyimpanan lokal (`SharedPreferences`).
3. **Cloud Sync Supabase (Backup, Fetch, & Restore JSONB):** Sinkronisasi data kebiasaan ke tabel PostgreSQL `user_data` di Supabase untuk mencadangkan data lokal ke *cloud* dan memulihkannya kembali kapan saja.
4. **Sistem *Daily Check-in*, Refleksi Mood, & Kalkulasi *Streak*:** Tombol responsif (*Optimistic UI*) untuk menandai kebiasaan selesai, mencatat suasana hati atau hari istirahat (*recovery mode*), serta menghitung *streak* secara akurat.
5. **Kamera / *Visual Habit Journal* ("Abadikan Momen"):** Fitur dokumentasi foto menggunakan kamera perangkat (`image_picker` & `path_provider`) untuk menyimpan bukti dan kenangan penyelesaian kebiasaan harian yang terintegrasi dengan riwayat kalender.
6. **Android *Local Push Notifications*:** Sistem pengingat harian terjadwal (`flutter_local_notifications` & `timezone`) yang memunculkan notifikasi pada jam tertentu meskipun aplikasi sedang tertutup (*background*).
7. **Kalender & Ringkasan Riwayat Kebiasaan:** Halaman kalender interaktif (`table_calendar`) serta indikator progres mingguan untuk memantau riwayat *check-in*, catatan refleksi, dan foto momen per tanggal.

## Fitur yang Tidak Dikerjakan
1. **Pembuatan API Backend Kustom dari Nol:** Aplikasi tidak membangun server *backend* mandiri (seperti Node.js/Express) atau *Remote Push Notification Server*, melainkan memanfaatkan layanan BaaS **Supabase** (Auth & PostgreSQL JSONB) dan *Local Notifications* agar pengembangan lebih fokus dan andal.
2. **Kompatibilitas Khusus iOS:** Konfigurasi izin dan *Local Notification* difokuskan terlebih dahulu untuk ekosistem Android.
3. **Integrasi Perangkat Keras Eksternal:** Belum mencakup sinkronisasi dengan *Smartwatch* atau *Fitness Tracker*.
4. **Fitur Jejaring Sosial:** Tidak mencakup *leaderboard* publik antar pengguna atau pembagian otomatis ke media sosial.

## Kriteria Aplikasi Dinyatakan Berhasil
1. **Fungsi Autentikasi Berjalan:** Pengguna dapat mendaftar akun baru, melakukan *login*, meminta tautan *reset password*, serta memperoleh sesi akses yang terisolasi untuk data akun miliknya sendiri melalui Supabase Auth.
2. **Persistensi Lokal & Sinkronisasi Cloud Sukses:** Data kebiasaan tersimpan utuh di perangkat meskipun aplikasi ditutup, serta operasi *Backup*, *Fetch*, dan *Restore* ke *Cloud Database* Supabase berjalan lancar sehingga data tidak hilang saat pengguna masuk di perangkat Android lain.
3. **Notifikasi *Background* & Kamera Berfungsi Aman:** Pengingat lokal muncul sesuai jadwal yang ditentukan pengguna dan fitur *"Abadikan Momen"* berhasil menyimpan foto jurnal kebiasaan tanpa menyebabkan *crash* meskipun izin perangkat ditolak atau aksi dibatalkan.
4. **Akurasi Logika Waktu & Pengujian Terverifikasi:** Perhitungan *streak* bertambah saat *check-in*, mendukung toleransi hari berjalan serta mode istirahat, dan seluruh **41 Unit & Widget Test** lulus 100% (`flutter test` & `flutter analyze` bersih tanpa isu).
