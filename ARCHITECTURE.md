# Arsitektur Sistem - Rutinku (Mobile Habit Tracker)

Dokumen ini menjelaskan rancangan arsitektur, tumpukan teknologi (*tech stack*), struktur proyek, dan skema data untuk aplikasi *mobile* Rutinku.

## 1. Tumpukan Teknologi (*Tech Stack*)
*   **Frontend (Mobile):** Flutter (UI Toolkit).
*   **Bahasa Pemrograman:** Dart (Mendukung *Null Safety* dan *Object-Oriented*).
*   **Backend & Database (BaaS):** Firebase (Authentication & Cloud Firestore).
*   **State Management:** Provider / Riverpod (untuk manajemen state global).
*   **Sistem Notifikasi:** `flutter_local_notifications` (untuk *Local Push Notifications*).

## 2. Alur Sistem (*System Flow*)
1.  **Autentikasi:** Aplikasi berkomunikasi langsung dengan Firebase Auth untuk mendaftarkan dan memvalidasi pengguna. Sesi disimpan menggunakan `flutter_secure_storage`.
2.  **Sinkronisasi Data (CRUD):** Semua operasi pembuatan, pengeditan, dan penghapusan kebiasaan dikirim dari aplikasi *mobile* ke Cloud Database (Firestore) menggunakan Firebase SDK untuk Flutter.
3.  **Kalkulasi Streak:** Saat aplikasi dibuka, fungsi lokal akan membandingkan tanggal hari ini dengan tanggal *check-in* terakhir di *database* untuk menentukan status *streak*.
4.  **Notifikasi Lokal:** Aplikasi mendaftarkan jadwal pengingat ke sistem operasi Android menggunakan API lokal ponsel tanpa perlu instruksi dari *server cloud*.

## 3. Skema Database (NoSQL - Firestore)

### A. Koleksi `Users`
*   `id` (String, Primary Key / UID dari Auth)
*   `email` (String)
*   `createdAt` (Timestamp)

### B. Koleksi `Habits`
*   `id` (String, Auto-generated)
*   `userId` (String, Foreign Key -> Users)
*   `title` (String)
*   `currentStreak` (Number)
*   `reminderTime` (String)
*   `createdAt` (Timestamp)

### C. Koleksi `CheckIns`
*   `id` (String, Auto-generated)
*   `habitId` (String, Foreign Key -> Habits)
*   `userId` (String, Foreign Key -> Users)
*   `completedAt` (Timestamp)

## 4. Struktur Direktori Proyek

Proyek ini mengadopsi standar arsitektur modular Flutter:

```text
rutinku_flutter/
│
├── lib/
│   ├── main.dart                  # Entri utama aplikasi
│   ├── app.dart                   # Root widget dan tema
│   │
│   ├── routes/                    # Manajemen navigasi
│   │   └── app_routes.dart        
│   │
│   ├── screens/                   # Halaman utama (UI Level)
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   └── profile_screen.dart
│   │
│   ├── widgets/                   # Komponen UI yang reusable
│   │   ├── primary_button.dart
│   │   └── app_text_field.dart
│   │
│   ├── models/                    # Struktur data (Class)
│   │   └── user_model.dart
│   │
│   └── services/                  # Logika eksternal (API / Firebase)
│       └── auth_service.dart
│
└── pubspec.yaml                   # Daftar dependensi package Flutter