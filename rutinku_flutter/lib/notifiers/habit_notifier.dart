import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/habit_model.dart';
import '../repositories/habit_repository.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

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
    String? parentHabitId,
    int targetValue = 1,
    String? unit,
  }) async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      await _repository.addHabit(
        title,
        category: category,
        reminderTime: reminderTime,
        parentHabitId: parentHabitId,
        targetValue: targetValue,
        unit: unit,
      );
      state = await AsyncValue.guard(() => _repository.fetchHabits());
    } catch (e) {
      state = previousState;
      throw Exception('Gagal menyimpan rutinitas');
    }
  }

  // FITUR: Edit
  Future<void> updateHabit(
    String id,
    String newTitle,
    String newCategory,
    String newReminder, {
    String? parentHabitId,
    int targetValue = 1,
    String? unit,
  }) async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      await _repository.updateHabit(
        id,
        newTitle,
        newCategory,
        newReminder,
        parentHabitId: parentHabitId,
        targetValue: targetValue,
        unit: unit,
      );
      state = await AsyncValue.guard(() => _repository.fetchHabits());
    } catch (e) {
      state = previousState;
      throw Exception('Gagal memperbarui rutinitas');
    }
  }

  // FITUR BARU: Toggle Check-in
  Future<void> toggleCheckIn(String id, DateTime date) async {
    final previousState = state;
    final currentList = state.value;
    if (currentList == null) return;

    final habitIndex = currentList.indexWhere((h) => h.id == id);
    if (habitIndex == -1) return;

    final currentHabit = currentList[habitIndex];
    // Logika toggle (copyWith, aturan target progresif) ada di HabitModel,
    // dipakai sama persis oleh repository saat menyimpan.
    final updatedHabit = currentHabit.toggleCheckIn(date);
    if (identical(updatedHabit, currentHabit)) return; // ditolak: target belum tercapai

    // Optimistic UI Update: perbarui state AsyncValue.data secara langsung di awal
    final updatedList = List<HabitModel>.from(currentList);
    updatedList[habitIndex] = updatedHabit;
    state = AsyncValue.data(updatedList);

    try {
      await _repository.toggleCheckIn(id, date);
    } catch (e) {
      // Jika repository throw error, kembalikan state ke kondisi sebelumnya
      state = previousState;
    }
  }

  // FITUR: Progressive Habit Tracking (+1 progres angka harian)
  Future<void> incrementHabitProgress(String id, DateTime date) async {
    final previousState = state;
    final currentList = state.value;
    if (currentList == null) return;

    final habitIndex = currentList.indexWhere((h) => h.id == id);
    if (habitIndex == -1) return;

    // Optimistic UI Update: logika +1 & auto-complete ada di HabitModel,
    // dipakai sama persis oleh repository saat menyimpan.
    final updatedList = List<HabitModel>.from(currentList);
    updatedList[habitIndex] = currentList[habitIndex].incrementProgress(date);
    state = AsyncValue.data(updatedList);

    try {
      await _repository.incrementHabitProgress(id, date);
    } catch (e) {
      state = previousState;
      throw Exception('Gagal memperbarui progres rutinitas');
    }
  }

  // FITUR: Update Detail Catatan / Status Jurnal (Mood & Recovery)
  Future<void> updateHabitRecord(
    String id,
    DateTime date, {
    String? status,
    String? mood,
    String? note,
    String? momentImagePath,
  }) async {
    final previousState = state;
    final currentList = state.value;
    if (currentList == null) return;

    final habitIndex = currentList.indexWhere((h) => h.id == id);
    if (habitIndex == -1) return;

    final currentHabit = currentList[habitIndex];
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final updatedRecords = List<HabitRecord>.from(currentHabit.records);
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

    final updatedHabit = currentHabit.copyWith(records: updatedRecords);

    // Optimistic UI Update: perbarui list secara langsung di awal
    final updatedList = List<HabitModel>.from(currentList);
    updatedList[habitIndex] = updatedHabit;
    state = AsyncValue.data(updatedList);

    try {
      await _repository.updateRecordDetails(
        id,
        date,
        status: status,
        mood: mood,
        note: note,
        momentImagePath: momentImagePath,
      );
    } catch (e) {
      // Jika repository gagal, rollback state
      state = previousState;
      throw Exception('Gagal memperbarui catatan refleksi');
    }
  }

  // FITUR: Abadikan Momen (Visual Habit Journal)
  Future<void> saveMomentImage(
    String id,
    String imagePath, [
    DateTime? date,
  ]) async {
    final targetDate = date ?? DateTime.now();
    final previousState = state;
    final currentList = state.value;
    if (currentList == null) return;

    final habitIndex = currentList.indexWhere((h) => h.id == id);
    if (habitIndex == -1) return;

    final currentHabit = currentList[habitIndex];
    final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
    final updatedRecords = List<HabitRecord>.from(currentHabit.records);
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

    final updatedHabit = currentHabit.copyWith(records: updatedRecords);

    // Optimistic UI Update: perbarui list secara langsung di awal
    final updatedList = List<HabitModel>.from(currentList);
    updatedList[habitIndex] = updatedHabit;
    state = AsyncValue.data(updatedList);

    try {
      await _repository.saveMomentImage(id, targetDate, imagePath);
    } catch (e) {
      state = previousState;
      throw Exception('Gagal menyimpan foto momen');
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
