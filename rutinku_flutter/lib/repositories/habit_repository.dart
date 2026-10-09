import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit_model.dart';

class HabitRepository {
  // Kunci utama untuk menyimpan data di memori lokal (Storage)
  static const String _storageKey = 'rutinku_habits';

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

    if (habitsJson != null) {
      final List<dynamic> decodedData = json.decode(habitsJson);
      return decodedData.map((map) => HabitModel.fromMap(map)).toList();
    }
    return []; // Kembalikan list kosong jika belum ada data di HP
  }

  // CREATE: Menambah data dan langsung simpan ke Storage
  Future<void> addHabit(
    String title, {
    String? category,
    String? reminderTime,
  }) async {
    final habits = await fetchHabits();
    final newHabit = HabitModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      reminderTime: reminderTime,
    );
    habits.add(newHabit);
    await _saveHabitsToStorage(habits);
  }

  // UPDATE (Edit): Mengubah data form dan simpan ke Storage
  Future<void> updateHabit(
    String id,
    String title,
    String category,
    String reminderTime,
  ) async {
    final habits = await fetchHabits();
    final index = habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      habits[index] = habits[index].copyWith(
        title: title,
        category: category,
        reminderTime: reminderTime,
      );
      await _saveHabitsToStorage(habits);
    }
  }

  // UPDATE (Gamifikasi): Mengubah status check-in dan simpan ke Storage
  Future<void> toggleCheckIn(String id) async {
    final habits = await fetchHabits();
    final index = habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      habits[index] = habits[index].copyWith(
        isCompletedToday: !habits[index].isCompletedToday,
      );
      await _saveHabitsToStorage(habits);
    }
  }

  // DELETE: Menghapus data dan simpan perubahan ke Storage
  Future<void> deleteHabit(String id) async {
    final habits = await fetchHabits();
    habits.removeWhere((h) => h.id == id);
    await _saveHabitsToStorage(habits);
  }

  // RESTORE (Undo): Mengembalikan data yang terhapus ke Storage
  Future<void> restoreHabit(HabitModel habit) async {
    final habits = await fetchHabits();
    habits.add(habit);
    await _saveHabitsToStorage(habits);
  }
}
