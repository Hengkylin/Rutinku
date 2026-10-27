import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/notifiers/sync_notifier.dart';
import 'package:rutinku_flutter/repositories/sync_repository.dart';

/// Mock SyncRepository (Mocktail) agar pengujian tidak menembak server
/// Supabase sungguhan. Dipakai juga oleh sync_screen_test.dart.
class MockSyncRepository extends Mock implements SyncRepository {}

void main() {
  group('Tugas Pertemuan Ke-6: 6 Unit Test Wajib Cloud Sync & Vertical Slice', () {
    late MockSyncRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockSyncRepository();
      container = ProviderContainer(
        overrides: [
          syncRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    // -------------------------------------------------------------------------
    // 1. Model Valid
    // -------------------------------------------------------------------------
    test(
      '1. Model Valid: HabitModel.fromMap berhasil membuat objek jika diberi map JSON yang benar',
      () {
        final validMap = {
          'id': 'habit-001',
          'title': 'Olahraga 30 Menit',
          'records': [
            {
              'date': '2026-10-20',
              'status': 'completed',
              'mood': 'semangat',
              'note': 'Lari santai di lapangan',
            },
          ],
          'parentHabitId': null,
          'category': 'Kesehatan',
          'reminderTime': '06:30',
        };

        final habit = HabitModel.fromMap(validMap);

        expect(habit, isA<HabitModel>());
        expect(habit.id, 'habit-001');
        expect(habit.title, 'Olahraga 30 Menit');
        expect(habit.category, 'Kesehatan');
        expect(habit.reminderTime, '06:30');
        expect(habit.records.length, 1);
        expect(habit.records.first.date, '2026-10-20');
        expect(habit.records.first.status, 'completed');
        expect(habit.records.first.mood, 'semangat');
        expect(habit.records.first.note, 'Lari santai di lapangan');
      },
    );

    // -------------------------------------------------------------------------
    // 2. Model Invalid
    // -------------------------------------------------------------------------
    test(
      '2. Model Invalid: HabitModel.fromMap melempar TypeError atau Exception jika diberi map dengan tipe data yang salah',
      () {
        // Kasus A: id berupa angka (int) padahal seharusnya string
        final invalidIdMap = {
          'id': 9999,
          'title': 'Kebiasaan dengan ID Angka',
        };

        expect(
          () => HabitModel.fromMap(invalidIdMap),
          throwsA(anyOf(isA<TypeError>(), isA<Exception>())),
          reason: 'Harus melempar TypeError atau Exception saat id bertipe int',
        );

        // Kasus B: records memiliki struktur salah (bukan List of Map)
        final invalidRecordsMap = {
          'id': 'habit-002',
          'title': 'Kebiasaan dengan Records Rusak',
          'records': [123, 456],
        };

        expect(
          () => HabitModel.fromMap(invalidRecordsMap),
          throwsA(anyOf(isA<TypeError>(), isA<Exception>())),
          reason: 'Harus melempar TypeError atau Exception saat records memiliki struktur salah',
        );
      },
    );

    // -------------------------------------------------------------------------
    // 3. API Sukses
    // -------------------------------------------------------------------------
    test(
      '3. API Sukses: fetchData memanggil repository dan state berisi List<HabitModel> dari cloud',
      () async {
        final cloudHabits = [
          HabitModel(id: '1', title: 'Lari Pagi 20 Menit'),
          HabitModel(id: '2', title: 'Minum Air 2 Liter'),
          HabitModel(id: '3', title: 'Meditasi 10 Menit'),
          HabitModel(id: '4', title: 'Membaca Buku 15 Menit'),
          HabitModel(id: '5', title: 'Tidur Sebelum Jam 23.00'),
        ];
        when(() => mockRepository.fetchHabitsFromCloud())
            .thenAnswer((_) async => cloudHabits);

        await container.read(syncNotifierProvider.notifier).fetchData();

        final state = container.read(syncNotifierProvider);
        expect(state, isA<AsyncData<List<HabitModel>>>());
        expect(state.value, isA<List<HabitModel>>());
        expect(state.value!.length, 5);
        expect(state.value![0].id, '1');
        expect(state.value![0].title, 'Lari Pagi 20 Menit');
        expect(state.value![4].id, '5');
        expect(state.value![4].title, 'Tidur Sebelum Jam 23.00');
        verify(() => mockRepository.fetchHabitsFromCloud()).called(1);
      },
    );

    // -------------------------------------------------------------------------
    // 4. Data Kosong
    // -------------------------------------------------------------------------
    test(
      '4. Data Kosong: fetchData dengan cloud kosong menghasilkan state AsyncData list kosong (panjang 0)',
      () async {
        when(() => mockRepository.fetchHabitsFromCloud())
            .thenAnswer((_) async => <HabitModel>[]);

        await container.read(syncNotifierProvider.notifier).fetchData();

        final state = container.read(syncNotifierProvider);
        expect(state, isA<AsyncData<List<HabitModel>>>());
        expect(state.value, isEmpty);
        expect(state.value!.length, 0);
      },
    );

    // -------------------------------------------------------------------------
    // 5. Request Gagal
    // -------------------------------------------------------------------------
    test(
      '5. Request Gagal: repository melempar Exception (mis. belum login / server error) dan state menjadi AsyncError',
      () async {
        when(() => mockRepository.fetchHabitsFromCloud())
            .thenThrow(Exception('Gagal mengambil data dari cloud'));

        await container.read(syncNotifierProvider.notifier).fetchData();

        final state = container.read(syncNotifierProvider);
        expect(state, isA<AsyncError<List<HabitModel>>>());
        expect(state.error, isA<Exception>());

        // retry() juga harus memanggil ulang repository
        await container.read(syncNotifierProvider.notifier).retry();
        verify(() => mockRepository.fetchHabitsFromCloud()).called(2);
      },
    );

    // -------------------------------------------------------------------------
    // 6. JSON Rusak
    // -------------------------------------------------------------------------
    test(
      '6. JSON Rusak: repository melempar FormatException saat data cloud rusak dan state menjadi AsyncError berisi FormatException',
      () async {
        when(() => mockRepository.fetchHabitsFromCloud())
            .thenThrow(const FormatException('Format data habits bukan list JSON'));

        await container.read(syncNotifierProvider.notifier).fetchData();

        final state = container.read(syncNotifierProvider);
        expect(state, isA<AsyncError<List<HabitModel>>>());
        expect(
          state.error,
          isA<FormatException>(),
          reason: 'FormatException harus diteruskan apa adanya ke state',
        );
      },
    );

    // -------------------------------------------------------------------------
    // Test Tambahan: Backup & Restore via SyncNotifier + Mock Repository
    // -------------------------------------------------------------------------
    test(
      'Bonus Test: backupData memanggil backupHabitsToCloud (true jika sukses) dan restoreData memuat ulang state',
      () async {
        final notifier = container.read(syncNotifierProvider.notifier);

        // Backup sukses
        when(() => mockRepository.backupHabitsToCloud())
            .thenAnswer((_) async => true);
        expect(await notifier.backupData(), isTrue);
        verify(() => mockRepository.backupHabitsToCloud()).called(1);

        // Backup gagal -> exception diteruskan
        when(() => mockRepository.backupHabitsToCloud())
            .thenThrow(Exception('Anda belum login'));
        expect(() => notifier.backupData(), throwsA(isA<Exception>()));

        // Restore -> repository menimpa data lokal, state diperbarui
        when(() => mockRepository.restoreHabitsFromCloud()).thenAnswer(
          (_) async => [
            HabitModel(id: 'local-1', title: 'Belajar Coding'),
            HabitModel(id: 'local-2', title: 'Membaca Dokumentasi'),
          ],
        );
        final restored = await notifier.restoreData();
        expect(restored, 2);
        expect(container.read(syncNotifierProvider).value!.length, 2);
        verify(() => mockRepository.restoreHabitsFromCloud()).called(1);
      },
    );
  });
}
