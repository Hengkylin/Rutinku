import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutinku_flutter/repositories/habit_repository.dart';
import 'package:rutinku_flutter/services/notification_service.dart';

class MockNotificationService extends Mock implements NotificationService {}

/// Issue #7: pengingat harian tidak boleh muncul lagi untuk hari yang
/// rutinitasnya sudah selesai; jadwal mulai besok (skipToday: true).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNotificationService notifications;
  late HabitRepository repository;
  final now = DateTime(2026, 11, 20, 9, 0);

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
    when(() => notifications.cancelReminder(any())).thenAnswer((_) async {});
    repository = HabitRepository(
      notificationService: notifications,
      clock: () => now,
    );
  });

  /// Nilai skipToday pada panggilan scheduleDailyReminder terakhir.
  bool lastSkipToday() {
    final calls = verify(() => notifications.scheduleDailyReminder(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
          skipToday: captureAny(named: 'skipToday'),
        )).captured;
    return calls.last as bool;
  }

  Future<String> addHabitWithReminder({int targetValue = 1}) async {
    await repository.addHabit('Minum Air',
        reminderTime: '20:00', targetValue: targetValue);
    clearInteractions(notifications);
    return (await repository.fetchHabits()).single.id;
  }

  test('check-in hari ini menjadwalkan ulang pengingat mulai besok', () async {
    final id = await addHabitWithReminder();

    await repository.toggleCheckIn(id, now);

    expect(lastSkipToday(), isTrue);
  });

  test('membatalkan check-in hari ini mengaktifkan lagi pengingat hari ini',
      () async {
    final id = await addHabitWithReminder();
    await repository.toggleCheckIn(id, now);
    clearInteractions(notifications);

    await repository.toggleCheckIn(id, now);

    expect(lastSkipToday(), isFalse);
  });

  test('habit progresif: pengingat dilewati hanya saat target tercapai',
      () async {
    final id = await addHabitWithReminder(targetValue: 2);

    await repository.incrementHabitProgress(id, now);
    expect(lastSkipToday(), isFalse);

    clearInteractions(notifications);
    await repository.incrementHabitProgress(id, now);
    expect(lastSkipToday(), isTrue);
  });

  test('menyimpan foto momen hari ini (status completed) melewati pengingat',
      () async {
    final id = await addHabitWithReminder();

    await repository.saveMomentImage(id, now, '/tmp/foto.jpg');

    expect(lastSkipToday(), isTrue);
  });

  test('check-in tanggal lain tidak mengubah jadwal pengingat', () async {
    final id = await addHabitWithReminder();

    await repository.toggleCheckIn(id, now.subtract(const Duration(days: 1)));

    verifyNever(() => notifications.scheduleDailyReminder(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
          skipToday: any(named: 'skipToday'),
        ));
  });

  test('rutinitas tanpa jam pengingat tidak menjadwalkan apa pun', () async {
    await repository.addHabit('Baca Buku');
    final id = (await repository.fetchHabits()).single.id;

    await repository.toggleCheckIn(id, now);

    verifyNever(() => notifications.scheduleDailyReminder(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
          skipToday: any(named: 'skipToday'),
        ));
  });
}
