import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit_model.dart';
import '../services/notification_service.dart';

class HabitRepository {
  // Kunci utama untuk menyimpan data di memori lokal (Storage)
  static const String storageKey = 'rutinku_habits';
  static const String _storageKey = storageKey;

  final NotificationService _notificationService;
  final DateTime Function() _clock;

  HabitRepository({
    NotificationService? notificationService,
    DateTime Function()? clock,
  })  : _notificationService = notificationService ?? NotificationService(),
        _clock = clock ?? DateTime.now;

  /// Antrian operasi tulis bersama (issue #6).
  ///
  /// Setiap operasi tulis membaca SELURUH daftar dari SharedPreferences,
  /// mengubah satu habit, lalu menulis ulang seluruh daftar. Tanpa antrian,
  /// dua operasi yang berjalan bersamaan (mis. mencentang dua rutinitas
  /// dengan cepat) membaca data lama yang sama dan tulisan terakhir menimpa
  /// yang pertama, sehingga centang yang sudah tampil di layar hilang setelah
  /// aplikasi ditutup paksa.
  ///
  /// Antrian sengaja per instance (bukan static): aplikasi hanya memakai satu
  /// instance lewat `habitRepositoryProvider`, dan antrian static yang
  /// dibagi lintas zona (mis. `tester.runAsync` vs FakeAsync di widget test)
  /// bisa menunggu Future yang tidak pernah selesai di zona lain.
  Future<void> _writeQueue = Future<void>.value();

