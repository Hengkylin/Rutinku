import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_model.dart';
import '../repositories/sync_repository.dart';
import '../services/app_logger.dart';
import 'habit_notifier.dart';

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository();
});

final syncNotifierProvider =
    NotifierProvider<SyncNotifier, AsyncValue<List<HabitModel>>>(() {
  return SyncNotifier();
});

class SyncNotifier extends Notifier<AsyncValue<List<HabitModel>>> {
  static final _log = AppLogger.get('sync');

  late final SyncRepository _repository;

  @override
  AsyncValue<List<HabitModel>> build() {
    _repository = ref.watch(syncRepositoryProvider);
    return const AsyncData<List<HabitModel>>([]);
  }

  /// Mengubah state menjadi AsyncLoading, lalu memanggil fetchHabitsFromCloud
  /// (hanya pratinjau data cloud, tidak menimpa data lokal).
  Future<void> fetchData() async {
    state = const AsyncLoading();
    try {
      final habits = await _repository.fetchHabitsFromCloud();
      _log.info('Fetch cloud: ${habits.length} rutinitas');
      state = AsyncData<List<HabitModel>>(habits);
    } catch (e, stackTrace) {
      _log.severe('Fetch cloud gagal', e, stackTrace);
      state = AsyncError(e, stackTrace);
    }
  }

  /// Memanggil ulang fetchData() untuk retry
  Future<void> retry() async {
    await fetchData();
  }

  /// Backup data lokal (SharedPreferences) ke Supabase.
  Future<bool> backupData() async {
    try {
      final success = await _repository.backupHabitsToCloud();
      _log.info('Backup ke cloud selesai (hasil: $success)');
      return success;
    } catch (e, s) {
      _log.severe('Backup ke cloud gagal', e, s);
      rethrow;
    }
  }

  /// Restore: menimpa data lokal dengan data cloud lalu memicu pembaruan
  /// state kebiasaan agar UI Dashboard/Kalender ikut ter-refresh.
  Future<int> restoreData() async {
    try {
      final habits = await _repository.restoreHabitsFromCloud();
      _log.info('Restore dari cloud: ${habits.length} rutinitas');
      ref.invalidate(habitNotifierProvider);
      state = AsyncData<List<HabitModel>>(habits);
      return habits.length;
    } catch (e, s) {
      _log.severe('Restore dari cloud gagal', e, s);
      rethrow;
    }
  }
}
