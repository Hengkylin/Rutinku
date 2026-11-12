import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/notifiers/habit_notifier.dart';
import 'package:rutinku_flutter/repositories/habit_repository.dart';
import 'package:rutinku_flutter/widgets/add_habit_bottom_sheet.dart';
import 'package:rutinku_flutter/widgets/edit_habit_bottom_sheet.dart';
import 'package:rutinku_flutter/widgets/habit_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Menutup dialog "Mantap!" yang muncul setelah tombol [+] ditekan.
  Future<void> closeProgressDialog(WidgetTester tester) async {
    expect(find.text('Mantap!'), findsOneWidget);
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
  }

  /// Merender HabitCard untuk habit pertama dari habitNotifierProvider.
  Widget cardApp({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              final habits = ref.watch(habitNotifierProvider).value ?? [];
              if (habits.isEmpty) return const SizedBox();
              return HabitCard(
                habit: habits.first,
                onToggle: () {},
                onLongPress: () {},
              );
            },
          ),
        ),
      ),
    );
  }

  group('HabitCard - Progressive Habit', () {
    testWidgets('tombol [+] menambah progres lalu berganti centang hijau',
        (tester) async {
      await tester.runAsync(
        () => HabitRepository()
            .addHabit('Minum Air', targetValue: 2, unit: 'gelas'),
      );
      final id = (await tester.runAsync(() => HabitRepository().fetchHabits()))!
          .first
          .id;

      await tester.pumpWidget(cardApp());
      await tester.pumpAndSettle();

      final increment = find.byKey(Key('habit_increment_$id'));
      expect(find.text('0 / 2 gelas'), findsOneWidget);
      expect(increment, findsOneWidget);
      expect(find.byKey(Key('habit_done_$id')), findsNothing);

      await tester.tap(increment);
      await tester.pumpAndSettle();
      expect(find.text('1 / 2 gelas'), findsOneWidget);
      await closeProgressDialog(tester);

      await tester.tap(increment);
      await tester.pumpAndSettle();
      expect(find.text('2 / 2 gelas'), findsOneWidget);
      await closeProgressDialog(tester);

      expect(find.byKey(Key('habit_done_$id')), findsOneWidget);
      expect(increment, findsNothing);
    });

    testWidgets('tombol [+] menampilkan dialog sukses dengan nama rutinitas',
        (tester) async {
      await tester.runAsync(
        () => HabitRepository()
            .addHabit('Minum Air', targetValue: 3, unit: 'gelas'),
      );
      final id = (await tester.runAsync(() => HabitRepository().fetchHabits()))!
          .first
          .id;

      await tester.pumpWidget(cardApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('habit_increment_$id')));
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.byIcon(Icons.stars_rounded)),
        findsOneWidget,
      );
      expect(find.text('Mantap!'), findsOneWidget);
      expect(
        find.text(
          'Progres rutinitas "Minum Air" berhasil ditambahkan. '
          'Teruskan konsistensimu!',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('1 / 3 gelas'), findsOneWidget);
    });

    testWidgets('gagal menyimpan progres: SnackBar merah, tanpa dialog',
        (tester) async {
      await tester.pumpWidget(
        cardApp(
          overrides: [
            habitRepositoryProvider.overrideWithValue(
              _FailingIncrementRepository(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('habit_increment_h1')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Gagal memperbarui progres rutinitas'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red.shade600);
      expect(find.text('0 / 3 gelas'), findsOneWidget); // state di-rollback
    });

    testWidgets('habit biasa (target 1) tetap memakai tombol check-in',
        (tester) async {
      await tester.runAsync(() => HabitRepository().addHabit('Olahraga'));
      final id = (await tester.runAsync(() => HabitRepository().fetchHabits()))!
          .first
          .id;

      await tester.pumpWidget(cardApp());
      await tester.pumpAndSettle();

      expect(find.byKey(Key('habit_increment_$id')), findsNothing);
      expect(find.byKey(Key('habit_progress_$id')), findsNothing);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('AddHabitBottomSheet - Target Harian & Satuan', () {
    testWidgets('nilai target & satuan dikirim ke addHabit', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AddHabitBottomSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Minum Air');
      await tester.enterText(find.byKey(const Key('habit_target_field')), '8');
      await tester.enterText(find.byKey(const Key('habit_unit_field')), ' gelas ');
      await tester.ensureVisible(find.text('Simpan'));
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      final habits =
          (await tester.runAsync(() => HabitRepository().fetchHabits()))!;
      expect(habits.single.targetValue, 8);
      expect(habits.single.unit, 'gelas');
    });

    testWidgets('target 0 ditolak validasi', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AddHabitBottomSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Minum Air');
      await tester.enterText(find.byKey(const Key('habit_target_field')), '0');
      await tester.ensureVisible(find.text('Simpan'));
      await tester.tap(find.text('Simpan'));
      await tester.pump();

      expect(find.text('Target minimal 1'), findsOneWidget);
    });

    testWidgets(
        'angka di kolom Satuan (target tetap 1) ditolak dan tidak tersimpan',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AddHabitBottomSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Petunjuk kapan tombol [+] muncul selalu terlihat di form.
      expect(find.textContaining('tombol [+]'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Minum Air');
      await tester.enterText(find.byKey(const Key('habit_unit_field')), '8');
      await tester.ensureVisible(find.text('Simpan'));
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.textContaining('diisi di Target harian'), findsOneWidget);
      final habits =
          (await tester.runAsync(() => HabitRepository().fetchHabits()))!;
      expect(habits, isEmpty);
    });
  });

  group('EditHabitBottomSheet - memperbaiki target & satuan', () {
    testWidgets('target 8 + satuan gelas tersimpan sehingga kartu memakai [+]',
        (tester) async {
      // Kondisi dari laporan: target 1, satuan "8".
      await tester.runAsync(
        () => HabitRepository().addHabit('Minum Air', unit: '8'),
      );
      final habit =
          (await tester.runAsync(() => HabitRepository().fetchHabits()))!
              .single;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: EditHabitBottomSheet(habit: habit),
                      ),
                    ),
                  ),
                  child: const Text('BUKA'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('BUKA'));
      await tester.pumpAndSettle();

      final targetField = find.byKey(const Key('habit_target_field'));
      final unitField = find.byKey(const Key('habit_unit_field'));
      final save = find.text('Simpan perubahan');

      // Menyimpan apa adanya ditolak karena satuan berisi angka.
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.textContaining('diisi di Target harian'), findsOneWidget);

      await tester.enterText(targetField, '8');
      await tester.enterText(unitField, 'gelas');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final saved =
          (await tester.runAsync(() => HabitRepository().fetchHabits()))!
              .single;
      expect(saved.targetValue, 8);
      expect(saved.unit, 'gelas');
      expect(find.text('BUKA'), findsOneWidget); // sheet tertutup
    });
  });
}

/// Repository yang selalu gagal menyimpan progres, untuk menguji jalur error.
class _FailingIncrementRepository extends HabitRepository {
  @override
  Future<List<HabitModel>> fetchHabits({bool forceError = false}) async => [
        HabitModel(id: 'h1', title: 'Minum Air', targetValue: 3, unit: 'gelas'),
      ];

  @override
  Future<void> incrementHabitProgress(String id, DateTime date) async {
    throw Exception('penyimpanan penuh');
  }
}
