import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/habit_model.dart';
import '../repositories/habit_repository.dart';
import '../services/app_logger.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

final habitNotifierProvider =
    AsyncNotifierProvider<HabitNotifier, List<HabitModel>>(() {
      return HabitNotifier();
    });

class HabitNotifier extends AsyncNotifier<List<HabitModel>> {
  static final _log = AppLogger.get('habit');

  late final HabitRepository _repository;

  /// Membaca data dari repository; error asli dicatat ke log sebelum
  /// diteruskan (UI menampilkan state error).
  Future<List<HabitModel>> _fetchHabits() async {
    try {
      return await _repository.fetchHabits();
    } catch (e, s) {
      _log.severe('Gagal memuat rutinitas', e, s);
      rethrow;
    }
  }

  /// Mengembalikan state sebelumnya, mencatat error asli ke log, lalu
  /// melempar [message] yang ramah pengguna.
  Never _fail(
    AsyncValue<List<HabitModel>> previousState,
    String message,
    Object error,
    StackTrace stackTrace,
  ) {
    state = previousState;
    _log.severe(message, error, stackTrace);
    throw Exception(message);
  }

  @override
  Future<List<HabitModel>> build() async {
    _repository = ref.read(habitRepositoryProvider);
    return _fetchHabits();
  }

  Future<void> retryFetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchHabits());
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
      state = await AsyncValue.guard(() => _fetchHabits());
    } catch (e, s) {
      _fail(previousState, 'Gagal menyimpan rutinitas', e, s);
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
      state = await AsyncValue.guard(() => _fetchHabits());
    } catch (e, s) {
      _fail(previousState, 'Gagal memperbarui rutinitas', e, s);
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
    } catch (e, s) {
      // Jika repository throw error, kembalikan state ke kondisi sebelumnya
      state = previousState;
      _log.severe('Gagal mengubah check-in', e, s);
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
    } catch (e, s) {
      _fail(previousState, 'Gagal memperbarui progres rutinitas', e, s);
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
    } catch (e, s) {
      _fail(previousState, 'Gagal memperbarui catatan refleksi', e, s);
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
    } catch (e, s) {
      _fail(previousState, 'Gagal menyimpan foto momen', e, s);
    }
  }

  // FITUR BARU: Hapus
  Future<void> deleteHabit(String id) async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      await _repository.deleteHabit(id);
      state = await AsyncValue.guard(() => _fetchHabits());
    } catch (e, s) {
      _fail(previousState, 'Gagal menghapus rutinitas', e, s);
    }
  }

  // FITUR BARU: Undo / Restore
  Future<void> restoreHabit(HabitModel habit) async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      await _repository.restoreHabit(habit);
      state = await AsyncValue.guard(() => _fetchHabits());
    } catch (e, s) {
      _fail(previousState, 'Gagal mengembalikan rutinitas', e, s);
    }
  }
}
