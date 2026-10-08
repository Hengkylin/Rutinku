import '../models/habit_model.dart';

class HabitRepository {
  final List<HabitModel> _mockDatabase = [];

  Future<List<HabitModel>> fetchHabits({bool forceError = false}) async {
    await Future.delayed(const Duration(seconds: 2));
    if (forceError) {
      throw Exception('Koneksi terputus. Gagal memuat data rutinitas.');
    }
    return _mockDatabase;
  }

  Future<void> addHabit(String title) async {
    await Future.delayed(const Duration(seconds: 1));
    final newHabit = HabitModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );
    _mockDatabase.add(newHabit);
  }

  // FITUR BARU: Edit
  Future<void> updateHabit(
    String id,
    String title,
    String category,
    String reminderTime,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    final index = _mockDatabase.indexWhere((h) => h.id == id);
    if (index != -1) {
      _mockDatabase[index] = _mockDatabase[index].copyWith(
        title: title,
        category: category,
        reminderTime: reminderTime,
      );
    }
  }

  // FITUR BARU: Toggle Check-in
  Future<void> toggleCheckIn(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockDatabase.indexWhere((h) => h.id == id);
    if (index != -1) {
      _mockDatabase[index] = _mockDatabase[index].copyWith(
        isCompletedToday: !_mockDatabase[index].isCompletedToday,
      );
    }
  }

  // FITUR BARU: Hapus
  Future<void> deleteHabit(String id) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockDatabase.removeWhere((h) => h.id == id);
  }

  // FITUR BARU: Undo / Restore
  Future<void> restoreHabit(HabitModel habit) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockDatabase.add(habit);
  }
}
