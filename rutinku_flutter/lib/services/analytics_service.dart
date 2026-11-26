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
        // Hari di luar jadwal rutinitas bukan kegagalan.
        if (!habit.isScheduledOn(date)) continue;
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
    final rates = getWeeklyCompletionRates();
    return rates.thisWeek - rates.lastWeek;
  }

  /// Persentase penyelesaian gabungan (0–100) untuk 7 hari terakhir
  /// ([thisWeek]) dan 7 hari sebelumnya ([lastWeek]).
  ({double thisWeek, double lastWeek}) getWeeklyCompletionRates() {
    return (
      thisWeek: _overallCompletionRate(startDaysAgo: 0, days: weekLength),
      lastWeek:
          _overallCompletionRate(startDaysAgo: weekLength, days: weekLength),
    );
  }

  /// Persentase (0–100) hari selesai untuk [habit] dalam [days] hari,
  /// mundur mulai dari [startDaysAgo] hari sebelum [now]. Hanya hari yang
  /// dijadwalkan yang dihitung (jadwal Sen/Rab/Jum -> pembagi 3 per minggu).
  double completionRate(
    HabitModel habit, {
    required int startDaysAgo,
    required int days,
  }) {
    final scheduled = _scheduledDays(habit, startDaysAgo, days);
    if (scheduled == 0) return 0;
    return _completedDays(habit, startDaysAgo, days) / scheduled * 100;
  }

  /// Persentase gabungan semua habit: total (habit, hari terjadwal) yang
  /// selesai dibagi total (habit, hari terjadwal).
  double _overallCompletionRate({required int startDaysAgo, required int days}) {
    if (habits.isEmpty || days <= 0) return 0;
    var completed = 0;
    var scheduled = 0;
    for (final habit in habits) {
      completed += _completedDays(habit, startDaysAgo, days);
      scheduled += _scheduledDays(habit, startDaysAgo, days);
    }
    if (scheduled == 0) return 0;
    return completed / scheduled * 100;
  }

  /// Jumlah hari terjadwal yang selesai.
  int _completedDays(HabitModel habit, int startDaysAgo, int days) {
    var count = 0;
    for (var i = startDaysAgo; i < startDaysAgo + days; i++) {
      final day = _daysAgo(i);
      if (habit.isScheduledOn(day) && habit.isCompletedOn(day)) count++;
    }
    return count;
  }

  /// Jumlah hari yang dijadwalkan untuk [habit] dalam rentang tersebut.
  int _scheduledDays(HabitModel habit, int startDaysAgo, int days) {
    var count = 0;
    for (var i = startDaysAgo; i < startDaysAgo + days; i++) {
      if (habit.isScheduledOn(_daysAgo(i))) count++;
    }
    return count;
  }

  /// Aritmetika kalender (bukan `Duration`) agar aman dari pergeseran DST.
  DateTime _daysAgo(int days) => DateTime(now.year, now.month, now.day - days);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
