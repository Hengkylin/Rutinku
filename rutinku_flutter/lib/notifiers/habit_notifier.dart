import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/habit_model.dart';
import '../repositories/habit_repository.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

final primogemsProvider = StateProvider<int>((ref) => 0);

final habitNotifierProvider =
    AsyncNotifierProvider<HabitNotifier, List<HabitModel>>(() {
      return HabitNotifier();
    });

class HabitNotifier extends AsyncNotifier<List<HabitModel>> {
  late final HabitRepository _repository;

  @override
  Future<List<HabitModel>> build() async {
    _repository = ref.read(habitRepositoryProvider);
    return _repository.fetchHabits();
  }

  Future<void> retryFetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchHabits());
  }

  Future<void> addHabit(
    String title, {
    String? category,
    String? reminderTime,
  }) async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      await _repository.addHabit(
        title,
        category: category,
        reminderTime: reminderTime,
      );
      state = await AsyncValue.guard(() => _repository.fetchHabits());
    } catch (e) {
      state = previousState;
      throw Exception('Gagal menyimpan rutinitas');
    }
  }

  // FITUR BARU: Edit
  Future<void> updateHabit(
    String id,
    String newTitle,
    String newCategory,
    String newReminder,
  ) async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      await _repository.updateHabit(id, newTitle, newCategory, newReminder);
      state = await AsyncValue.guard(() => _repository.fetchHabits());
    } catch (e) {
      state = previousState;
      throw Exception('Gagal memperbarui rutinitas');
    }
  }

  // FITUR BARU: Toggle Check-in & Gamifikasi
  Future<void> toggleCheckIn(String id) async {
    final previousState = state;
    final currentList = state.value;
    if (currentList == null) return;

    final habitIndex = currentList.indexWhere((h) => h.id == id);
    if (habitIndex == -1) return;

    final currentHabit = currentList[habitIndex];
    final updatedHabit = currentHabit.copyWith(
      isCompletedToday: !currentHabit.isCompletedToday,
    );

    // Optimistic UI Update: perbarui state AsyncValue.data secara langsung di awal
    final updatedList = List<HabitModel>.from(currentList);
    updatedList[habitIndex] = updatedHabit;
    state = AsyncValue.data(updatedList);

    try {
      await _repository.toggleCheckIn(id);
      final points = updatedHabit.isCompletedToday ? 15 : -15;
      ref.read(primogemsProvider.notifier).state += points;
    } catch (e) {
      // Jika repository throw error, kembalikan state ke kondisi sebelumnya
      state = previousState;
    }
  }

  // FITUR BARU: Hapus
  Future<void> deleteHabit(String id) async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      await _repository.deleteHabit(id);
      state = await AsyncValue.guard(() => _repository.fetchHabits());
    } catch (e) {
      state = previousState;
      throw Exception('Gagal menghapus rutinitas');
    }
  }

  // FITUR BARU: Undo / Restore
  Future<void> restoreHabit(HabitModel habit) async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      await _repository.restoreHabit(habit);
      state = await AsyncValue.guard(() => _repository.fetchHabits());
    } catch (e) {
      state = previousState;
      throw Exception('Gagal mengembalikan rutinitas');
    }
  }
}
