import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_model.dart';
import '../repositories/habit_repository.dart';

// Provider untuk menginjeksi Repository
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

// Provider utama yang akan dipanggil oleh UI
final habitNotifierProvider = AsyncNotifierProvider<HabitNotifier, List<HabitModel>>(() {
  return HabitNotifier();
});

class HabitNotifier extends AsyncNotifier<List<HabitModel>> {
  late final HabitRepository _repository;

  @override
  Future<List<HabitModel>> build() async {
    _repository = ref.read(habitRepositoryProvider);
    // Secara default, Riverpod akan masuk ke kondisi "Initial Loading" saat fungsi ini berjalan
    return _repository.fetchHabits(forceError: false); // Ubah ke true untuk melihat Error State
  }

  // Dipanggil oleh "Tombol Retry" di UI jika terjadi error
  Future<void> retryFetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchHabits());
  }

  // Dipanggil saat mensubmit form
  Future<void> addHabit(String title) async {
    final previousState = state;
    state = const AsyncValue.loading(); // Memicu UI masuk ke kondisi Submit Loading
    
    try {
      await _repository.addHabit(title);
      // Jika sukses, muat ulang data terbaru (bisa memicu Empty State atau Data Loaded)
      state = await AsyncValue.guard(() => _repository.fetchHabits());
    } catch (e, st) {
      state = previousState;
      throw Exception('Gagal menyimpan rutinitas');
    }
  }
}