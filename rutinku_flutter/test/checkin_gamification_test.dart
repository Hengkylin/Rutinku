import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/repositories/habit_repository.dart';
import 'package:rutinku_flutter/notifiers/habit_notifier.dart';

void main() {
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
      expect(habits.first.isCompletedToday, true);

      // Update habit preserves isCompletedToday
      await repo.updateHabit(id, 'Minum 2L Air', 'Kesehatan', '08:00');
      expect(habits.first.title, 'Minum 2L Air');
      expect(habits.first.category, 'Kesehatan');
      expect(habits.first.reminderTime, '08:00');
      expect(habits.first.isCompletedToday, true);

      // Toggle check-in back to false
      await repo.toggleCheckIn(id);
      expect(habits.first.isCompletedToday, false);

      // Delete habit
      await repo.deleteHabit(id);
      expect(habits.isEmpty, true);

      // Restore habit
      await repo.restoreHabit(habit);
      expect(habits.length, 1);
      expect(habits.first.id, id);
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
