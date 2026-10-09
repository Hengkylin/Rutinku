# Laporan Tugas P4 — State Management (RutinKu)

## 1. Tujuan Feature
Feature **Manajemen Kebiasaan (Habit Tracker)** menerapkan form dan state management secara reaktif menggunakan **Riverpod**. Arsitektur dibangun dengan memisahkan tanggung jawab antara tampilan (UI), pengelola state (Notifier), dan operasi data (Repository).

## 2. Posisi Kode & Arsitektur
```text
DashboardScreen & AddHabitBottomSheet (Layer UI)
  → HabitNotifier (Layer State Controller)
  → HabitRepository (Layer Data Access)

```

* **`lib/screens/dashboard_screen.dart`** — Menampilkan daftar data, *loading*, *empty state*, dan *error state*.
* **`lib/widgets/add_habit_bottom_sheet.dart`** — Menangani form input, validasi, dan *loading submit*.
* **`lib/notifiers/habit_notifier.dart`** — Mengelola state (`AsyncLoading`, `AsyncData`, `AsyncError`) dan menjembatani UI dengan data.
* **`lib/repositories/habit_repository.dart`** — Kontrak operasi CRUD murni.

## 3. Enam Kondisi UI Wajib

| Kondisi | Letak File & Tampilan | Status Test |
| --- | --- | --- |
| **Initial loading** | `dashboard_screen.dart`: `habitState.when(loading: ...)` memunculkan `CircularProgressIndicator` | ✅ Lulus |
| **Data berhasil dimuat** | `dashboard_screen.dart`: `habitState.when(data: ...)` me-render `ListView.builder` berisi kartu kebiasaan | ✅ Lulus |
| **Empty state** | `dashboard_screen.dart`: Jika array kosong, muncul teks "Belum ada rutinitas" | ✅ Lulus |
| **Error + retry** | `dashboard_screen.dart`: `habitState.when(error: ...)` memunculkan pesan merah & tombol "Coba Lagi" untuk memicu `retryFetch()` | ✅ Lulus |
| **Validasi form** | `add_habit_bottom_sheet.dart`: Teks merah muncul jika form kosong atau kurang dari 3 karakter | ✅ Lulus |
| **Loading submit** | `add_habit_bottom_sheet.dart`: Tombol "Simpan" berubah menjadi loading dan *disabled* (mencegah *double tap*) | ✅ Lulus |

## 4. AI Usage Record — P4

* **Tool:** Gemini & Antigravity AI Assistant.
* **Prompt Utama:** *"Tugas Anda adalah membuat satu feature Flutter yang menerapkan state management, form, dan validasi secara nyata. Feature wajib memiliki minimal enam kondisi UI..."*
* **Bagian yang ditinjau dan diperbaiki mandiri:** Memvalidasi penggunaan `AsyncValue.guard` pada Notifier untuk mencegah *crash*, memastikan form menggunakan `GlobalKey<FormState>`, serta memastikan tombol dinonaktifkan (`onPressed: null`) pada layer UI saat proses submit asinkron berjalan untuk mencegah duplikasi data.

---
Link Video Dokumentasi: https://drive.google.com/file/d/19dYYtVZFqdKiJLgcz7iDsIKp91DmGR7x/view?usp=drive_link