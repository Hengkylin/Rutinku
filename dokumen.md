# P4 — Habit Tracker State Management

## Tujuan Feature

Feature **Manajemen Kebiasaan (Habit Tracker)** menerapkan form dan state management dengan Riverpod. Implementasi awal P4 ini menggunakan repository in-memory dengan simulasi *delay* untuk mendemonstrasikan alur data asinkron sebelum nantinya diintegrasikan dengan database sungguhan.

## Arsitektur

```text
DashboardScreen (widget/UI)
  → HabitNotifier (Riverpod state controller)
  → HabitRepository (data abstraction & in-memory storage)

Lokasi kode:

lib/screens/dashboard_screen.dart — UI, form tambah kebiasaan, dan integrasi state.

lib/notifiers/habit_notifier.dart — state loading, data, empty, error, retry, dan submit.

lib/repositories/habit_repository.dart — kontrak repository dan simulasi data lokal.

lib/models/habit_model.dart — entity dan struktur data input.

Kondisi,Tampilan,Test
Initial loading,CircularProgressIndicator ketika repository memuat data awal,shows initial loading while habits data is fetched
Data berhasil dimuat,Daftar kartu rutinitas dan jumlah gamifikasi (Primogems),shows loaded data when a habit exists
Empty state,"Pesan ""Belum ada rutinitas"" dan instruksi untuk menambah",shows empty state when no habit has been saved
Error + retry,Pesan gagal memuat dan tombol Coba Lagi,shows error state and retry loads the habit again
Validasi form,Nama kebiasaan wajib diisi minimal 3 karakter,validates required name length
Loading submit,"Tombol ""Simpan"" menampilkan loading dan ter-disable agar tidak double tap",shows submit loading and prevents a double submit

Hasil Verifikasi
Perintah yang dijalankan:

PowerShell
flutter test test/widget_test.dart
Hasil pada 8 Oktober 2026:

Plaintext
00:06 +1: All tests passed!


***

### 2. Isi file `ai-usage-p4.md`

```markdown
# AI Usage Record — P4

## Tool

Gemini & Antigravity AI Assistant digunakan untuk membantu membuat boilerplate Riverpod, menyusun struktur komponen UI, serta melakukan review logika state management.

## Prompt yang Digunakan

> "Tugas Anda adalah membuat satu feature Flutter yang menerapkan state management, form, dan validasi secara nyata. Feature wajib memiliki minimal enam kondisi UI: initial loading, data berhasil dimuat, empty state, error state dengan tombol retry, validasi input pada form, serta loading saat proses submit agar pengguna tidak dapat melakukan double tap. Gunakan state management yang konsisten, misalnya Riverpod, dan pisahkan tanggung jawab antara widget, notifier/use case, serta repository. Sertakan widget test untuk setiap state utama dan dokumentasikan hasilnya dengan screenshot atau video singkat. Anda boleh menggunakan Codex atau Gemini untuk membantu membuat boilerplate, test, atau melakukan review kode, tetapi Anda tetap wajib memahami, menjelaskan, dan bertanggung jawab atas kode yang dikumpulkan; cantumkan prompt AI yang digunakan serta bagian kode yang Anda periksa atau perbaiki sendiri."

## Bagian yang Ditinjau dan Diperbaiki Sendiri

- Memilih feature Habit Management (Dashboard & Tambah Kebiasaan) karena ini merupakan fungsionalitas inti dari aplikasi RutinKu.
- Mengontrol penggunaan `AsyncValue.guard` pada `habit_notifier.dart` untuk memastikan UI tidak *crash* ketika repository melempar exception saat simulasi gagal jaringan.
- Memvalidasi penggunaan `GlobalKey<FormState>` dan pemisahan state lokal `_isSubmitting` di dalam `StatefulWidget` dialog form, sehingga tombol benar-benar nonaktif saat proses asinkron berjalan.
- Mengembangkan logika tambahan untuk fitur Gamifikasi (Primogems) dan *Optimistic UI Update* saat melakukan *check-in* harian agar antarmuka merespons tanpa jeda loading.
- Menjalankan ulang widget test di terminal sampai hasil pengujian UI menyatakan lulus (*All tests passed!*).

## Tanggung Jawab Mahasiswa

Mahasiswa perlu dapat menjelaskan alur `Widget → Notifier → Repository`, alasan membungkus root aplikasi dengan `ProviderScope` di `main.dart`, serta mekanisme penonaktifan tombol (*disabled state*) saat proses submit berlangsung untuk mencegah pengiriman data berulang.
