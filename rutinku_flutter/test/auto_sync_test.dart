import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/notifiers/auto_sync_notifier.dart';
import 'package:rutinku_flutter/notifiers/habit_notifier.dart';
import 'package:rutinku_flutter/notifiers/sync_notifier.dart';
import 'package:rutinku_flutter/notifiers/today_notifier.dart';
import 'package:rutinku_flutter/repositories/habit_repository.dart';
import 'package:rutinku_flutter/screens/sync_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_sync_test.dart';

/// HabitNotifier palsu: membaca/menulis SharedPreferences langsung, tanpa
/// HabitRepository (tidak menyentuh plugin notifikasi).
class FakeHabitNotifier extends HabitNotifier {
  @override
  Future<List<HabitModel>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return decode(prefs.getString(HabitRepository.storageKey) ?? '[]');
  }

  /// Meniru perubahan lokal (tambah/centang/hapus): simpan + perbarui state.
  Future<void> save(List<HabitModel> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(HabitRepository.storageKey, encode(habits));
    state = AsyncData(habits);
  }
}

/// AutoSyncNotifier dengan state tetap, untuk tes tampilan kartu.
class FixedAutoSyncNotifier extends AutoSyncNotifier {
  FixedAutoSyncNotifier(this.fixed);
  final AutoSyncState fixed;
  bool? enabledSetTo;

  @override
  AutoSyncState build() => fixed;

  @override
  Future<void> setEnabled(bool enabled) async {
    enabledSetTo = enabled;
    state = state.copyWith(
      enabled: enabled,
      status: enabled ? AutoSyncStatus.synced : AutoSyncStatus.off,
    );
  }
}

HabitModel habit(String id) => HabitModel(id: id, title: 'Rutinitas $id');

String encode(List<HabitModel> habits) =>
    jsonEncode(habits.map((h) => h.toMap()).toList());

List<HabitModel> decode(String json) => (jsonDecode(json) as List)
    .map((e) => HabitModel.fromMap(Map<String, dynamic>.from(e as Map)))
    .toList();

