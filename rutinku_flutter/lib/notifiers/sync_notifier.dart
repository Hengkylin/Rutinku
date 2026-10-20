import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/habit_model.dart';
import '../repositories/sync_repository.dart';

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository();
});

final syncHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(() => client.close());
  return client;
});

final syncNotifierProvider =
    NotifierProvider<SyncNotifier, AsyncValue<List<HabitModel>>>(() {
  return SyncNotifier();
});

class SyncNotifier extends Notifier<AsyncValue<List<HabitModel>>> {
  late final SyncRepository _repository;
  late final http.Client _client;

  @override
  AsyncValue<List<HabitModel>> build() {
    _repository = ref.watch(syncRepositoryProvider);
    _client = ref.watch(syncHttpClientProvider);
    return const AsyncData<List<HabitModel>>([]);
  }

  /// Mengubah state menjadi AsyncLoading, lalu memanggil fetchHabitsFromCloud
  Future<void> fetchData() async {
    state = const AsyncLoading();
    try {
      final habits = await _repository.fetchHabitsFromCloud(_client);
      if (habits.isEmpty) {
        state = const AsyncData<List<HabitModel>>([]);
      } else {
        state = AsyncData<List<HabitModel>>(habits);
      }
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  /// Memanggil ulang fetchData() untuk retry
  Future<void> retry() async {
    await fetchData();
  }

  /// Memanggil POST backup data ke cloud
  Future<bool> backupData(List<HabitModel> habits) async {
    return _repository.backupHabitsToCloud(_client, habits);
  }
}