  /// Menjalankan [action] setelah semua operasi tulis sebelumnya selesai.
  /// Error tetap diteruskan ke pemanggil tanpa menghentikan antrian.
  Future<T> _locked<T>(Future<T> Function() action) {
    final result = _writeQueue.then((_) => action());
    _writeQueue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Mengubah HabitModel.id (String) menjadi int untuk ID notifikasi (32-bit positive int)
  int _notificationIdFromHabitId(String id) {
    return id.hashCode & 0x7FFFFFFF;
  }

  /// ID notifikasi mingguan untuk [weekday] (1..7) dari ID dasar sebuah
  /// rutinitas. Tetap 32-bit positif dan berbeda per hari.
  static int weeklyNotificationId(int baseId, int weekday) =>
      (baseId % 200000000) * 10 + weekday;

  /// Membatalkan semua pengingat sebuah rutinitas (harian + 7 mingguan).
  Future<void> _cancelAllReminders(String habitId) async {
    final base = _notificationIdFromHabitId(habitId);
    await _notificationService.cancelReminder(base);
    for (var day = 1; day <= 7; day++) {
      await _notificationService.cancelReminder(weeklyNotificationId(base, day));
    }
  }

  /// Menjadwalkan pengingat jika reminderTime tersedia (format "HH:mm").
  /// Rutinitas harian -> satu alarm harian; rutinitas dengan hari tertentu
  /// -> satu alarm mingguan per hari terjadwal (hari lain dibatalkan).
  /// Jika rutinitas hari ini sudah selesai, pengingat hari ini dilewati
  /// sehingga tidak muncul lagi untuk hari yang sudah dicentang (issue #7).
  Future<void> _scheduleReminderIfPresent(HabitModel habit) async {
    final reminderTime = habit.reminderTime;
    if (reminderTime != null && reminderTime.isNotEmpty) {
      final parts = reminderTime.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0].trim());
        final minute = int.tryParse(parts[1].trim());
        if (hour != null && minute != null) {
          final base = _notificationIdFromHabitId(habit.id);
          final title = 'Waktunya RutinKu: ${habit.title}';
          final body =
              'Yuk, sempatkan waktu untuk menyelesaikan rutinitas "${habit.title}"!';
          final skipToday = habit.isCompletedOn(_clock());

          if (habit.isDaily) {
            for (var day = 1; day <= 7; day++) {
              await _notificationService
                  .cancelReminder(weeklyNotificationId(base, day));
            }
            await _notificationService.scheduleDailyReminder(
              id: base,
              title: title,
              body: body,
              hour: hour,
              minute: minute,
              skipToday: skipToday,
            );
            return;
          }

          await _notificationService.cancelReminder(base);
          for (var day = 1; day <= 7; day++) {
            final id = weeklyNotificationId(base, day);
            if (habit.scheduledDays.contains(day)) {
              await _notificationService.scheduleWeeklyReminder(
                id: id,
                title: title,
                body: body,
                weekday: day,
                hour: hour,
                minute: minute,
                skipToday: skipToday,
              );
            } else {
              await _notificationService.cancelReminder(id);
            }
          }
        }
      }
    }
  }

  /// Dipanggil setelah record suatu tanggal berubah (check-in, progres,
  /// refleksi, foto). Hanya perubahan pada HARI INI yang memengaruhi
  /// pengingat berikutnya, jadi jadwal diatur ulang hanya untuk itu.
  Future<void> _refreshReminderAfterRecordChange(
    HabitModel habit,
    DateTime date,
  ) async {
    final today = _clock();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    if (!isToday) return;
    await _scheduleReminderIfPresent(habit);
  }

  // Fungsi internal untuk menyimpan list ke SharedPreferences
  Future<void> _saveHabitsToStorage(List<HabitModel> habits) async {
    final prefs = await SharedPreferences.getInstance();
    // Mengubah List of Object menjadi teks JSON
    final String encodedData = json.encode(
      habits.map((h) => h.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encodedData);
  }

  // READ: Mengambil data dari Storage
  Future<List<HabitModel>> fetchHabits({bool forceError = false}) async {
    if (forceError) throw Exception('Koneksi terputus.');

    final prefs = await SharedPreferences.getInstance();
    final String? habitsJson = prefs.getString(_storageKey);

    if (habitsJson != null && habitsJson.isNotEmpty) {
      final List<dynamic> decodedData = json.decode(habitsJson) as List<dynamic>;
      return decodedData
          .map((item) => HabitModel.fromMap(item as Map<String, dynamic>))
          .toList();
    }
    return []; // Kembalikan list kosong jika belum ada data di HP
  }

  // CREATE: Menambah data dan langsung simpan ke Storage
  Future<void> addHabit(
    String title, {
    String? category,
    String? reminderTime,
    String? parentHabitId,
    int targetValue = 1,
    String? unit,
    List<int>? scheduledDays,
  }) {
    return _locked(() async {
      final habits = await fetchHabits();
      final newHabit = HabitModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        category: category,
        reminderTime: reminderTime,
        parentHabitId: parentHabitId,
        targetValue: targetValue,
        unit: unit,
        scheduledDays: scheduledDays,
      );
      habits.add(newHabit);
      await _saveHabitsToStorage(habits);
      await _scheduleReminderIfPresent(newHabit);
    });
  }

  // UPDATE (Edit): Mengubah data form dan simpan ke Storage
  Future<void> updateHabit(
    String id,
    String title,
    String category,
    String reminderTime, {
    String? parentHabitId,
    int targetValue = 1,
    String? unit,
    List<int>? scheduledDays,
  }) {
    return _locked(() async {
      final habits = await fetchHabits();
      final index = habits.indexWhere((h) => h.id == id);
      if (index != -1) {
        final updatedHabit = habits[index].copyWith(
          title: title,
          category: category,
          reminderTime: reminderTime,
          parentHabitId: parentHabitId,
          clearParentHabitId: parentHabitId == null,
          targetValue: targetValue,
          unit: unit,
          clearUnit: unit == null,
          scheduledDays: scheduledDays,
        );
        habits[index] = updatedHabit;
        await _saveHabitsToStorage(habits);

        if (reminderTime.isNotEmpty) {
          await _scheduleReminderIfPresent(updatedHabit);
        } else {
          await _cancelAllReminders(id);
        }
      }
    });
  }

  // UPDATE (Gamifikasi): Mengubah status check-in dan simpan ke Storage
  Future<void> toggleCheckIn(String id, DateTime date) {
    return _locked(() async {
      final habits = await fetchHabits();
      final index = habits.indexWhere((h) => h.id == id);
      if (index == -1) return;

      habits[index] = habits[index].toggleCheckIn(date);
      await _saveHabitsToStorage(habits);
      await _refreshReminderAfterRecordChange(habits[index], date);
    });
  }

  // UPDATE (Progressive Habit): Menambah progres angka harian (+1) dan simpan ke Storage
  Future<void> incrementHabitProgress(String id, DateTime date) {
    return _locked(() async {
      final habits = await fetchHabits();
      final index = habits.indexWhere((h) => h.id == id);
      if (index == -1) return;

      habits[index] = habits[index].incrementProgress(date);
      await _saveHabitsToStorage(habits);
      await _refreshReminderAfterRecordChange(habits[index], date);
    });
  }

  // UPDATE (Mood & Recovery Record): Mengubah status, mood, dan catatan refleksi
  Future<void> updateRecordDetails(
    String id,
    DateTime date, {
    String? status,
    String? mood,
    String? note,
    String? momentImagePath,
  }) {
    return _locked(() async {
      final habits = await fetchHabits();
      final index = habits.indexWhere((h) => h.id == id);
      if (index != -1) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final habit = habits[index];
        final updatedRecords = List<HabitRecord>.from(habit.records);
        final recordIndex = updatedRecords.indexWhere((r) => r.date == dateStr);

        if (recordIndex != -1) {
          // copyWith agar field lain (mis. currentValue) tidak hilang
          updatedRecords[recordIndex] = updatedRecords[recordIndex].copyWith(
            status: status,
            mood: mood,
            note: note,
            momentImagePath: momentImagePath,
          );
        } else {
          updatedRecords.add(
            HabitRecord(
              date: dateStr,
              status: status ?? 'completed',
              mood: mood,
              note: note,
              momentImagePath: momentImagePath,
            ),
          );
        }

        habits[index] = habit.copyWith(records: updatedRecords);
        await _saveHabitsToStorage(habits);
        await _refreshReminderAfterRecordChange(habits[index], date);
      }
    });
  }

  // UPDATE (Visual Habit Journal): Menyimpan path foto momen ke check-in hari ini
  Future<void> saveMomentImage(
    String id,
    DateTime date,
    String imagePath,
  ) {
    return _locked(() async {
      final habits = await fetchHabits();
      final index = habits.indexWhere((h) => h.id == id);
      if (index != -1) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final habit = habits[index];
        final updatedRecords = List<HabitRecord>.from(habit.records);
        final recordIndex = updatedRecords.indexWhere((r) => r.date == dateStr);

        if (recordIndex != -1) {
          final existing = updatedRecords[recordIndex];
          updatedRecords[recordIndex] = existing.copyWith(
            status: 'completed',
            momentImagePath: imagePath,
          );
        } else {
          updatedRecords.add(
            HabitRecord(
              date: dateStr,
              status: 'completed',
              momentImagePath: imagePath,
            ),
          );
        }

        habits[index] = habit.copyWith(records: updatedRecords);
        await _saveHabitsToStorage(habits);
        await _refreshReminderAfterRecordChange(habits[index], date);
      }
    });
  }

  // DELETE: Menghapus data dan simpan perubahan ke Storage
  Future<void> deleteHabit(String id) {
    return _locked(() async {
      final habits = await fetchHabits();
      habits.removeWhere((h) => h.id == id);
      await _saveHabitsToStorage(habits);
      await _cancelAllReminders(id);
    });
  }

  // RESTORE (Undo): Mengembalikan data yang terhapus ke Storage
  Future<void> restoreHabit(HabitModel habit) {
    return _locked(() async {
      final habits = await fetchHabits();
      habits.add(habit);
      await _saveHabitsToStorage(habits);
      await _scheduleReminderIfPresent(habit);
    });
  }
}
