import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit_model.dart';
import '../notifiers/habit_notifier.dart';
import '../services/analytics_service.dart';

/// Halaman Analitik: hanya menampilkan hasil dari [AnalyticsService].
/// Seluruh perhitungan ada di service, bukan di widget ini.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  static const _navy = Color(0xFF1E293B);
  static const _slate = Color(0xFF64748B);
  static const _positive = Color(0xFF16A34A);
  static const _negative = Color(0xFFDC2626);

  /// Teks selisih, mis. "+17,9% dari minggu lalu" atau "-5% dari minggu lalu".
  static String formatProgressDelta(double delta) {
    if (delta.abs() < 0.05) return 'Sama dengan minggu lalu';
    final sign = delta > 0 ? '+' : '-';
    return '$sign${_formatPercent(delta.abs())} dari minggu lalu';
  }

  /// 17.857 → "17,9%", 100.0 → "100%".
  static String _formatPercent(double value) {
    final fixed = value.toStringAsFixed(1);
    final trimmed = fixed.endsWith('.0')
        ? fixed.substring(0, fixed.length - 2)
        : fixed;
    return '${trimmed.replaceAll('.', ',')}%';
  }

  static Color _deltaColor(double delta) {
    if (delta.abs() < 0.05) return _slate;
    return delta > 0 ? _positive : _negative;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitState = ref.watch(habitNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Analitik Kebiasaan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: _navy,
        elevation: 0,
      ),
      body: habitState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _buildMessage(
          icon: Icons.error_outline_rounded,
          title: 'Gagal memuat data',
          subtitle: 'Coba buka kembali halaman ini.',
        ),
        data: (habits) => habits.isEmpty
            ? _buildMessage(
                icon: Icons.insights_rounded,
                title: 'Belum ada data analitik',
                subtitle:
                    'Tambahkan kebiasaan di tab Tugas dan lakukan check-in '
                    'untuk melihat perkembanganmu di sini.',
              )
            : _buildContent(AnalyticsService(habits)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Konten
  // ---------------------------------------------------------------------------

  Widget _buildContent(AnalyticsService service) {
    final consistent = service.getMostConsistentHabit();
    final missedDay = service.getMostMissedDay();
    final rates = service.getWeeklyCompletionRates();
    final delta = service.getWeeklyProgressComparison();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Ringkasan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildConsistentCard(service, consistent)),
              const SizedBox(width: 12),
              Expanded(child: _buildMissedDayCard(missedDay)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildWeeklySection(rates, delta),
      ],
    );
  }

  Widget _buildConsistentCard(
    AnalyticsService service,
    HabitModel? habit,
  ) {
    final rate = habit == null
        ? null
        : service.completionRate(
            habit,
            startDaysAgo: 0,
            days: AnalyticsService.consistencyWindowDays,
          );
    return _SummaryCard(
      key: const Key('analytics_most_consistent'),
      icon: Icons.emoji_events_rounded,
      iconColor: const Color(0xFFCA8A04),
      iconBackground: const Color(0xFFFEF9C3),
      label: 'Kebiasaan Paling Konsisten',
      value: habit?.title ?? '-',
      caption: rate == null
          ? 'Belum ada data'
          : '${_formatPercent(rate)} selesai dalam '
              '${AnalyticsService.consistencyWindowDays} hari',
    );
  }

  Widget _buildMissedDayCard(String? missedDay) {
    return _SummaryCard(
      key: const Key('analytics_most_missed_day'),
      icon: Icons.event_busy_rounded,
      iconColor: _negative,
      iconBackground: const Color(0xFFFEE2E2),
      label: 'Hari Sering Terlewat',
      value: missedDay ?? 'Tidak ada',
      caption: missedDay == null
          ? 'Tidak ada yang terlewat dalam 4 minggu'
          : 'Paling sering gagal dalam 4 minggu terakhir',
    );
  }

  Widget _buildWeeklySection(
    ({double thisWeek, double lastWeek}) rates,
    double delta,
  ) {
    final deltaColor = _deltaColor(delta);
    final deltaIcon = delta.abs() < 0.05
        ? Icons.trending_flat_rounded
        : (delta > 0
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Komparasi Mingguan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Persentase check-in selesai dari semua kebiasaan',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _WeeklyBarChart(
              lastWeek: rates.lastWeek,
              thisWeek: rates.thisWeek,
              formatPercent: _formatPercent,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(deltaIcon, color: deltaColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatProgressDelta(delta),
                  key: const Key('analytics_weekly_delta'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: deltaColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: _slate),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  static BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

/// Kartu ringkasan berikon (dipakai untuk kedua kartu di bagian atas).
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AnalyticsScreen._cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AnalyticsScreen._slate,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AnalyticsScreen._navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// Grafik 2 batang: "Minggu Lalu" vs "Minggu Ini" (skala 0–100%).
class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({
    required this.lastWeek,
    required this.thisWeek,
    required this.formatPercent,
  });

  final double lastWeek;
  final double thisWeek;
  final String Function(double) formatPercent;

  static const _labels = ['Minggu Lalu', 'Minggu Ini'];

  @override
  Widget build(BuildContext context) {
    final values = [lastWeek, thisWeek];
    final colors = [const Color(0xFFCBD5E1), AnalyticsScreen._navy];

    return BarChart(
      key: const Key('analytics_weekly_chart'),
      BarChartData(
        minY: 0,
        maxY: 100,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: const BarTouchData(enabled: false),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 25,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= values.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatPercent(values[index]),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AnalyticsScreen._navy,
                        ),
                      ),
                      Text(
                        _labels[index],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  width: 40,
                  color: colors[i],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: const Color(0xFFF1F5F9),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
