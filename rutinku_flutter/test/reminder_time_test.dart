import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/widgets/habit_card.dart';
import 'package:rutinku_flutter/widgets/reminder_time_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengingat khusus per rutinitas (issue #9).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReminderTimeField.format / parse', () {
    test('format menambahkan nol di depan jam dan menit', () {
      expect(
        ReminderTimeField.format(const TimeOfDay(hour: 6, minute: 5)),
        '06:05',
      );
      expect(
        ReminderTimeField.format(const TimeOfDay(hour: 21, minute: 30)),
        '21:30',
      );
    });

    test('parse membaca "HH:mm" yang valid', () {
      expect(
        ReminderTimeField.parse('07:45'),
        const TimeOfDay(hour: 7, minute: 45),
      );
      expect(
        ReminderTimeField.parse(' 23:59 '),
        const TimeOfDay(hour: 23, minute: 59),
      );
    });

    test('parse mengembalikan null untuk nilai kosong atau tidak valid', () {
      for (final value in [null, '', '7', '24:00', '12:60', 'ab:cd', '1:2:3']) {
        expect(ReminderTimeField.parse(value), isNull, reason: '$value');
      }
    });
  });

  group('ReminderTimeField widget', () {
    Widget fieldApp(TextEditingController controller) {
      return MaterialApp(
        home: Scaffold(
          body: ReminderTimeField(
            controller: controller,
            decoration: const InputDecoration(),
          ),
        ),
      );
    }

    testWidgets('tanpa jam: tidak ada tombol hapus', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(fieldApp(controller));

      expect(find.byKey(const Key('reminder_time_clear')), findsNothing);
      expect(find.text('Tanpa pengingat'), findsOneWidget);
    });

    testWidgets('tombol hapus mengosongkan jam pengingat', (tester) async {
      final controller = TextEditingController(text: '08:30');
      addTearDown(controller.dispose);
      await tester.pumpWidget(fieldApp(controller));

      expect(find.text('Notifikasi muncul setiap hari pukul 08:30'),
          findsOneWidget);
      await tester.tap(find.byKey(const Key('reminder_time_clear')));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(find.byKey(const Key('reminder_time_clear')), findsNothing);
    });

    testWidgets('picker dibuka di jam yang tersimpan', (tester) async {
      final controller = TextEditingController(text: '08:30');
      addTearDown(controller.dispose);
      await tester.pumpWidget(fieldApp(controller));

      await tester.tap(find.byKey(const Key('reminder_time_field')));
      await tester.pumpAndSettle();
      expect(find.text('Pilih jam pengingat'), findsOneWidget);

      // Menekan OK tanpa mengubah apa pun harus mempertahankan 08:30,
      // bukan diganti jam sekarang.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(controller.text, '08:30');
    });
  });

  group('HabitCard menampilkan jam pengingat sebenarnya', () {
    Widget cardApp(HabitModel habit) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HabitCard(habit: habit, onToggle: () {}, onLongPress: () {}),
          ),
        ),
      );
    }

    testWidgets('menampilkan jam yang dipilih pengguna', (tester) async {
      await tester.pumpWidget(cardApp(
        HabitModel(id: 'h1', title: 'Baca Buku', reminderTime: '21:15'),
      ));
      await tester.pump();

      final reminder = find.byKey(const Key('habit_reminder_h1'));
      expect(
        find.descendant(of: reminder, matching: find.text('21:15')),
        findsOneWidget,
      );
    });

    testWidgets('tanpa pengingat tidak menampilkan jam palsu', (tester) async {
      await tester.pumpWidget(cardApp(
        HabitModel(id: 'h2', title: 'Minum Air'),
      ));
      await tester.pump();

      final reminder = find.byKey(const Key('habit_reminder_h2'));
      expect(
        find.descendant(of: reminder, matching: find.text('Tanpa pengingat')),
        findsOneWidget,
      );
      expect(find.text('07:00'), findsNothing);
      expect(find.text('Sepanjang hari'), findsNothing);
    });
  });
}
