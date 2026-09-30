import '../models/habit_model.dart';

class HabitRepository {
  // Simulasi database lokal di memori
  final List<HabitModel> _mockDatabase = [];

  // Ditambahkan parameter forceError untuk menguji Error State & Tombol Retry
  Future<List<HabitModel>> fetchHabits({bool forceError = false}) async {
    await Future.delayed(const Duration(seconds: 2)); 
    
    if (forceError) {
      throw Exception('Koneksi terputus. Gagal memuat data rutinitas.');
    }
    
    return _mockDatabase;
  }

  Future<void> addHabit(String title) async {
    await Future.delayed(const Duration(seconds: 2)); 
    final newHabit = HabitModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );
    _mockDatabase.add(newHabit);
  }
}