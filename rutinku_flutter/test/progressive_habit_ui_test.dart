import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinku_flutter/notifiers/habit_notifier.dart';
import 'package:rutinku_flutter/repositories/habit_repository.dart';
import 'package:rutinku_flutter/widgets/add_habit_bottom_sheet.dart';
import 'package:rutinku_flutter/widgets/habit_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Merender HabitCard untuk habit pertama dari habitNotifierProvider.
  Widget cardApp() {
    return ProviderScope(
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

      await tester.tap(increment);
      await tester.pumpAndSettle();
      expect(find.text('2 / 2 gelas'), findsOneWidget);
      expect(find.byKey(Key('habit_done_$id')), findsOneWidget);
      expect(increment, findsNothing);
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
  });
}