/// Memberi waktu untuk microtask, Future dan timer pendek di tes.
Future<void> wait([int ms = 20]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixedNow = DateTime(2026, 11, 26, 9, 30);
  late MockSyncRepository repo;

  setUp(() {
    repo = MockSyncRepository();
    when(() => repo.isLoggedIn).thenReturn(true);
    when(() => repo.currentUserEmail).thenReturn('user@rutinku.com');
    when(() => repo.fetchHabitsFromCloud()).thenAnswer((_) async => []);
    when(() => repo.backupHabitsToCloud()).thenAnswer((_) async => true);
  });

  Future<void> setLocal(List<HabitModel> habits,
      {Map<String, Object> extra = const {}}) async {
    SharedPreferences.setMockInitialValues({
      HabitRepository.storageKey: encode(habits),
      ...extra,
    });
  }

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      syncRepositoryProvider.overrideWithValue(repo),
      habitNotifierProvider.overrideWith(FakeHabitNotifier.new),
      clockProvider.overrideWithValue(() => fixedNow),
      autoSyncDebounceProvider
          .overrideWithValue(const Duration(milliseconds: 30)),
      autoSyncRetryProvider.overrideWithValue(const Duration(milliseconds: 60)),
    ]);
    addTearDown(container.dispose);
    // autoDispose: tetap hidup selama didengarkan.
    container.listen(autoSyncProvider, (_, _) {});
    return container;
  }

  AutoSyncStatus statusOf(ProviderContainer c) =>
      c.read(autoSyncProvider).status;

  group('Sinkron otomatis - cek awal', () {
    test('belum login -> notLoggedIn, cloud tidak dihubungi', () async {
      await setLocal([habit('a')]);
      when(() => repo.isLoggedIn).thenReturn(false);
      final c = makeContainer();
      await wait();

      expect(statusOf(c), AutoSyncStatus.notLoggedIn);
      verifyNever(() => repo.fetchHabitsFromCloud());
      verifyNever(() => repo.backupHabitsToCloud());
    });

    test('sakelar dimatikan -> off, cloud tidak dihubungi', () async {
      await setLocal([habit('a')],
          extra: {AutoSyncNotifier.enabledKey: false});
      final c = makeContainer();
      await wait();

      expect(statusOf(c), AutoSyncStatus.off);
      expect(c.read(autoSyncProvider).enabled, isFalse);
      verifyNever(() => repo.fetchHabitsFromCloud());
    });

    test('HP kosong & cloud berisi -> restore otomatis tanpa backup',
        () async {
      await setLocal([]);
      final cloud = [habit('x'), habit('y')];
      when(() => repo.fetchHabitsFromCloud()).thenAnswer((_) async => cloud);
      when(() => repo.restoreHabitsFromCloud()).thenAnswer((_) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(HabitRepository.storageKey, encode(cloud));
        return cloud;
      });
      final c = makeContainer();
      await wait(100);

      verify(() => repo.restoreHabitsFromCloud()).called(1);
      verifyNever(() => repo.backupHabitsToCloud());
      expect(statusOf(c), AutoSyncStatus.synced);
      final habits = await c.read(habitNotifierProvider.future);
      expect(habits.map((h) => h.id), ['x', 'y']);
    });

    test('HP berisi & cloud kosong -> backup + catat waktu sinkron',
        () async {
      await setLocal([habit('a')]);
      final c = makeContainer();
      await wait();

      verify(() => repo.backupHabitsToCloud()).called(1);
      expect(statusOf(c), AutoSyncStatus.synced);
      expect(c.read(autoSyncProvider).lastSyncedAt, fixedNow);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AutoSyncNotifier.lastSyncKey),
          fixedNow.toIso8601String());
      expect(prefs.getBool(AutoSyncNotifier.pendingKey), isFalse);
    });

    test('HP & cloud sama-sama kosong -> synced tanpa upload', () async {
      await setLocal([]);
      final c = makeContainer();
      await wait();

      expect(statusOf(c), AutoSyncStatus.synced);
      verifyNever(() => repo.backupHabitsToCloud());
    });

    test('data HP & cloud sama -> synced tanpa upload', () async {
      await setLocal([habit('a')]);
      when(() => repo.fetchHabitsFromCloud())
          .thenAnswer((_) async => [habit('a')]);
      final c = makeContainer();
      await wait();

      expect(statusOf(c), AutoSyncStatus.synced);
      verifyNever(() => repo.backupHabitsToCloud());
      verifyNever(() => repo.restoreHabitsFromCloud());
    });

    test('data berbeda & HP belum pernah sinkron -> conflict, cloud aman',
        () async {
      await setLocal([habit('a')]);
      when(() => repo.fetchHabitsFromCloud())
          .thenAnswer((_) async => [habit('b')]);
      final c = makeContainer();
      await wait();

      expect(statusOf(c), AutoSyncStatus.conflict);
      verifyNever(() => repo.backupHabitsToCloud());
      verifyNever(() => repo.restoreHabitsFromCloud());
    });

    test('data berbeda & HP pernah sinkron -> data HP di-backup', () async {
      await setLocal([habit('a')], extra: {
        AutoSyncNotifier.lastSyncKey: DateTime(2026, 11, 20).toIso8601String(),
      });
      when(() => repo.fetchHabitsFromCloud())
          .thenAnswer((_) async => [habit('b')]);
      final c = makeContainer();
      await wait();

      verify(() => repo.backupHabitsToCloud()).called(1);
      expect(statusOf(c), AutoSyncStatus.synced);
    });

    test('cloud tidak bisa dihubungi -> error', () async {
      await setLocal([habit('a')]);
      when(() => repo.fetchHabitsFromCloud())
          .thenThrow(Exception('Failed host lookup'));
      final c = makeContainer();
      await wait();

      expect(statusOf(c), AutoSyncStatus.error);
    });
  });

  group('Sinkron otomatis - perubahan lokal', () {
    test('perubahan -> pending, lalu backup setelah jeda', () async {
      await setLocal([habit('a')]);
      when(() => repo.fetchHabitsFromCloud())
          .thenAnswer((_) async => [habit('a')]);
      final c = makeContainer();
      await wait();
      expect(statusOf(c), AutoSyncStatus.synced);

      await (c.read(habitNotifierProvider.notifier) as FakeHabitNotifier)
          .save([habit('a'), habit('b')]);
      expect(statusOf(c), AutoSyncStatus.pending);
      verifyNever(() => repo.backupHabitsToCloud());

      await wait(100);
      verify(() => repo.backupHabitsToCloud()).called(1);
      expect(statusOf(c), AutoSyncStatus.synced);
    });

    test('beberapa perubahan beruntun -> hanya 1 upload', () async {
      await setLocal([habit('a')]);
      when(() => repo.fetchHabitsFromCloud())
          .thenAnswer((_) async => [habit('a')]);
      final c = makeContainer();
      await wait();

      final notifier =
          c.read(habitNotifierProvider.notifier) as FakeHabitNotifier;
      await notifier.save([habit('a'), habit('b')]);
      await notifier.save([habit('a'), habit('b'), habit('c')]);
      await notifier.save([habit('c')]);

      await wait(100);
      verify(() => repo.backupHabitsToCloud()).called(1);
      expect(statusOf(c), AutoSyncStatus.synced);
    });

    test('backup gagal -> error, dicoba lagi otomatis sampai berhasil',
        () async {
      await setLocal([habit('a')]);
      var calls = 0;
      when(() => repo.backupHabitsToCloud()).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('offline');
        return true;
      });
      final c = makeContainer();
      await wait();
      expect(statusOf(c), AutoSyncStatus.error);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AutoSyncNotifier.pendingKey), isTrue);

      await wait(120);
      expect(calls, 2);
      expect(statusOf(c), AutoSyncStatus.synced);
      expect(prefs.getBool(AutoSyncNotifier.pendingKey), isFalse);
    });

    test('saat conflict, perubahan lokal tidak meng-upload', () async {
      await setLocal([habit('a')]);
      when(() => repo.fetchHabitsFromCloud())
          .thenAnswer((_) async => [habit('b')]);
      final c = makeContainer();
      await wait();
      expect(statusOf(c), AutoSyncStatus.conflict);

      await (c.read(habitNotifierProvider.notifier) as FakeHabitNotifier)
          .save([habit('a'), habit('c')]);
      await wait(100);

      expect(statusOf(c), AutoSyncStatus.conflict);
      verifyNever(() => repo.backupHabitsToCloud());
    });
  });

  group('Sinkron otomatis - API untuk UI', () {
    test('setEnabled(false) -> off, tersimpan, perubahan tidak di-upload',
        () async {
      await setLocal([habit('a')]);
      when(() => repo.fetchHabitsFromCloud())
          .thenAnswer((_) async => [habit('a')]);
      final c = makeContainer();
      await wait();

      await c.read(autoSyncProvider.notifier).setEnabled(false);
      expect(statusOf(c), AutoSyncStatus.off);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AutoSyncNotifier.enabledKey), isFalse);

      await (c.read(habitNotifierProvider.notifier) as FakeHabitNotifier)
          .save([habit('a'), habit('b')]);
      await wait(100);
      verifyNever(() => repo.backupHabitsToCloud());
    });

    test('setEnabled(true) menjalankan cek awal lagi', () async {
      await setLocal([habit('a')],
          extra: {AutoSyncNotifier.enabledKey: false});
      final c = makeContainer();
      await wait();
      expect(statusOf(c), AutoSyncStatus.off);

      await c.read(autoSyncProvider.notifier).setEnabled(true);
      await wait();
      expect(c.read(autoSyncProvider).enabled, isTrue);
      expect(statusOf(c), AutoSyncStatus.synced);
      verify(() => repo.backupHabitsToCloud()).called(1);
    });

    test('recordManualSync menyelesaikan conflict', () async {
      await setLocal([habit('a')]);
      when(() => repo.fetchHabitsFromCloud())
          .thenAnswer((_) async => [habit('b')]);
      final c = makeContainer();
      await wait();
      expect(statusOf(c), AutoSyncStatus.conflict);

      await c.read(autoSyncProvider.notifier).recordManualSync();
      expect(statusOf(c), AutoSyncStatus.synced);
      expect(c.read(autoSyncProvider).lastSyncedAt, fixedNow);
    });

    test('syncNow tidak meng-upload saat conflict', () async {
      await setLocal([habit('a')]);
      when(() => repo.fetchHabitsFromCloud())
          .thenAnswer((_) async => [habit('b')]);
      final c = makeContainer();
      await wait();

      await c.read(autoSyncProvider.notifier).syncNow();
      verifyNever(() => repo.backupHabitsToCloud());
    });

    test('syncNow tidak upload ulang data yang sudah sama', () async {
      await setLocal([habit('a')]);
      final c = makeContainer();
      await wait();
      verify(() => repo.backupHabitsToCloud()).called(1);

      await c.read(autoSyncProvider.notifier).syncNow();
      verifyNever(() => repo.backupHabitsToCloud());
      expect(statusOf(c), AutoSyncStatus.synced);
    });
  });

  group('Muat ulang setelah restore (invalidate)', () {
    // Regresi: restore otomatis memanggil ref.invalidate(habitNotifierProvider)
    // saat Dashboard sudah tampil. Riverpod memakai ulang instance notifier,
    // sehingga field `late final` yang diisi di build() melempar
    // LateInitializationError ("has already been initialized").
    test('HabitNotifier asli bisa di-invalidate berulang kali', () async {
      await setLocal([habit('a')]);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.listen(habitNotifierProvider, (_, _) {});

      expect((await c.read(habitNotifierProvider.future)).length, 1);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          HabitRepository.storageKey, encode([habit('x'), habit('y')]));
      c.invalidate(habitNotifierProvider);
      final reloaded = await c.read(habitNotifierProvider.future);

      expect(reloaded.map((h) => h.id), ['x', 'y']);
      expect(c.read(habitNotifierProvider).hasError, isFalse);

      c.invalidate(habitNotifierProvider);
      expect((await c.read(habitNotifierProvider.future)).length, 2);
    });

    test('SyncNotifier asli bisa dibangun ulang', () async {
      final c = ProviderContainer(overrides: [
        syncRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(c.dispose);
      c.listen(syncNotifierProvider, (_, _) {});
      c.read(syncNotifierProvider);

      c.invalidate(syncNotifierProvider);
      c.read(syncNotifierProvider);
      await c.read(syncNotifierProvider.notifier).fetchData();

      expect(c.read(syncNotifierProvider).hasError, isFalse);
    });
  });

  group('Kartu Sinkron otomatis di SyncScreen', () {
    Future<FixedAutoSyncNotifier> pumpCard(
        WidgetTester tester, AutoSyncState state) async {
      final fake = FixedAutoSyncNotifier(state);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          syncRepositoryProvider.overrideWithValue(repo),
          autoSyncProvider.overrideWith(() => fake),
        ],
        child: const MaterialApp(home: SyncScreen()),
      ));
      await tester.pump();
      return fake;
    }

    testWidgets('menampilkan waktu sinkron terakhir', (tester) async {
      await pumpCard(
        tester,
        AutoSyncState(status: AutoSyncStatus.synced, lastSyncedAt: fixedNow),
      );
      expect(find.byKey(const Key('auto_sync_card')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('auto_sync_status_text')))
            .data,
        contains('26/11 09:30'),
      );
    });

    testWidgets('conflict menampilkan pesan pilihan', (tester) async {
      await pumpCard(
          tester, const AutoSyncState(status: AutoSyncStatus.conflict));
      expect(find.byKey(const Key('auto_sync_conflict_text')), findsOneWidget);
      expect(find.text('Perlu dipilih: data HP dan cloud berbeda'),
          findsOneWidget);
    });

    testWidgets('sakelar mematikan sinkron otomatis', (tester) async {
      final fake = await pumpCard(
          tester, const AutoSyncState(status: AutoSyncStatus.synced));
      await tester.tap(find.byKey(const Key('auto_sync_switch')));
      await tester.pump();

      expect(fake.enabledSetTo, isFalse);
      expect(find.text('Mati · gunakan Backup / Restore manual'),
          findsOneWidget);
    });
  });
}
