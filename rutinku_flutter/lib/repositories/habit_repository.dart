import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit_model.dart';
import '../services/notification_service.dart';

class HabitRepository {
  // Kunci utama untuk menyimpan data di memori lokal (Storage)
  static const String _storageKey = 'rutinku_habits';

  final NotificationService _notificationService;

  HabitRepository({NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService();

  /// Mengubah HabitModel.id (String) menjadi int untuk ID notifikasi (32-bit positive int)
  int _notificationIdFromHabitId(String id) {
    return id.hashCode & 0x7FFFFFFF;
  }

  /// Menjadwalkan pengingat harian jika reminderTime tersedia (format "HH:mm")
  Future<void> _scheduleReminderIfPresent(HabitModel habit) async {
    final reminderTime = habit.reminderTime;
    if (reminderTime != null && reminderTime.isNotEmpty) {
      final parts = reminderTime.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0].trim());
        final minute = int.tryParse(parts[1].trim());
        if (hour != null && minute != null) {
          await _notificationService.scheduleDailyReminder(
            id: _notificationIdFromHabitId(habit.id),
            title: 'Waktunya RutinKu: ${habit.title}',
            body: 'Yuk, sempatkan waktu untuk menyelesaikan rutinitas "${habit.title}"!',
            hour: hour,
            minute: minute,
          );
        }
      }
    }
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
  }) async {
    final habits = await fetchHabits();
    final newHabit = HabitModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      reminderTime: reminderTime,
      parentHabitId: parentHabitId,
    );
    habits.add(newHabit);
    await _saveHabitsToStorage(habits);
    await _scheduleReminderIfPresent(newHabit);
  }

  // UPDATE (Edit): Mengubah data form dan simpan ke Storage
  Future<void> updateHabit(
    String id,
    String title,
    String category,
    String reminderTime, {
    String? parentHabitId,
  }) async {
    final habits = await fetchHabits();
    final index = habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final updatedHabit = habits[index].copyWith(
        title: title,
        category: category,
        reminderTime: reminderTime,
        parentHabitId: parentHabitId,
        clearParentHabitId: parentHabitId == null,
      );
      habits[index] = updatedHabit;
      await _saveHabitsToStorage(habits);

      if (reminderTime.isNotEmpty) {
        await _scheduleReminderIfPresent(updatedHabit);
      } else {
        await _notificationService.cancelReminder(_notificationIdFromHabitId(id));
      }
    }
  }

  // UPDATE (Gamifikasi): Mengubah status check-in dan simpan ke Storage
  Future<void> toggleCheckIn(String id, DateTime date) async {
    final habits = await fetchHabits();
    final index = habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final habit = habits[index];
      final updatedRecords = List<HabitRecord>.from(habit.records);
      final existingIndex = updatedRecords.indexWhere((r) => r.date == dateStr);

      if (existingIndex != -1 && updatedRecords[existingIndex].status == 'completed') {
        updatedRecords.removeAt(existingIndex);
      } else if (existingIndex == -1) {
        updatedRecords.add(HabitRecord(date: dateStr, status: 'completed'));
      } else {
        updatedRecords[existingIndex] = HabitRecord(date: dateStr, status: 'completed');
      }

      habits[index] = habit.copyWith(records: updatedRecords);
      await _saveHabitsToStorage(habits);
    }
  }

  // UPDATE (Mood & Recovery Record): Mengubah status, mood, dan catatan refleksi
  Future<void> updateRecordDetails(
    String id,
    DateTime date, {
    String? status,
    String? mood,
    String? note,
  }) async {
    final habits = await fetchHabits();
    final index = habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final habit = habits[index];
      final updatedRecords = List<HabitRecord>.from(habit.records);
      final recordIndex = updatedRecords.indexWhere((r) => r.date == dateStr);

      if (recordIndex != -1) {
        final existing = updatedRecords[recordIndex];
        updatedRecords[recordIndex] = HabitRecord(
          date: dateStr,
          status: status ?? existing.status,
          mood: mood ?? existing.mood,
          note: note ?? existing.note,
        );
      } else {
        updatedRecords.add(
          HabitRecord(
            date: dateStr,
            status: status ?? 'completed',
            mood: mood,
            note: note,
          ),
        );
      }

      habits[index] = habit.copyWith(records: updatedRecords);
      await _saveHabitsToStorage(habits);
    }
  }

  // DELETE: Menghapus data dan simpan perubahan ke Storage
  Future<void> deleteHabit(String id) async {
    final habits = await fetchHabits();
    habits.removeWhere((h) => h.id == id);
    await _saveHabitsToStorage(habits);
    await _notificationService.cancelReminder(_notificationIdFromHabitId(id));
  }

  // RESTORE (Undo): Mengembalikan data yang terhapus ke Storage
  Future<void> restoreHabit(HabitModel habit) async {
    final habits = await fetchHabits();
    habits.add(habit);
    await _saveHabitsToStorage(habits);
    await _scheduleReminderIfPresent(habit);
  }
}
