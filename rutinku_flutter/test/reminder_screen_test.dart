import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/notifiers/today_notifier.dart';
import 'package:rutinku_flutter/repositories/habit_repository.dart';
import 'package:rutinku_flutter/screens/dashboard_screen.dart';
import 'package:rutinku_flutter/screens/reminder_screen.dart';
import 'package:rutinku_flutter/services/notification_service.dart';
import 'package:rutinku_flutter/widgets/edit_habit_bottom_sheet.dart';

class MockNotificationService extends Mock implements NotificationService {}

/// Halaman Pengingat yang dibuka dari ikon lonceng Dashboard
/// (sebelumnya ikon lonceng tidak bisa diketuk).
void main() {
  final now = DateTime(2026, 11, 26, 9, 0); // Kamis 09:00

  void seed(List<HabitModel> habits) {
    SharedPreferences.setMockInitialValues({
      HabitRepository.storageKey:
          json.encode(habits.map((h) => h.toMap()).toList()),
    });
  }

  Widget app(Widget home) => ProviderScope(
        overrides: [clockProvider.overrideWithValue(() => now)],
        child: MaterialApp(home: home),
      );

  group('ReminderScreen.minutesOf & statusOf', () {
    test('minutesOf membaca HH:mm dan menolak format tidak valid', () {
      expect(ReminderScreen.minutesOf('07:30'), 450);
      expect(ReminderScreen.minutesOf(' 20:05 '), 1205);
      expect(ReminderScreen.minutesOf(null), isNull);
      expect(ReminderScreen.minutesOf(''), isNull);
      expect(ReminderScreen.minutesOf('25:00'), isNull);
      expect(ReminderScreen.minutesOf('jam 7'), isNull);
    });

    test('statusOf: akan datang, sudah lewat, dan sudah selesai', () {
      expect(
        ReminderScreen.statusOf(
            HabitModel(id: 'a', title: 'A', reminderTime: '20:00'), now),
        'Hari ini pukul 20:00',
      );
      expect(
        ReminderScreen.statusOf(
            HabitModel(id: 'b', title: 'B', reminderTime: '06:00'), now),
        'Sudah lewat hari ini · berikutnya besok 06:00',
      );
      expect(
        ReminderScreen.statusOf(
          HabitModel(id: 'c', title: 'C', reminderTime: '20:00', records: [
            HabitRecord(date: '2026-11-26', status: 'completed'),
          ]),
          now,
        ),
        'Selesai hari ini · berbunyi lagi besok 20:00',
      );
    });
  });

  testWidgets('menampilkan pengingat terurut per jam + rutinitas tanpa pengingat',
      (tester) async {
    seed([
      HabitModel(id: 'a', title: 'Minum Air', reminderTime: '20:00'),
      HabitModel(id: 'b', title: 'Sikat Gigi', reminderTime: '07:00', records: [
        HabitRecord(date: '2026-11-26', status: 'completed'),
      ]),
      HabitModel(id: 'c', title: 'Olahraga', reminderTime: '06:00'),
      HabitModel(id: 'd', title: 'Baca Buku'),
    ]);

    await tester.pumpWidget(app(const ReminderScreen()));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Terjadwal (3)'), findsOneWidget);
    expect(find.text('Tanpa pengingat (1)'), findsOneWidget);
    expect(find.text('Hari ini pukul 20:00'), findsOneWidget);
    expect(find.text('Selesai hari ini · berbunyi lagi besok 07:00'),
        findsOneWidget);
    expect(find.text('Sudah lewat hari ini · berikutnya besok 06:00'),
        findsOneWidget);
    expect(find.text('Ketuk untuk mengatur jam pengingat'), findsOneWidget);

    double y(String id) =>
        tester.getTopLeft(find.byKey(Key('reminder_item_$id'))).dy;
    expect(y('c') < y('b') && y('b') < y('a'), isTrue,
        reason: 'urut 06:00, 07:00, 20:00');
    expect(y('a') < y('d'), isTrue, reason: 'tanpa pengingat di bawah');
  });

  testWidgets('tanpa rutinitas: tampil pesan kosong', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(app(const ReminderScreen()));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byKey(const Key('reminder_empty')), findsOneWidget);
  });

  testWidgets('ketuk rutinitas membuka form edit untuk mengatur jam',
      (tester) async {
    seed([HabitModel(id: 'd', title: 'Baca Buku')]);

    await tester.pumpWidget(app(const ReminderScreen()));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await tester.tap(find.byKey(const Key('reminder_item_d')));
    await tester.pumpAndSettle();

    expect(find.byType(EditHabitBottomSheet), findsOneWidget);
  });

  testWidgets('tombol izin memanggil requestPermission lalu SnackBar',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final notifications = MockNotificationService();
    when(() => notifications.requestPermission()).thenAnswer((_) async {});

    await tester.pumpWidget(
        app(ReminderScreen(notificationService: notifications)));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await tester.tap(find.byKey(const Key('reminder_permission_button')));
    await tester.pumpAndSettle();

    verify(() => notifications.requestPermission()).called(1);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('ikon lonceng di Dashboard membuka halaman Pengingat',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(app(const DashboardScreen()));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await tester.tap(find.byKey(const Key('dashboard_reminder_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reminder_screen')), findsOneWidget);
  });
}
