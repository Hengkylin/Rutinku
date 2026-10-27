import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/repositories/habit_repository.dart';
import 'package:rutinku_flutter/notifiers/habit_notifier.dart';
import 'package:rutinku_flutter/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HabitModel & HabitRepository Tests', () {
    test('HabitModel supports records, isCompletedOn, and copyWith', () {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final habit = HabitModel(id: '1', title: 'Belajar Flutter');
      expect(habit.isCompletedOn(now), false);
      expect(habit.isCompletedToday, false);

      final updated = habit.copyWith(records: [HabitRecord(date: dateStr, status: 'completed')]);
      expect(updated.id, '1');
      expect(updated.title, 'Belajar Flutter');
      expect(updated.isCompletedOn(now), true);
      expect(updated.isCompletedToday, true);

      final renamed = updated.copyWith(title: 'Belajar Riverpod');
      expect(renamed.title, 'Belajar Riverpod');
      expect(renamed.isCompletedToday, true);
    });

    test('HabitModel serialization toMap, fromMap, toJson, and fromJson', () {
      final habit = HabitModel(
        id: '101',
        title: 'Membaca Buku',
        records: [
          HabitRecord(
            date: '2026-10-16',
            status: 'completed',
            mood: 'happy',
            note: '10 halaman',
          ),
        ],
        parentHabitId: 'parent-1',
        category: 'Belajar',
        reminderTime: '20:00',
      );

      final map = habit.toMap();
      expect(map['id'], '101');
      expect(map['title'], 'Membaca Buku');
      expect(map['records'], [
        {
          'date': '2026-10-16',
          'status': 'completed',
          'mood': 'happy',
          'note': '10 halaman',
          'momentImagePath': null,
        },
      ]);
      expect(map['parentHabitId'], 'parent-1');
      expect(map['category'], 'Belajar');
      expect(map['reminderTime'], '20:00');
      expect(map.containsKey('currentStreak'), false);

      final fromMapHabit = HabitModel.fromMap(map);
      expect(fromMapHabit.id, habit.id);
      expect(fromMapHabit.title, habit.title);
      expect(fromMapHabit.records, habit.records);
      expect(fromMapHabit.parentHabitId, 'parent-1');
      expect(fromMapHabit.isCompletedOn(DateTime.parse('2026-10-16')), true);
      expect(fromMapHabit.category, habit.category);
      expect(fromMapHabit.reminderTime, habit.reminderTime);

      final jsonString = habit.toJson();
      expect(jsonString.contains('"id":"101"'), true);
      expect(jsonString.contains('"title":"Membaca Buku"'), true);
      expect(jsonString.contains('"parentHabitId":"parent-1"'), true);
      expect(jsonString.contains('"records":'), true);

      final fromJsonHabit = HabitModel.fromJson(jsonString);
      expect(fromJsonHabit.id, habit.id);
      expect(fromJsonHabit.title, habit.title);
      expect(fromJsonHabit.records, habit.records);
      expect(fromJsonHabit.parentHabitId, 'parent-1');
      expect(fromJsonHabit.category, 'Belajar');
      expect(fromJsonHabit.reminderTime, '20:00');
    });

    test('HabitModel streakCount dynamic calculation with today grace period', () {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
      final twoDaysAgoStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 2)));
      final threeDaysAgoStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 3)));

      // 1. Kosong -> streak 0
      final emptyHabit = HabitModel(id: '1', title: 'Test');
      expect(emptyHabit.streakCount, 0);

      // 2. Hari ini selesai, kemarin selesai, 2 hari lalu selesai -> streak 3
      final activeStreakHabit = HabitModel(
        id: '2',
        title: 'Test',
        records: [
          HabitRecord(date: todayStr, status: 'completed'),
          HabitRecord(date: yesterdayStr, status: 'completed'),
          HabitRecord(date: twoDaysAgoStr, status: 'completed'),
        ],
      );
      expect(activeStreakHabit.streakCount, 3);

      // 3. Hari ini BELUM selesai, tapi kemarin & 2 hari lalu selesai -> streak tetap 2 (toleransi mundur dari kemarin)
      final pendingTodayHabit = HabitModel(
        id: '3',
        title: 'Test',
        records: [
          HabitRecord(date: yesterdayStr, status: 'completed'),
          HabitRecord(date: twoDaysAgoStr, status: 'completed'),
        ],
      );
      expect(pendingTodayHabit.streakCount, 2);

      // 4. Hari ini belum selesai, kemarin juga bolong, 3 hari lalu selesai -> streak 0 (patah)
      final brokenStreakHabit = HabitModel(
        id: '4',
        title: 'Test',
        records: [
          HabitRecord(date: threeDaysAgoStr, status: 'completed'),
        ],
      );
      expect(brokenStreakHabit.streakCount, 0);
    });

    test('HabitModel weeklyProgress dynamic calculation', () {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

      final habit = HabitModel(
        id: '1',
        title: 'Test',
        records: [
          HabitRecord(date: todayStr, status: 'completed'),
          HabitRecord(date: yesterdayStr, status: 'completed'),
        ],
      );

      // 2 dari 7 hari selesai = 2 / 7.0
      expect(habit.weeklyProgress, closeTo(2 / 7.0, 0.001));

      final emptyHabit = HabitModel(id: '2', title: 'Test');
      expect(emptyHabit.weeklyProgress, 0.0);
    });

    test('HabitModel parses legacy completedDates gracefully', () {
      final legacyMap = {
        'id': 'legacy-1',
        'title': 'Olahraga Lama',
        'completedDates': ['2026-10-15', '2026-10-16'],
      };
      final habit = HabitModel.fromMap(legacyMap);
      expect(habit.records.length, 2);
      expect(habit.records[0].date, '2026-10-15');
      expect(habit.records[0].status, 'completed');
      expect(habit.records[1].date, '2026-10-16');
      expect(habit.isCompletedOn(DateTime.parse('2026-10-15')), true);
    });

    test('HabitRepository persists data across restarts in SharedPreferences', () async {
      final now = DateTime.now();
      final repo1 = HabitRepository();
      await repo1.addHabit('Minum Air', category: 'Kesehatan', reminderTime: '07:00');
      
      // Simulasi restart aplikasi dengan membuat instance HabitRepository baru
      final repo2 = HabitRepository();
      final persistedHabits = await repo2.fetchHabits();
      expect(persistedHabits.length, 1);
      expect(persistedHabits.first.title, 'Minum Air');
      expect(persistedHabits.first.category, 'Kesehatan');
      expect(persistedHabits.first.reminderTime, '07:00');
      expect(persistedHabits.first.isCompletedOn(now), false);

      // Check-in melalui repo2
      await repo2.toggleCheckIn(persistedHabits.first.id, now);

      // Simulasi restart aplikasi lagi
      final repo3 = HabitRepository();
      final reloadedHabits = await repo3.fetchHabits();
      expect(reloadedHabits.first.isCompletedOn(now), true);
    });

    test('HabitRepository toggleCheckIn & updateHabit with copyWith & restoreHabit', () async {
      final now = DateTime.now();
      final repo = HabitRepository();
      await repo.addHabit('Minum Air');
      final habits = await repo.fetchHabits();
      expect(habits.length, 1);
      final habit = habits.first;
      final id = habit.id;
      expect(habit.isCompletedOn(now), false);

      // Toggle check-in to true
      await repo.toggleCheckIn(id, now);
      var currentHabits = await repo.fetchHabits();
      expect(currentHabits.first.isCompletedOn(now), true);

      // Update habit preserves records
      await repo.updateHabit(id, 'Minum 2L Air', 'Kesehatan', '08:00');
      currentHabits = await repo.fetchHabits();
      expect(currentHabits.first.title, 'Minum 2L Air');
      expect(currentHabits.first.category, 'Kesehatan');
      expect(currentHabits.first.reminderTime, '08:00');
      expect(currentHabits.first.isCompletedOn(now), true);

      // Toggle check-in back to false
      await repo.toggleCheckIn(id, now);
      currentHabits = await repo.fetchHabits();
      expect(currentHabits.first.isCompletedOn(now), false);

      // Delete habit
      await repo.deleteHabit(id);
      currentHabits = await repo.fetchHabits();
      expect(currentHabits.isEmpty, true);

      // Restore habit
      await repo.restoreHabit(habit);
      currentHabits = await repo.fetchHabits();
      expect(currentHabits.length, 1);
      expect(currentHabits.first.id, id);
    });
  });

  group('HabitNotifier Optimistic UI & Check-in Tests', () {
    test('toggleCheckIn performs optimistic update and toggles check-in status', () async {
      final now = DateTime.now();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Add a habit first
      final repo = container.read(habitRepositoryProvider);
      await repo.addHabit('Lari Pagi');

      // Initialize notifier
      final initial = await container.read(habitNotifierProvider.future);
      expect(initial.length, 1);
      final habitId = initial.first.id;
      expect(initial.first.isCompletedOn(now), false);

      // Call toggleCheckIn - verify optimistic update occurs immediately
      final future = container.read(habitNotifierProvider.notifier).toggleCheckIn(habitId, now);
      
      // Right away before future completes, optimistic state is true
      expect(container.read(habitNotifierProvider).value?.first.isCompletedOn(now), true);

      // Await completion
      await future;
      expect(container.read(habitNotifierProvider).value?.first.isCompletedOn(now), true);

      // Toggle off
      await container.read(habitNotifierProvider.notifier).toggleCheckIn(habitId, now);
      expect(container.read(habitNotifierProvider).value?.first.isCompletedOn(now), false);
    });

    test('deleteHabit and restoreHabit work in HabitNotifier', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(habitRepositoryProvider);
      await repo.addHabit('Olahraga');

      final initial = await container.read(habitNotifierProvider.future);
      expect(initial.length, 1);
      final habit = initial.first;

      await container.read(habitNotifierProvider.notifier).deleteHabit(habit.id);
      expect(container.read(habitNotifierProvider).value?.isEmpty, true);

      await container.read(habitNotifierProvider.notifier).restoreHabit(habit);
      expect(container.read(habitNotifierProvider).value?.length, 1);
      expect(container.read(habitNotifierProvider).value?.first.title, 'Olahraga');
    });
  });

  group('Smart Reminder & NotificationService Tests', () {
    test('NotificationService is a singleton', () {
      final s1 = NotificationService();
      final s2 = NotificationService();
      expect(identical(s1, s2), true);
    });

    test('HabitRepository schedules and cancels reminders gracefully', () async {
      final repo = HabitRepository();
      // addHabit with reminderTime
      await repo.addHabit('Meditasi', category: 'Kesehatan', reminderTime: '06:30');
      var habits = await repo.fetchHabits();
      expect(habits.length, 1);
      expect(habits.first.reminderTime, '06:30');

      // updateHabit changing reminderTime
      await repo.updateHabit(habits.first.id, 'Meditasi Pagi', 'Kesehatan', '07:00');
      habits = await repo.fetchHabits();
      expect(habits.first.reminderTime, '07:00');

      // updateHabit removing reminderTime (cancel reminder)
      await repo.updateHabit(habits.first.id, 'Meditasi Bebas', 'Kesehatan', '');
      habits = await repo.fetchHabits();
      expect(habits.first.reminderTime, '');

      // deleteHabit (cancel reminder)
      final habit = habits.first;
      await repo.deleteHabit(habit.id);
      habits = await repo.fetchHabits();
      expect(habits.isEmpty, true);

      // restoreHabit
      await repo.restoreHabit(habit);
      habits = await repo.fetchHabits();
      expect(habits.length, 1);
    });
  });

  group('Mood Journal & Recovery Mode Tests', () {
    test('HabitModel streakCount preserves streak when a day is marked as rest', () {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
      final twoDaysAgoStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 2)));

      // Hari ini libur (rest), kemarin libur (rest), 2 hari lalu completed -> streak tetap 1!
      final recoveryHabit = HabitModel(
        id: 'rec-1',
        title: 'Lari Pagi',
        records: [
          HabitRecord(date: todayStr, status: 'rest', mood: '😫', note: 'Kaki pegal'),
          HabitRecord(date: yesterdayStr, status: 'rest'),
          HabitRecord(date: twoDaysAgoStr, status: 'completed'),
        ],
      );

      expect(recoveryHabit.streakCount, 1);
      expect(recoveryHabit.todayRecord?.status, 'rest');
      expect(recoveryHabit.todayRecord?.mood, '😫');
      expect(recoveryHabit.todayRecord?.note, 'Kaki pegal');
    });

    test('HabitRepository updateRecordDetails adds and modifies mood/status/note', () async {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final repo = HabitRepository();
      await repo.addHabit('Baca Buku');
      var habits = await repo.fetchHabits();
      final id = habits.first.id;

      // Update record details when no record existed yet
      await repo.updateRecordDetails(
        id,
        now,
        status: 'skipped',
        mood: '😐',
        note: 'Banyak tugas kantor',
      );

      habits = await repo.fetchHabits();
      final record = habits.first.getRecordOn(now);
      expect(record, isNotNull);
      expect(record!.date, dateStr);
      expect(record.status, 'skipped');
      expect(record.mood, '😐');
      expect(record.note, 'Banyak tugas kantor');

      // Update existing record to 'completed' with new mood
      await repo.updateRecordDetails(
        id,
        now,
        status: 'completed',
        mood: '😄',
        note: 'Selesai 20 halaman!',
      );

      habits = await repo.fetchHabits();
      final updatedRecord = habits.first.getRecordOn(now);
      expect(updatedRecord!.status, 'completed');
      expect(updatedRecord.mood, '😄');
      expect(updatedRecord.note, 'Selesai 20 halaman!');
    });

    test('HabitNotifier updateHabitRecord updates state optimistically', () async {
      final now = DateTime.now();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(habitRepositoryProvider);
      await repo.addHabit('Minum Vitamin');

      final initial = await container.read(habitNotifierProvider.future);
      final habitId = initial.first.id;

      // Call updateHabitRecord
      await container.read(habitNotifierProvider.notifier).updateHabitRecord(
        habitId,
        now,
        status: 'rest',
        mood: '😄',
        note: 'Jadwal istirahat',
      );

      final current = container.read(habitNotifierProvider).value?.first;
      expect(current?.todayRecord?.status, 'rest');
      expect(current?.todayRecord?.mood, '😄');
      expect(current?.todayRecord?.note, 'Jadwal istirahat');
    });
  });

  group('Habit Stacking Tests', () {
    test('HabitRepository supports adding and updating habit with parentHabitId', () async {
      final repo = HabitRepository();
      // 1. Tambah habit induk
      await repo.addHabit('Sarapan Pagi', category: 'Kesehatan');
      var habits = await repo.fetchHabits();
      expect(habits.length, 1);
      final parentId = habits.first.id;
      expect(habits.first.parentHabitId, isNull);

      // 2. Tambah habit anak yang ditautkan (Habit Stacking)
      await repo.addHabit(
        'Minum Vitamin',
        category: 'Kesehatan',
        parentHabitId: parentId,
      );
      habits = await repo.fetchHabits();
      expect(habits.length, 2);
      final childHabit = habits.firstWhere((h) => h.title == 'Minum Vitamin');
      expect(childHabit.parentHabitId, parentId);

      // 3. Update habit anak untuk melepaskan tautan (parentHabitId: null)
      await repo.updateHabit(
        childHabit.id,
        'Minum Vitamin Siang',
        'Kesehatan',
        '12:00',
        parentHabitId: null,
      );
      habits = await repo.fetchHabits();
      final unlinkedChild = habits.firstWhere((h) => h.id == childHabit.id);
      expect(unlinkedChild.parentHabitId, isNull);
      expect(unlinkedChild.title, 'Minum Vitamin Siang');
    });

    test('HabitNotifier supports parentHabitId in addHabit and updateHabit', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(habitNotifierProvider.notifier);
      await notifier.addHabit('Bangun Pagi');
      var habits = await container.read(habitNotifierProvider.future);
      final parentId = habits.first.id;

      await notifier.addHabit('Merapikan Tempat Tidur', parentHabitId: parentId);
      habits = await container.read(habitNotifierProvider.future);
      expect(habits.length, 2);
      final stacked = habits.firstWhere((h) => h.title == 'Merapikan Tempat Tidur');
      expect(stacked.parentHabitId, parentId);
    });
  });
}
