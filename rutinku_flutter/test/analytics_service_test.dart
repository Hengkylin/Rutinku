import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/services/analytics_service.dart';

/// Tanggal acuan tetap agar hasil tes tidak bergantung pada hari dijalankan.
/// 11 Nov 2026 = Rabu. Offset hari (i hari lalu) → nama hari:
///   0 Rab, 1 Sel, 2 Sen, 3 Min, 4 Sab, 5 Jum, 6 Kam, 7 Rab, 8 Sel, ...
/// Selasa dalam 28 hari terakhir: i = 1, 8, 15, 22.
/// Kamis  dalam 28 hari terakhir: i = 6, 13, 20, 27.
final now = DateTime(2026, 11, 11);

String daysAgo(int i) =>
    DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, now.day - i));

HabitRecord record(int i, String status, {int currentValue = 0}) =>
    HabitRecord(date: daysAgo(i), status: status, currentValue: currentValue);

const tuesdays = {1, 8, 15, 22};
const thursdays = {6, 13, 20, 27};

/// Konsisten: selesai setiap hari selama 30 hari terakhir.
/// 30 hari: 30/30 = 100%. Minggu ini 7/7, minggu lalu 7/7.
final minumAir = HabitModel(
  id: 'minum-air',
  title: 'Minum Air',
  records: [for (var i = 0; i < 30; i++) record(i, 'completed')],
);

/// Sering gagal di hari Selasa: dilewati tiap Selasa (4x dalam 28 hari),
/// selesai di hari lain. Tidak ada record untuk i = 28, 29.
/// 30 hari: 24/30 = 80%. Minggu ini 6/7, minggu lalu 6/7.
final olahraga = HabitModel(
  id: 'olahraga',
  title: 'Olahraga',
  records: [
    for (var i = 0; i < 28; i++)
      record(i, tuesdays.contains(i) ? 'skipped' : 'completed'),
  ],
);

/// Minggu lalu lebih buruk: minggu ini 7/7, minggu lalu hanya 2/7
/// (selesai i = 7 Rab & 8 Sel; pending i = 9..13 → Sen, Min, Sab, Jum, Kam).
/// Jebakan: 5 kegagalan hari Rabu di luar jendela 4 minggu (i = 35..63)
/// yang tidak boleh ikut dihitung.
/// 30 hari: 9/30 = 30%.
final membaca = HabitModel(
  id: 'membaca',
  title: 'Membaca',
  records: [
    for (var i = 0; i <= 8; i++) record(i, 'completed'),
    for (var i = 9; i <= 13; i++) record(i, 'pending'),
    for (final i in [35, 42, 49, 56, 63]) record(i, 'skipped'),
  ],
);

/// Jebakan: libur (rest) tiap Kamis. Rest bukan kegagalan; jika ikut
/// dihitung, Kamis (4 + 1 dari Membaca = 5) akan mengalahkan Selasa (4).
/// 30 hari: 0%. Minggu ini 0/7, minggu lalu 0/7.
final meditasi = HabitModel(
  id: 'meditasi',
  title: 'Meditasi',
  records: [for (final i in thursdays) record(i, 'rest')],
);

void main() {
  final habits = [olahraga, membaca, meditasi, minumAir];
  final service = AnalyticsService(habits, now: now);

  group('getMostConsistentHabit', () {
    test('mengembalikan habit dengan persentase penyelesaian 30 hari tertinggi',
        () {
      expect(service.completionRate(minumAir, startDaysAgo: 0, days: 30), 100);
      expect(service.completionRate(olahraga, startDaysAgo: 0, days: 30), 80);
      expect(service.completionRate(membaca, startDaysAgo: 0, days: 30), 30);
      expect(service.completionRate(meditasi, startDaysAgo: 0, days: 30), 0);

      expect(service.getMostConsistentHabit()?.title, 'Minum Air');
    });

    test('jika persentase sama, streak tertinggi yang menang', () {
      // Sama-sama 10/30 hari, tetapi hanya "Baru" yang punya streak (10 hari).
      final lama = HabitModel(
        id: 'lama',
        title: 'Lama',
        records: [for (var i = 20; i < 30; i++) record(i, 'completed')],
      );
      final baru = HabitModel(
        id: 'baru',
        title: 'Baru',
        records: [for (var i = 0; i < 10; i++) record(i, 'completed')],
      );

      final result =
          AnalyticsService([lama, baru], now: now).getMostConsistentHabit();

      expect(lama.streakCountOn(now), 0);
      expect(baru.streakCountOn(now), 10);
      expect(result?.title, 'Baru');
    });

    test('list kosong mengembalikan null', () {
      expect(AnalyticsService([], now: now).getMostConsistentHabit(), isNull);
    });
  });

  group('getMostMissedDay', () {
    test('mengembalikan hari dengan kegagalan terbanyak dalam 4 minggu', () {
      // Selasa: 4 (Olahraga). Sen/Min/Sab/Jum/Kam: masing-masing 1 (Membaca).
      // Rest (Meditasi) dan kegagalan di luar 28 hari tidak dihitung.
      expect(service.getMostMissedDay(), 'Selasa');
    });

    test('record progresif di bawah target dihitung gagal', () {
      final air = HabitModel(
        id: 'air',
        title: 'Air',
        targetValue: 8,
        records: [
          record(6, 'pending', currentValue: 3), // Kamis, belum capai target
          record(1, 'completed', currentValue: 8), // Selasa, selesai
        ],
      );

      expect(AnalyticsService([air], now: now).getMostMissedDay(), 'Kamis');
    });

    test('tanpa kegagalan mengembalikan null', () {
      expect(AnalyticsService([minumAir], now: now).getMostMissedDay(), isNull);
      expect(AnalyticsService([], now: now).getMostMissedDay(), isNull);
    });
  });

  group('getWeeklyProgressComparison', () {
    test('selisih persentase 7 hari terakhir vs 7 hari sebelumnya', () {
      // Minggu ini  (i 0..6) : 7 + 6 + 7 + 0 = 20 dari 4 x 7 = 28 → 71,43%
      // Minggu lalu (i 7..13): 7 + 6 + 2 + 0 = 15 dari 28          → 53,57%
      // Selisih = 5/28 x 100 = +17,857...
      expect(service.getWeeklyProgressComparison(), closeTo(500 / 28, 1e-9));
    });

    test('getWeeklyCompletionRates mengembalikan persentase tiap minggu', () {
      final rates = service.getWeeklyCompletionRates();
      expect(rates.thisWeek, closeTo(2000 / 28, 1e-9)); // 20/28
      expect(rates.lastWeek, closeTo(1500 / 28, 1e-9)); // 15/28
    });

    test('bernilai negatif jika minggu ini lebih buruk', () {
      // Minggu ini 1/7, minggu lalu 7/7 → (1 - 7)/7 x 100 = -85,71...
      final turun = HabitModel(
        id: 'turun',
        title: 'Turun',
        records: [
          record(0, 'completed'),
          for (var i = 7; i < 14; i++) record(i, 'completed'),
        ],
      );

      expect(
        AnalyticsService([turun], now: now).getWeeklyProgressComparison(),
        closeTo(-600 / 7, 1e-9),
      );
    });

    test('list kosong mengembalikan 0', () {
      expect(AnalyticsService([], now: now).getWeeklyProgressComparison(), 0);
    });
  });
}
