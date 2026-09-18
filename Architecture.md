# Arsitektur Sistem - Rutinku (Mobile Habit Tracker)

Dokumen ini menjelaskan rancangan arsitektur, tumpukan teknologi (*tech stack*), struktur proyek, dan skema data untuk aplikasi *mobile* Rutinku.

## 1. Tumpukan Teknologi (*Tech Stack*)

Aplikasi ini menggunakan arsitektur *Serverless/Backend-as-a-Service* (BaaS) untuk mempercepat siklus pengembangan.

*   **Frontend (Mobile):** React Native dengan *framework* Expo.
*   **Bahasa Pemrograman:** TypeScript (untuk keamanan tipe data dan skalabilitas kode).
*   **Backend & Database (BaaS):** Firebase (Authentication & Cloud Firestore) atau Supabase.
*   **State Management:** React Context API & Custom Hooks.
*   **Sistem Notifikasi:** `expo-notifications` (untuk *Local Push Notifications* di OS Android).

## 2. Alur Sistem (*System Flow*)

1.  **Autentikasi:** Aplikasi berkomunikasi langsung dengan layanan BaaS (Firebase Auth) untuk mendaftarkan dan memvalidasi pengguna menggunakan *Email/Password*. Sesi pengguna (token) disimpan secara aman secara lokal di perangkat.
2.  **Sinkronisasi Data (CRUD):** Semua operasi pembuatan, pengeditan, dan penghapusan kebiasaan, serta log *check-in* dikirim langsung dari aplikasi *mobile* ke *Cloud Database* (Firestore) menggunakan SDK resmi. Data diikat berdasarkan `userId` yang sedang aktif.
3.  **Kalkulasi Streak:** Saat aplikasi dibuka atau saat pengguna melakukan *check-in*, fungsi logika di dalam aplikasi (atau memanfaatkan *Cloud Functions* ringan) akan membandingkan tanggal hari ini dengan tanggal *check-in* terakhir di *database* untuk menentukan apakah *streak* bertambah, bertahan, atau di-reset ke 0.
4.  **Notifikasi Lokal:** Aplikasi mendaftarkan jadwal pengingat (misal: pukul 20:00 setiap hari) ke sistem operasi Android menggunakan API lokal. OS Android akan memunculkan notifikasi pada jam tersebut tanpa perlu instruksi lanjutan dari *server cloud*.

## 3. Skema Database (NoSQL - Firestore)

Sistem menggunakan tiga koleksi (*collections*) utama:

### A. Koleksi `Users`
Menyimpan profil dasar pengguna.
*   `id` (String, Primary Key / UID dari Auth)
*   `email` (String)
*   `createdAt` (Timestamp)

### B. Koleksi `Habits`
Menyimpan daftar kebiasaan yang dibuat oleh pengguna.
*   `id` (String, Auto-generated)
*   `userId` (String, Foreign Key -> Users)
*   `title` (String, contoh: "Minum Air 2 Liter")
*   `currentStreak` (Number, perhitungan *streak* saat ini)
*   `reminderTime` (String, contoh: "20:00" - opsional untuk notifikasi)
*   `createdAt` (Timestamp)

### C. Koleksi `CheckIns` (Sub-collection / Koleksi Terpisah)
Menyimpan riwayat penyelesaian (*log*) dari setiap kebiasaan.
*   `id` (String, Auto-generated)
*   `habitId` (String, Foreign Key -> Habits)
*   `userId` (String, Foreign Key -> Users)
*   `completedAt` (Timestamp / ISO 8601 Date String)

## 4. Struktur Direktori Proyek

Proyek ini menggunakan struktur standar React Native (Expo) yang memisahkan logika UI, akses data, dan tipe TypeScript.

```text
rutinku-mobile/
│
├── App.tsx                 # Entri utama aplikasi dan konfigurasi navigasi
├── app.json                # Konfigurasi aplikasi Expo (nama, ikon, versi)
│
├── src/
│   ├── assets/             # Gambar, ikon, dan font lokal
│   │
│   ├── components/         # Komponen UI yang dapat digunakan ulang (Button, Card, dll)
│   │
│   ├── screens/            # Layar utama aplikasi
│   │   ├── LoginScreen.tsx
│   │   ├── DashboardScreen.tsx
│   │   └── StatisticsScreen.tsx
│   │
│   ├── hooks/              # Custom React Hooks (logika bisnis)
│   │   ├── useAuth.ts      # Mengelola state login/logout
│   │   ├── useHabits.ts    # Mengelola operasi CRUD ke database
│   │   └── useStreak.ts    # Logika kalkulasi waktu dan reset streak
│   │
│   ├── services/           # Konfigurasi layanan eksternal
│   │   ├── firebase.ts     # Inisialisasi Firebase Auth dan Firestore
│   │   └── notification.ts # Konfigurasi expo-notifications
│   │
│   └── types/              # Definisi tipe TypeScript (Interfaces)
│       └── index.ts        # Interface User, Habit, dan CheckIn
│
├── .env                    # Variabel environment (API Keys BaaS) - Tidak di-commit
├── package.json            # Daftar dependensi NPM
└── tsconfig.json           # Konfigurasi TypeScript
