import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/notifiers/habit_notifier.dart';
import 'package:rutinku_flutter/repositories/habit_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final now = DateTime.now();
  String dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  group('HabitModel - Progressive Habit', () {
    test('fromMap data JSON lama memakai nilai default', () {
      final habit = HabitModel.fromMap({
        'id': '1',
        'title': 'Lama',
        'records': [
          {'date': '2026-10-16', 'status': 'completed'},
        ],
      });

      expect(habit.targetValue, 1);
      expect(habit.unit, isNull);
      expect(habit.records.first.currentValue, 0);
      expect(habit.isCompletedOn(DateTime.parse('2026-10-16')), true);
    });

    test('toMap/fromMap mempertahankan targetValue, unit, dan currentValue', () {
      final habit = HabitModel(
        id: '1',
        title: 'Minum Air',
        targetValue: 8,
        unit: 'gelas',
        records: [HabitRecord(date: '2026-10-16', currentValue: 3)],
      );

      final restored = HabitModel.fromJson(habit.toJson());

      expect(restored.targetValue, 8);
      expect(restored.unit, 'gelas');
      expect(restored.records, habit.records);
    });

    test('target > 1: selesai hanya jika currentValue >= targetValue', () {
      HabitModel withValue(int value) => HabitModel(
            id: '1',
            title: 'Minum Air',
            targetValue: 3,
            records: [
              HabitRecord(
                date: dateKey(now),
                status: 'completed',
                currentValue: value,
              ),
            ],
          );

      // Status 'completed' saja tidak cukup untuk target > 1
      expect(withValue(2).isCompletedToday, false);
      expect(withValue(3).isCompletedToday, true);
      expect(withValue(5).isCompletedToday, true);
    });

    test('streakCount memakai logika target angka', () {
      final yesterday = now.subtract(const Duration(days: 1));
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      final habit = HabitModel(
        id: '1',
        title: 'Baca',
        targetValue: 2,
        records: [
          HabitRecord(date: dateKey(now), currentValue: 2),
          HabitRecord(date: dateKey(yesterday), currentValue: 2),
          // Belum mencapai target -> memutus streak
          HabitRecord(date: dateKey(twoDaysAgo), currentValue: 1),
        ],
      );

      expect(habit.streakCount, 2);
    });

    test('incrementProgress: record baru pending, lalu completed saat target tercapai', () {
      var habit = HabitModel(id: '1', title: 'Minum Air', targetValue: 2);

      habit = habit.incrementProgress(now);
      expect(habit.todayRecord?.currentValue, 1);
      expect(habit.todayRecord?.status, 'pending');
      expect(habit.isCompletedToday, false);

      habit = habit.incrementProgress(now);
      expect(habit.todayRecord?.currentValue, 2);
      expect(habit.todayRecord?.status, 'completed');
      expect(habit.isCompletedToday, true);
      expect(habit.records.length, 1);
    });

    test('toggleCheckIn membalik status via copyWith tanpa menghapus data', () {
      final habit = HabitModel(
        id: '1',
        title: 'Olahraga',
        records: [
          HabitRecord(date: dateKey(now), status: 'completed', mood: '😊'),
        ],
      );

      final off = habit.toggleCheckIn(now);
      expect(off.todayRecord?.status, 'pending');
      expect(off.todayRecord?.mood, '😊');
      expect(off.isCompletedToday, false);

      final on = off.toggleCheckIn(now);
      expect(on.todayRecord?.status, 'completed');
      expect(on.todayRecord?.mood, '😊');
    });

    test('toggleCheckIn habit progresif ditolak sebelum target tercapai', () {
      final belowTarget = HabitModel(
        id: '1',
        title: 'Minum Air',
        targetValue: 3,
        records: [
          HabitRecord(date: dateKey(now), status: 'pending', currentValue: 2),
        ],
      );
      expect(identical(belowTarget.toggleCheckIn(now), belowTarget), true);

      final noRecord = HabitModel(id: '2', title: 'Baca', targetValue: 3);
      expect(identical(noRecord.toggleCheckIn(now), noRecord), true);

      final reached = belowTarget.incrementProgress(now).toggleCheckIn(now);
      expect(reached.todayRecord?.status, 'pending');
      expect(reached.todayRecord?.currentValue, 3);
    });

    test('incrementProgress target 1 langsung completed', () {
      final habit =
          HabitModel(id: '1', title: 'Olahraga').incrementProgress(now);

      expect(habit.todayRecord?.status, 'completed');
      expect(habit.isCompletedToday, true);
    });
  });

  group('HabitRepository - Progressive Habit', () {
    test('addHabit & updateHabit menyimpan targetValue dan unit', () async {
      final repo = HabitRepository();
      await repo.addHabit('Minum Air', targetValue: 8, unit: 'gelas');

      var habit = (await repo.fetchHabits()).first;
      expect(habit.targetValue, 8);
      expect(habit.unit, 'gelas');

      await repo.updateHabit(
        habit.id,
        'Minum Air Putih',
        'Kesehatan',
        '',
        targetValue: 10,
        unit: 'gelas',
      );
      habit = (await repo.fetchHabits()).first;
      expect(habit.targetValue, 10);
      expect(habit.unit, 'gelas');
    });

    test('incrementHabitProgress tersimpan persisten', () async {
      final repo = HabitRepository();
      await repo.addHabit('Membaca', targetValue: 2, unit: 'halaman');
      final id = (await repo.fetchHabits()).first.id;

      await repo.incrementHabitProgress(id, now);
      var habit = (await HabitRepository().fetchHabits()).first;
      expect(habit.todayRecord?.currentValue, 1);
      expect(habit.todayRecord?.status, 'pending');

      await repo.incrementHabitProgress(id, now);
      habit = (await HabitRepository().fetchHabits()).first;
      expect(habit.todayRecord?.currentValue, 2);
      expect(habit.isCompletedToday, true);
    });

    test('updateRecordDetails tidak menghapus currentValue', () async {
      final repo = HabitRepository();
      await repo.addHabit('Minum Air', targetValue: 8);
      final id = (await repo.fetchHabits()).first.id;

      await repo.incrementHabitProgress(id, now);
      await repo.updateRecordDetails(id, now, mood: '😊');

      final record = (await repo.fetchHabits()).first.todayRecord;
      expect(record?.currentValue, 1);
      expect(record?.mood, '😊');
    });
  });

  group('HabitNotifier - incrementHabitProgress', () {
    test('optimistic update lalu tersimpan ke repository', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(habitRepositoryProvider)
          .addHabit('Minum Air', targetValue: 2, unit: 'gelas');
      final habits = await container.read(habitNotifierProvider.future);
      final id = habits.first.id;
      final notifier = container.read(habitNotifierProvider.notifier);

      final future = notifier.incrementHabitProgress(id, now);
      // State langsung berubah sebelum repository selesai
      expect(
        container.read(habitNotifierProvider).value?.first.todayRecord?.currentValue,
        1,
      );
      await future;

      await notifier.incrementHabitProgress(id, now);
      final current = container.read(habitNotifierProvider).value!.first;
      expect(current.todayRecord?.currentValue, 2);
      expect(current.isCompletedToday, true);

      final persisted = (await HabitRepository().fetchHabits()).first;
      expect(persisted.todayRecord?.currentValue, 2);
      expect(persisted.todayRecord?.status, 'completed');
    });

    test('updateHabit tanpa target mengembalikan ke default 1', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(habitRepositoryProvider)
          .addHabit('Minum Air', targetValue: 8, unit: 'gelas');
      final id = (await container.read(habitNotifierProvider.future)).first.id;

      await container
          .read(habitNotifierProvider.notifier)
          .updateHabit(id, 'Minum Air', 'Kesehatan', '');

      final habit = container.read(habitNotifierProvider).value!.first;
      expect(habit.targetValue, 1);
      expect(habit.unit, isNull);
    });
  });
}
