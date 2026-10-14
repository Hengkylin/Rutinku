import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/repositories/habit_repository.dart';
import 'package:rutinku_flutter/notifiers/habit_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HabitModel & HabitRepository Tests', () {
    test('HabitModel supports isCompletedToday and copyWith', () {
      final habit = HabitModel(id: '1', title: 'Belajar Flutter');
      expect(habit.isCompletedToday, false);

      final updated = habit.copyWith(isCompletedToday: true);
      expect(updated.id, '1');
      expect(updated.title, 'Belajar Flutter');
      expect(updated.isCompletedToday, true);

      final renamed = updated.copyWith(title: 'Belajar Riverpod');
      expect(renamed.title, 'Belajar Riverpod');
      expect(renamed.isCompletedToday, true);
    });

    test('HabitModel serialization toMap, fromMap, toJson, and fromJson', () {
      final habit = HabitModel(
        id: '101',
        title: 'Membaca Buku',
        isCompletedToday: true,
        category: 'Belajar',
        reminderTime: '20:00',
        currentStreak: 5,
      );

      final map = habit.toMap();
      expect(map['id'], '101');
      expect(map['title'], 'Membaca Buku');
      expect(map['isCompletedToday'], true);
      expect(map['category'], 'Belajar');
      expect(map['reminderTime'], '20:00');
      expect(map['currentStreak'], 5);

      final fromMapHabit = HabitModel.fromMap(map);
      expect(fromMapHabit.id, habit.id);
      expect(fromMapHabit.title, habit.title);
      expect(fromMapHabit.isCompletedToday, habit.isCompletedToday);
      expect(fromMapHabit.category, habit.category);
      expect(fromMapHabit.reminderTime, habit.reminderTime);
      expect(fromMapHabit.currentStreak, habit.currentStreak);

      final jsonString = habit.toJson();
      expect(jsonString.contains('"id":"101"'), true);
      expect(jsonString.contains('"title":"Membaca Buku"'), true);

      final fromJsonHabit = HabitModel.fromJson(jsonString);
      expect(fromJsonHabit.id, habit.id);
      expect(fromJsonHabit.title, habit.title);
      expect(fromJsonHabit.isCompletedToday, true);
      expect(fromJsonHabit.category, 'Belajar');
      expect(fromJsonHabit.reminderTime, '20:00');
      expect(fromJsonHabit.currentStreak, 5);
    });

    test('HabitRepository persists data across restarts in SharedPreferences', () async {
      final repo1 = HabitRepository();
      await repo1.addHabit('Minum Air', category: 'Kesehatan', reminderTime: '07:00');
      
      // Simulasi restart aplikasi dengan membuat instance HabitRepository baru
      final repo2 = HabitRepository();
      final persistedHabits = await repo2.fetchHabits();
      expect(persistedHabits.length, 1);
      expect(persistedHabits.first.title, 'Minum Air');
      expect(persistedHabits.first.category, 'Kesehatan');
      expect(persistedHabits.first.reminderTime, '07:00');
      expect(persistedHabits.first.isCompletedToday, false);

      // Check-in melalui repo2
      await repo2.toggleCheckIn(persistedHabits.first.id);

      // Simulasi restart aplikasi lagi
      final repo3 = HabitRepository();
      final reloadedHabits = await repo3.fetchHabits();
      expect(reloadedHabits.first.isCompletedToday, true);
    });

    test('HabitRepository toggleCheckIn & updateHabit with copyWith & restoreHabit', () async {
      final repo = HabitRepository();
      await repo.addHabit('Minum Air');
      final habits = await repo.fetchHabits();
      expect(habits.length, 1);
      final habit = habits.first;
      final id = habit.id;
      expect(habit.isCompletedToday, false);

      // Toggle check-in to true
      await repo.toggleCheckIn(id);
      var currentHabits = await repo.fetchHabits();
      expect(currentHabits.first.isCompletedToday, true);

      // Update habit preserves isCompletedToday
      await repo.updateHabit(id, 'Minum 2L Air', 'Kesehatan', '08:00');
      currentHabits = await repo.fetchHabits();
      expect(currentHabits.first.title, 'Minum 2L Air');
      expect(currentHabits.first.category, 'Kesehatan');
      expect(currentHabits.first.reminderTime, '08:00');
      expect(currentHabits.first.isCompletedToday, true);

      // Toggle check-in back to false
      await repo.toggleCheckIn(id);
      currentHabits = await repo.fetchHabits();
      expect(currentHabits.first.isCompletedToday, false);

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

  group('HabitNotifier Optimistic UI & Gamifikasi & Restore Tests', () {
    test('toggleCheckIn performs optimistic update and updates primogems', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Add a habit first
      final repo = container.read(habitRepositoryProvider);
      await repo.addHabit('Lari Pagi');

      // Initialize notifier
      final initial = await container.read(habitNotifierProvider.future);
      expect(initial.length, 1);
      final habitId = initial.first.id;
      expect(initial.first.isCompletedToday, false);
      expect(container.read(primogemsProvider), 0);

      // Call toggleCheckIn - verify optimistic update occurs immediately
      final future = container.read(habitNotifierProvider.notifier).toggleCheckIn(habitId);
      
      // Right away before future completes, optimistic state is true
      expect(container.read(habitNotifierProvider).value?.first.isCompletedToday, true);

      // Await completion
      await future;

      // Primogems increased by +15
      expect(container.read(primogemsProvider), 15);
      expect(container.read(habitNotifierProvider).value?.first.isCompletedToday, true);

      // Toggle off
      await container.read(habitNotifierProvider.notifier).toggleCheckIn(habitId);
      expect(container.read(primogemsProvider), 0);
      expect(container.read(habitNotifierProvider).value?.first.isCompletedToday, false);
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
}
