# Rutinku - Web Habit Tracker App 🚀

## Deskripsi Masalah
Banyak orang kesulitan mempertahankan konsistensi saat mencoba membangun kebiasaan baru (seperti minum air 2 liter sehari, olahraga ringan, atau membaca buku). Kegagalan ini sering terjadi karena mereka tidak memiliki alat pencatat progres yang praktis dan tidak adanya dorongan visual (seperti *streak*) untuk memotivasi mereka secara harian. Akibatnya, motivasi mudah hilang dan kebiasaan baik gagal terbentuk.

## Profil Target Pengguna
- **Individu (Pelajar, Mahasiswa, Pekerja):** Siapa saja yang ingin membangun dan melacak rutinitas positif baru setiap harinya.
- **Pengguna Desktop & Browser-based:** Orang yang sering menghabiskan waktu di depan komputer (bekerja/belajar) dan membutuhkan aplikasi web responsif yang mudah diakses kapan saja lewat *browser* tanpa perlu menginstal aplikasi *mobile*.

## Manfaat Aplikasi
- **Meningkatkan Konsistensi:** Memberikan motivasi visual berupa perhitungan *streak* (hari berturut-turut) yang mendorong pengguna agar tidak memutus rantai rutinitas.
- **Pencatatan Cepat & Bebas Hambatan:** Memudahkan pengguna untuk mencatat (*check-in*) kebiasaan harian mereka dalam satu kali klik langsung dari *browser* mereka.
- **Evaluasi Diri Terfokus:** Membantu pengguna melihat pola kedisiplinan mereka melalui ringkasan progres mingguan yang ditampilkan dalam *dashboard* sederhana.

## Daftar Fitur Inti
> *Target penyelesaian dalam 12 pertemuan.*
1. **Manajemen Kebiasaan (CRUD):** Fitur untuk menambah (*Create*), membaca (*Read*), mengedit (*Update*), dan menghapus (*Delete*) target kebiasaan harian.
2. **Sistem *Daily Check-in*:** Tombol interaktif untuk menandai (centang) kebiasaan yang sudah diselesaikan pada hari ini.
3. **Kalkulasi *Streak* Otomatis:** Sistem logika yang menghitung berapa hari berturut-turut sebuah kebiasaan berhasil dilakukan. Jika terlewat satu hari (pergantian tanggal tanpa *check-in*), *streak* akan di-reset kembali ke 0.
4. **Ringkasan Progres Mingguan:** Tampilan antarmuka (*dashboard*) yang menunjukkan riwayat *check-in* pengguna selama 7 hari terakhir dalam bentuk kalender mini atau grafik sederhana.
5. **Penyimpanan Data Lokal (*Local Storage/IndexedDB*):** Data kebiasaan dan riwayat *check-in* disimpan secara lokal di *browser* pengguna, sehingga aplikasi bisa langsung digunakan tanpa perlu sistem *login* yang rumit (cocok untuk prototipe awal).

## Fitur yang Tidak Dikerjakan (Out of Scope)
1. Aplikasi versi *Mobile* (Android/iOS).
2. Sistem *Login/Authentication* multi-pengguna dan sinkronisasi *Cloud Database* (fokus pada penyimpanan lokal).
3. Integrasi dengan perangkat keras (seperti *Smartwatch* atau *Fitness Tracker*).
4. Fitur jejaring sosial (Forum komunitas, berbagi progres ke media sosial).
5. Sistem notifikasi otomatis (karena keterbatasan izin notifikasi pada *browser*).

## Kriteria Aplikasi Dinyatakan Berhasil
1. **Aplikasi Berjalan:** *Frontend* aplikasi web (React) dapat dijalankan di lingkungan lokal (*localhost*) atau di-*deploy* (misal via Vercel/Netlify) dan berjalan tanpa *error* fatal.
2. **Fungsi CRUD Berjalan:** Pengguna sukses melakukan penambahan, pengeditan, dan penghapusan daftar kebiasaan, serta data tersebut persisten (tidak hilang saat *browser* di-*refresh*).
3. **Akurasi Logika *Streak*:** Ketika pengguna melakukan *check-in* hari ini, angka *streak* bertambah +1. Logika aplikasi sukses mendeteksi pergantian hari dan me-reset *streak* ke 0 jika tidak ada *check-in* di hari sebelumnya.
4. **UI Responsif:** Tampilan aplikasi tetap rapi dan bisa digunakan dengan baik saat diakses melalui *browser desktop* maupun ukuran layar yang lebih kecil.

---
**Tech Stack:**
- **Frontend Framework:** React
- **Bahasa Pemrograman:** TypeScript
- **Styling:** *(Opsional: Tailwind CSS / CSS Modules)*
- **State Management / Storage:** React Context API & Browser LocalStorage