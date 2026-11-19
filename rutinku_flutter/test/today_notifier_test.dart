import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/notifiers/today_notifier.dart';
import 'package:rutinku_flutter/widgets/habit_card.dart';

/// Issue #4: streak & status "hari ini" harus ikut berganti saat lewat
/// pukul 00:00 atau saat aplikasi dibuka lagi keesokan harinya, tanpa
/// menunggu data rutinitas berubah.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('TodayNotifier', () {
    test('refresh() hanya mengubah state saat hari benar-benar berganti', () {
      var now = DateTime(2026, 11, 11, 23, 59, 30);
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(() => now)],
      );
      addTearDown(container.dispose);

      final changes = <DateTime>[];
      container.listen<DateTime>(todayProvider, (_, next) => changes.add(next));
      expect(container.read(todayProvider), DateTime(2026, 11, 11));

      now = DateTime(2026, 11, 11, 23, 59, 59);
      container.read(todayProvider.notifier).refresh();
      expect(changes, isEmpty);

      now = DateTime(2026, 11, 12, 0, 0, 5);
      container.read(todayProvider.notifier).refresh();
      expect(container.read(todayProvider), DateTime(2026, 11, 12));
      expect(changes, [DateTime(2026, 11, 12)]);
    });

    testWidgets('berganti otomatis lewat pukul 00:00 tanpa interaksi',
        (tester) async {
      var now = DateTime(2026, 11, 11, 23, 59, 0);
      await tester.pumpWidget(_todayText(() => now));
      expect(find.text('2026-11-11'), findsOneWidget);

      now = DateTime(2026, 11, 12, 0, 0, 1);
      await tester.pump(const Duration(seconds: 61)); // timer tengah malam
      await tester.pump();

      expect(find.text('2026-11-12'), findsOneWidget);
    });

    testWidgets('berganti saat aplikasi dibuka kembali (resume)',
        (tester) async {
      var now = DateTime(2026, 11, 11, 21, 0);
      await tester.pumpWidget(_todayText(() => now));
      expect(find.text('2026-11-11'), findsOneWidget);

      // Aplikasi di-background semalaman, lalu dibuka besok pagi.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = DateTime(2026, 11, 12, 7, 30);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.text('2026-11-12'), findsOneWidget);
    });
  });

  group('HabitCard memakai todayProvider', () {
    // Selesai 10 & 11 Nov, tidak ada check-in 12 Nov.
    final habit = HabitModel(
      id: 'h1',
      title: 'Baca Buku',
      records: [
        HabitRecord(date: '2026-11-10', status: 'completed'),
        HabitRecord(date: '2026-11-11', status: 'completed'),
      ],
    );

    testWidgets('streak & status ter-reset saat aplikasi dibuka lusa',
        (tester) async {
      var now = DateTime(2026, 11, 11, 22, 0);
      await tester.pumpWidget(_card(habit, () => now));
      expect(find.text('2 hari'), findsOneWidget);

      // 12 Nov: belum check-in, streak tetap 2 (toleransi hari berjalan).
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = DateTime(2026, 11, 12, 8, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('2 hari'), findsOneWidget);

      // 13 Nov: 12 Nov terlewat -> streak putus dan label disembunyikan.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = DateTime(2026, 11, 13, 8, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('2 hari'), findsNothing);
    });
  });
}

Widget _todayText(Clock clock) {
  return ProviderScope(
    overrides: [clockProvider.overrideWithValue(clock)],
    child: MaterialApp(
      home: Consumer(
        builder: (context, ref, _) {
          final d = ref.watch(todayProvider);
          final text = '${d.year}-${d.month.toString().padLeft(2, '0')}-'
              '${d.day.toString().padLeft(2, '0')}';
          return Text(text);
        },
      ),
    ),
  );
}

Widget _card(HabitModel habit, Clock clock) {
  return ProviderScope(
    overrides: [clockProvider.overrideWithValue(clock)],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: HabitCard(habit: habit, onToggle: () {}, onLongPress: () {}),
        ),
      ),
    ),
  );
}
