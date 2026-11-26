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
import 'package:rutinku_flutter/services/analytics_service.dart';
import 'package:rutinku_flutter/services/notification_service.dart';
import 'package:rutinku_flutter/widgets/add_habit_bottom_sheet.dart';
import 'package:rutinku_flutter/widgets/habit_card.dart';
import 'package:rutinku_flutter/widgets/schedule_days_field.dart';

class MockNotificationService extends Mock implements NotificationService {}

/// Fitur jadwal per hari: rutinitas hanya dijadwalkan pada hari tertentu
/// (mis. Senin, Rabu, Jumat). Tanggal acuan: Jumat 2026-11-27.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fri = DateTime(2026, 11, 27); // Jumat
  final thu = DateTime(2026, 11, 26); // Kamis
  const monWedFri = [1, 3, 5];
  HabitRecord done(String date) => HabitRecord(date: date, status: 'completed');

  group('HabitModel jadwal', () {
    test('default harian: semua hari terjadwal, label "Setiap hari"', () {
      final h = HabitModel(id: '1', title: 'Baca');
      expect(h.isDaily, isTrue);
      expect(h.scheduledDays, isEmpty);
      expect(h.isScheduledOn(thu), isTrue);
      expect(h.scheduleLabel, 'Setiap hari');
    });

    test('pilihan hari dirapikan: urut, unik, hanya 1..7; 7 hari = harian', () {
      expect(HabitModel.normalizeScheduledDays([5, 1, 3, 3, 9, 0]), [1, 3, 5]);
      expect(HabitModel.normalizeScheduledDays([1, 2, 3, 4, 5, 6, 7]), isEmpty);
      expect(HabitModel.normalizeScheduledDays(null), isEmpty);
      expect(
        HabitModel(id: '1', title: 'Lari', scheduledDays: [5, 1, 3])
            .scheduleLabel,
        'Sen, Rab, Jum',
      );
    });

    test('label ringkas: rentang & nama pola umum', () {
      expect(HabitModel.scheduleLabelFor([1, 2, 3, 4, 5, 6]), 'Sen–Sab');
      expect(HabitModel.scheduleLabelFor([1, 2, 3, 4, 5]), 'Hari kerja');
      expect(HabitModel.scheduleLabelFor([6, 7]), 'Akhir pekan');
      expect(HabitModel.scheduleLabelFor([1, 2, 3, 5]), 'Sen–Rab, Jum');
      expect(HabitModel.scheduleLabelFor([1, 2]), 'Sen, Sel');
      expect(HabitModel.scheduleLabelFor([]), 'Setiap hari');
    });

    test('isScheduledOn mengikuti hari dalam minggu', () {
      final h = HabitModel(id: '1', title: 'Lari', scheduledDays: monWedFri);
      expect(h.isDaily, isFalse);
      expect(h.isScheduledOn(fri), isTrue);
      expect(h.isScheduledOn(thu), isFalse);
    });

    test('serialisasi menyimpan jadwal; data lama tanpa field = harian', () {
      final h = HabitModel(id: '1', title: 'Lari', scheduledDays: monWedFri);
      expect(HabitModel.fromJson(h.toJson()).scheduledDays, monWedFri);
      expect(HabitModel.fromMap({'id': '1', 'title': 'Lama'}).isDaily, isTrue);
    });

    test('copyWith: 7 hari menjadi harian, tanpa argumen tetap', () {
      final h = HabitModel(id: '1', title: 'Lari', scheduledDays: monWedFri);
      expect(h.copyWith().scheduledDays, monWedFri);
      expect(h.copyWith(scheduledDays: [1, 2, 3, 4, 5, 6, 7]).isDaily, isTrue);
    });
  });

  group('Streak & progres dengan jadwal', () {
    test('Sen/Rab/Jum selalu selesai: hari tidak terjadwal tidak memutus', () {
      final h = HabitModel(id: '1', title: 'Lari', scheduledDays: monWedFri,
          records: [done('2026-11-23'), done('2026-11-25'), done('2026-11-27')]);
      expect(h.streakCountOn(fri), 3);
    });

    test('hari terjadwal yang terlewat tetap memutus streak', () {
      final h = HabitModel(id: '1', title: 'Lari', scheduledDays: monWedFri,
          records: [done('2026-11-23'), done('2026-11-27')]);
      expect(h.streakCountOn(fri), 1);
    });

    test('hari ini tidak terjadwal: streak tetap terhitung dari sebelumnya', () {
      final h = HabitModel(id: '1', title: 'Lari', scheduledDays: monWedFri,
          records: [done('2026-11-23'), done('2026-11-25')]);
      expect(h.streakCountOn(thu), 2);
    });

    test('rutinitas harian tetap putus bila sehari terlewat', () {
      final h = HabitModel(id: '1', title: 'Baca',
          records: [done('2026-11-27'), done('2026-11-25')]);
      expect(h.streakCountOn(fri), 1);
    });

    test('progres mingguan dibagi jumlah hari terjadwal (3), bukan 7', () {
      final h = HabitModel(id: '1', title: 'Lari', scheduledDays: monWedFri,
          records: [done('2026-11-23'), done('2026-11-27')]);
      expect(h.weeklyProgressOn(fri), closeTo(2 / 3, 1e-9));
    });
  });

  group('AnalyticsService dengan jadwal', () {
    test('completionRate 100% bila semua hari terjadwal selesai', () {
      final h = HabitModel(id: '1', title: 'Lari', scheduledDays: monWedFri,
          records: [done('2026-11-23'), done('2026-11-25'), done('2026-11-27')]);
      final service = AnalyticsService([h], now: fri);
      expect(service.completionRate(h, startDaysAgo: 0, days: 7), 100);
    });

    test('hari paling sering terlewat mengabaikan hari tidak terjadwal', () {
      final h = HabitModel(id: '1', title: 'Lari', scheduledDays: monWedFri,
          records: [HabitRecord(date: '2026-11-24', status: 'pending')]);
      expect(AnalyticsService([h], now: fri).getMostMissedDay(), isNull);
    });
  });

  group('ScheduleDaysField & ReminderScreen', () {
    test('summary & validate', () {
      expect(ScheduleDaysField.summary(ScheduleDaysField.allDays), 'Setiap hari');
      expect(ScheduleDaysField.summary([5, 1]), 'Sen, Jum');
      expect(ScheduleDaysField.validate([]), 'Pilih minimal 1 hari');
      expect(ScheduleDaysField.validate([1]), isNull);
    });

    test('status pengingat memakai hari terjadwal berikutnya', () {
      final h = HabitModel(id: '1', title: 'Lari', reminderTime: '20:00',
          scheduledDays: monWedFri);
      expect(ReminderScreen.statusOf(h, DateTime(2026, 11, 26, 9)),
          'Libur hari ini · berikutnya besok 20:00');
      final doneWed = h.copyWith(records: [done('2026-11-25')]);
      expect(ReminderScreen.statusOf(doneWed, DateTime(2026, 11, 25, 9)),
          'Selesai hari ini · berbunyi lagi Jum 20:00');
    });
  });

  group('Penjadwalan notifikasi per hari', () {
    late MockNotificationService notifications;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      notifications = MockNotificationService();
      when(() => notifications.scheduleDailyReminder(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            hour: any(named: 'hour'),
            minute: any(named: 'minute'),
            skipToday: any(named: 'skipToday'),
          )).thenAnswer((_) async {});
      when(() => notifications.scheduleWeeklyReminder(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            weekday: any(named: 'weekday'),
            hour: any(named: 'hour'),
            minute: any(named: 'minute'),
            skipToday: any(named: 'skipToday'),
          )).thenAnswer((_) async {});
      when(() => notifications.cancelReminder(any())).thenAnswer((_) async {});
    });

    test('jadwal Sen/Rab/Jum -> 3 alarm mingguan, tanpa alarm harian', () async {
      final repo = HabitRepository(
          notificationService: notifications, clock: () => thu);
      await repo.addHabit('Lari',
          reminderTime: '06:30', scheduledDays: monWedFri);

      final weekdays = verify(() => notifications.scheduleWeeklyReminder(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            weekday: captureAny(named: 'weekday'),
            hour: 6,
            minute: 30,
            skipToday: any(named: 'skipToday'),
          )).captured;
      expect(weekdays, monWedFri);
      verifyNever(() => notifications.scheduleDailyReminder(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            hour: any(named: 'hour'),
            minute: any(named: 'minute'),
            skipToday: any(named: 'skipToday'),
          ));
    });

    test('diubah menjadi harian -> alarm harian + alarm mingguan dibatalkan',
        () async {
      final repo = HabitRepository(
          notificationService: notifications, clock: () => thu);
      await repo.addHabit('Lari',
          reminderTime: '06:30', scheduledDays: monWedFri);
      final id = (await repo.fetchHabits()).single.id;
      clearInteractions(notifications);

      await repo.updateHabit(id, 'Lari', '', '06:30',
          scheduledDays: ScheduleDaysField.allDays);

      verify(() => notifications.scheduleDailyReminder(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            hour: 6,
            minute: 30,
            skipToday: any(named: 'skipToday'),
          )).called(1);
      verify(() => notifications.cancelReminder(any())).called(7);
      expect((await repo.fetchHabits()).single.isDaily, isTrue);
    });

    test('ID notifikasi mingguan unik per hari & tetap 32-bit', () {
      const base = 0x7FFFFFFF;
      final ids = [
        for (var d = 1; d <= 7; d++) HabitRepository.weeklyNotificationId(base, d)
      ];
      expect(ids.toSet().length, 7);
      expect(ids.every((id) => id > 0 && id <= 0x7FFFFFFF), isTrue);
    });
  });

  group('UI jadwal', () {
    Widget app(Widget home, {DateTime? now}) => ProviderScope(
          overrides: [clockProvider.overrideWithValue(() => now ?? thu)],
          child: MaterialApp(home: Scaffold(body: home)),
        );

    testWidgets('form tambah: preset Hari kerja tersimpan sebagai Sen..Jum',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(app(const AddHabitBottomSheet()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Kuliah');
      await tester.pumpAndSettle();
      await tester.ensureVisible(
          find.byKey(const Key('schedule_preset_weekdays')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('schedule_preset_weekdays')));
      // Tunggu animasi chip & perpindahan fokus selesai sebelum mengetuk lagi.
      await tester.pumpAndSettle();
      expect(find.text('Sen, Sel, Rab, Kam, Jum'), findsOneWidget);

      await tester.ensureVisible(find.text('Simpan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final habits =
          await tester.runAsync(() => HabitRepository().fetchHabits());
      expect(habits!.single.scheduledDays, [1, 2, 3, 4, 5]);
    });

    testWidgets('form tambah: semua hari dimatikan -> error, tidak tersimpan',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(app(const AddHabitBottomSheet()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Kuliah');
      await tester.pumpAndSettle();
      for (var d = 1; d <= 7; d++) {
        final chip = find.byKey(Key('schedule_day_$d'));
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Simpan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan'));
      await tester.pump();

      expect(find.text('Pilih minimal 1 hari'), findsOneWidget);
      final habits =
          await tester.runAsync(() => HabitRepository().fetchHabits());
      expect(habits, isEmpty);
    });

    testWidgets('HabitCard: label "Libur hari ini" di hari tidak terjadwal',
        (tester) async {
      final h = HabitModel(id: 'h1', title: 'Lari', scheduledDays: monWedFri);
      await tester.pumpWidget(app(
        ListView(children: [
          HabitCard(habit: h, onToggle: () {}, onLongPress: () {}),
        ]),
      ));
      await tester.pump();

      expect(find.text('Libur hari ini · Sen, Rab, Jum'), findsOneWidget);
    });

    testWidgets('Dashboard: target hanya menghitung rutinitas hari ini',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        HabitRepository.storageKey: json.encode([
          HabitModel(id: 'a', title: 'Baca Buku').toMap(),
          HabitModel(id: 'b', title: 'Lari', scheduledDays: monWedFri).toMap(),
        ]),
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [clockProvider.overrideWithValue(() => thu)],
        child: const MaterialApp(home: DashboardScreen()),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('1 target'), findsOneWidget);
      expect(find.text('0 dari 1'), findsOneWidget);
    });
  });
}
