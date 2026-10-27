import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/notifiers/sync_notifier.dart';
import 'package:rutinku_flutter/screens/sync_screen.dart';

import 'api_sync_test.dart';

void main() {
  late MockSyncRepository mockRepository;

  setUp(() {
    mockRepository = MockSyncRepository();
    when(() => mockRepository.currentUserEmail).thenReturn('user@rutinku.com');
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        syncRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(
        home: SyncScreen(),
      ),
    );
  }

  testWidgets('SyncScreen renders loading state initially when fetching', (tester) async {
    when(() => mockRepository.fetchHabitsFromCloud()).thenAnswer((_) async {
      // Delay to test loading state
      await Future.delayed(const Duration(milliseconds: 500));
      return <HabitModel>[];
    });

    await tester.pumpWidget(buildApp());

    // Initial post frame callback triggers fetchData() -> Loading
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Menyinkronkan data...'), findsOneWidget);

    // Finish async call
    await tester.pumpAndSettle();
  });

  testWidgets('SyncScreen renders Empty State when cloud returns empty list', (tester) async {
    when(() => mockRepository.fetchHabitsFromCloud())
        .thenAnswer((_) async => <HabitModel>[]);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Data di cloud masih kosong'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    // Email akun aktif tampil sebagai indikator koneksi
    expect(find.text('user@rutinku.com'), findsOneWidget);

    // Tombol Backup harus tetap ada & berfungsi saat cloud kosong (tidak dead end)
    expect(find.text('Backup Data Lokal ke Cloud'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload), findsOneWidget);

    when(() => mockRepository.backupHabitsToCloud()).thenAnswer((_) async => true);
    // Setelah backup sukses, data cloud di-refresh otomatis
    when(() => mockRepository.fetchHabitsFromCloud()).thenAnswer(
      (_) async => [HabitModel(id: '1', title: 'Kebiasaan Baru di Cloud')],
    );
    await tester.tap(find.text('Backup Data Lokal ke Cloud'));
    await tester.pumpAndSettle();
    verify(() => mockRepository.backupHabitsToCloud()).called(1);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Kebiasaan Baru di Cloud'), findsOneWidget);
  });

  testWidgets('SyncScreen renders Success State with ListView and Backup button', (tester) async {
    when(() => mockRepository.fetchHabitsFromCloud()).thenAnswer(
      (_) async => [
        HabitModel(id: '1', title: 'Kebiasaan Cloud 1'),
        HabitModel(id: '2', title: 'Kebiasaan Cloud 2'),
      ],
    );
    when(() => mockRepository.backupHabitsToCloud()).thenAnswer((_) async => true);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Kebiasaan Cloud 1'), findsOneWidget);
    expect(find.text('Kebiasaan Cloud 2'), findsOneWidget);
    expect(find.text('Backup Data Lokal ke Cloud'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('user@rutinku.com'), findsOneWidget);

    // Tap backup button
    await tester.tap(find.text('Backup Data Lokal ke Cloud'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    verify(() => mockRepository.backupHabitsToCloud()).called(1);
  });

  testWidgets('SyncScreen renders Error State with warning icon and Coba Lagi button', (tester) async {
    when(() => mockRepository.fetchHabitsFromCloud())
        .thenThrow(Exception('Gagal mengambil data dari cloud'));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
    // Backup tetap tersedia walau state error
    expect(find.text('Backup Data Lokal ke Cloud'), findsOneWidget);
  });
}
