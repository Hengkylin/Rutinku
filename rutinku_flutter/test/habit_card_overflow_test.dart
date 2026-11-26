import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/notifiers/today_notifier.dart';
import 'package:rutinku_flutter/widgets/habit_card.dart';

/// Regresi: di HP lebar 411dp dengan ukuran huruf sistem besar, baris
/// "Tanpa pengingat" di HabitCard overflow ("OVERFLOWED BY 8.8 PIXELS").
/// Overflow dilaporkan sebagai error, jadi tes ini gagal bila muncul lagi.
void main() {
  final now = DateTime(2026, 11, 26, 9);

  Future<void> pumpCard(
    WidgetTester tester,
    HabitModel habit, {
    double width = 411,
    double textScale = 1.3,
  }) async {
    tester.view.physicalSize = Size(width * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [clockProvider.overrideWithValue(() => now)],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: ListView(
            // Sama dengan padding daftar di DashboardScreen.
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              HabitCard(habit: habit, onToggle: () {}, onLongPress: () {}),
            ],
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('tanpa pengingat + judul panjang + huruf besar: tidak overflow',
      (tester) async {
    await pumpCard(
      tester,
      HabitModel(id: 'h1', title: 'Minum air putih, jaga kesehatan'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Tanpa pengingat'), findsOneWidget);
  });

  testWidgets('streak & mood di layar sempit (360dp, huruf 1.5x): tidak overflow',
      (tester) async {
    await pumpCard(
      tester,
      HabitModel(id: 'h2', title: 'Pergi tidur lebih awal', records: [
        HabitRecord(date: '2026-11-25', status: 'completed'),
        HabitRecord(date: '2026-11-24', status: 'completed'),
        HabitRecord(date: '2026-11-26', status: 'pending', mood: 'senang'),
      ]),
      width: 360,
      textScale: 1.5,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('2 hari'), findsOneWidget);
  });

  testWidgets('dengan jam pengingat: jam tetap tampil', (tester) async {
    await pumpCard(
      tester,
      HabitModel(id: 'h3', title: 'Ambil Pengingat Pil', reminderTime: '07:30'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('07:30'), findsOneWidget);
  });
}
