import '../models/habit_model.dart';

/// Analitik kebiasaan (logika data murni, tanpa UI maupun penyimpanan).
///
/// Semua perhitungan memakai tanggal acuan [now] (default: hari ini) dan
/// definisi "selesai" dari `HabitModel.isCompletedOn()`, sehingga habit
/// progresif (`targetValue > 1`) ikut dihitung dengan benar.
class AnalyticsService {
  AnalyticsService(this.habits, {DateTime? now})
      : now = _dateOnly(now ?? DateTime.now());

  final List<HabitModel> habits;
  final DateTime now;

  static const int consistencyWindowDays = 30;
  static const int missedDayWindowDays = 28; // 4 minggu
  static const int weekLength = 7;

  /// Nama hari sesuai `DateTime.weekday` (1 = Senin ... 7 = Minggu).
  static const List<String> dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  /// Habit dengan persentase penyelesaian tertinggi dalam 30 hari terakhir.
  /// Jika sama, dipilih yang streak-nya (per [now]) lebih tinggi; jika masih
  /// sama, yang lebih dulu ada di list. `null` jika tidak ada habit.
  HabitModel? getMostConsistentHabit() {
    HabitModel? best;
    var bestRate = -1.0;
    var bestStreak = -1;

    for (final habit in habits) {
      final rate =
          completionRate(habit, startDaysAgo: 0, days: consistencyWindowDays);
      final streak = habit.streakCountOn(now);
      if (rate > bestRate || (rate == bestRate && streak > bestStreak)) {
        best = habit;
        bestRate = rate;
        bestStreak = streak;
      }
    }
    return best;
  }

  /// Nama hari (mis. "Selasa") dengan kegagalan terbanyak dalam 4 minggu
  /// terakhir. Kegagalan = record yang tidak selesai menurut
  /// `isCompletedOn()`; hari libur (`'rest'`) tidak dihitung gagal.
  /// Jika seri, dipilih hari paling awal dalam urutan Senin–Minggu.
  /// `null` jika tidak ada kegagalan.
  String? getMostMissedDay() {
    final windowStart = _daysAgo(missedDayWindowDays - 1);
    final missedPerWeekday = List<int>.filled(7, 0);

    for (final habit in habits) {
      for (final record in habit.records) {
        final date = DateTime.tryParse(record.date);
        if (date == null || date.isBefore(windowStart) || date.isAfter(now)) {
          continue;
        }
        if (record.status == 'rest' || habit.isCompletedOn(date)) continue;
        missedPerWeekday[date.weekday - 1]++;
      }
    }

    var maxIndex = -1;
    for (var i = 0; i < missedPerWeekday.length; i++) {
      if (missedPerWeekday[i] > 0 &&
          (maxIndex == -1 || missedPerWeekday[i] > missedPerWeekday[maxIndex])) {
        maxIndex = i;
      }
    }
    return maxIndex == -1 ? null : dayNames[maxIndex];
  }

  /// Selisih persentase penyelesaian semua habit: 7 hari terakhir
  /// (hari ke-1..7, termasuk hari ini) dikurangi 7 hari sebelumnya
  /// (hari ke-8..14). Positif = membaik, negatif = menurun.
  double getWeeklyProgressComparison() {
    final thisWeek = _overallCompletionRate(startDaysAgo: 0, days: weekLength);
    final lastWeek =
        _overallCompletionRate(startDaysAgo: weekLength, days: weekLength);
    return thisWeek - lastWeek;
  }

  /// Persentase (0–100) hari selesai untuk [habit] dalam [days] hari,
  /// mundur mulai dari [startDaysAgo] hari sebelum [now].
  double completionRate(
    HabitModel habit, {
    required int startDaysAgo,
    required int days,
  }) {
    if (days <= 0) return 0;
    return _completedDays(habit, startDaysAgo, days) / days * 100;
  }

  /// Persentase gabungan semua habit: total (habit, hari) yang selesai
  /// dibagi jumlah habit × [days].
  double _overallCompletionRate({required int startDaysAgo, required int days}) {
    if (habits.isEmpty || days <= 0) return 0;
    final completed = habits.fold<int>(
      0,
      (sum, habit) => sum + _completedDays(habit, startDaysAgo, days),
    );
    return completed / (habits.length * days) * 100;
  }

  int _completedDays(HabitModel habit, int startDaysAgo, int days) {
    var count = 0;
    for (var i = startDaysAgo; i < startDaysAgo + days; i++) {
      if (habit.isCompletedOn(_daysAgo(i))) count++;
    }
    return count;
  }

  /// Aritmetika kalender (bukan `Duration`) agar aman dari pergeseran DST.
  DateTime _daysAgo(int days) => DateTime(now.year, now.month, now.day - days);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
