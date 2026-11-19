import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/notifiers/habit_notifier.dart';
import 'package:rutinku_flutter/repositories/habit_repository.dart';

/// Issue #5: nama kebiasaan kosong/tak terlihat harus ditolak juga di
/// lapisan state (HabitNotifier), bukan hanya oleh validator form.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late HabitNotifier notifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
    await container.read(habitNotifierProvider.future);
    notifier = container.read(habitNotifierProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('addHabit menolak nama kosong, spasi, dan karakter tak terlihat',
      () async {
    for (final title in ['', '     ', '​​​', 'ㅤㅤ']) {
      await expectLater(notifier.addHabit(title), throwsException);
    }
    expect(await HabitRepository().fetchHabits(), isEmpty);
  });

  test('addHabit menyimpan nama yang sudah dirapikan', () async {
    await notifier.addHabit('  Minum   Air​  ');

    final habits = await HabitRepository().fetchHabits();
    expect(habits.single.title, 'Minum Air');
  });

  test('updateHabit menolak nama tak terlihat dan data lama tetap utuh',
      () async {
    await notifier.addHabit('Baca Buku');
    final HabitModel habit = (await HabitRepository().fetchHabits()).single;

    await expectLater(
      notifier.updateHabit(habit.id, '​​​', 'Belajar', ''),
      throwsException,
    );

    final habits = await HabitRepository().fetchHabits();
    expect(habits.single.title, 'Baca Buku');
  });
}
