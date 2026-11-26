import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit_model.dart';
import '../notifiers/habit_notifier.dart';
import '../notifiers/today_notifier.dart';
import '../services/notification_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/edit_habit_bottom_sheet.dart';

/// Halaman Pengingat (dibuka dari ikon lonceng di Dashboard).
///
/// Menampilkan rutinitas yang punya jam pengingat beserta statusnya hari
/// ini, rutinitas yang belum punya pengingat (ketuk untuk mengaturnya), dan
/// tombol untuk memeriksa izin notifikasi.
class ReminderScreen extends ConsumerWidget {
  const ReminderScreen({super.key, this.notificationService});

  /// Dapat diganti di tes; default singleton NotificationService.
  final NotificationService? notificationService;

  static const _navy = Color(0xFF1E293B);

  /// "HH:mm" -> menit sejak 00:00; `null` jika format tidak valid.
  static int? minutesOf(String? time) {
    final parts = (time ?? '').trim().split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return h * 60 + m;
  }

  /// Hari terjadwal berikutnya setelah [now]: "besok" atau nama hari
  /// singkat (mis. "Rab") untuk rutinitas dengan jadwal hari tertentu.
  static String nextDayLabel(HabitModel habit, DateTime now) {
    for (var k = 1; k <= 7; k++) {
      final day = DateTime(now.year, now.month, now.day + k);
      if (habit.isScheduledOn(day)) {
        return k == 1 ? 'besok' : HabitModel.dayShortNames[day.weekday - 1];
      }
    }
    return 'besok';
  }

  /// Status pengingat sebuah rutinitas pada waktu [now].
  static String statusOf(HabitModel habit, DateTime now) {
    final time = habit.reminderTime!.trim();
    final next = nextDayLabel(habit, now);
    if (!habit.isScheduledOn(now) && !habit.isCompletedOn(now)) {
      return 'Libur hari ini · berikutnya $next $time';
    }
    if (habit.isCompletedOn(now)) {
      return 'Selesai hari ini · berbunyi lagi $next $time';
    }
    final minutes = minutesOf(time)!;
    if (now.hour * 60 + now.minute >= minutes) {
      return 'Sudah lewat hari ini · berikutnya $next $time';
    }
    return 'Hari ini pukul $time';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitState = ref.watch(habitNotifierProvider);
    ref.watch(todayProvider); // gambar ulang saat hari berganti
    final now = ref.watch(clockProvider)();

    return Scaffold(
      key: const Key('reminder_screen'),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pengingat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _navy,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: habitState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Gagal memuat rutinitas')),
        data: (habits) => _buildContent(context, habits, now),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<HabitModel> habits,
    DateTime now,
  ) {
    final scheduled = habits
        .where((h) => minutesOf(h.reminderTime) != null)
        .toList()
      ..sort((a, b) =>
          minutesOf(a.reminderTime)!.compareTo(minutesOf(b.reminderTime)!));
    final withoutReminder =
        habits.where((h) => minutesOf(h.reminderTime) == null).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (habits.isEmpty)
          const Padding(
            key: Key('reminder_empty'),
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'Belum ada rutinitas.\nTambahkan rutinitas di tab Tugas, lalu atur jam pengingatnya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        if (scheduled.isNotEmpty) ...[
          _sectionTitle('Terjadwal (${scheduled.length})'),
          for (final habit in scheduled)
            _ReminderTile(
              key: Key('reminder_item_${habit.id}'),
              habit: habit,
              icon: habit.isCompletedOn(now)
                  ? Icons.check_circle_outline
                  : Icons.notifications_active_outlined,
              iconColor: habit.isCompletedOn(now)
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF3B82F6),
              subtitle: statusOf(habit, now),
              onTap: () => _openEdit(context, habit),
            ),
        ],
        if (withoutReminder.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionTitle('Tanpa pengingat (${withoutReminder.length})'),
          for (final habit in withoutReminder)
            _ReminderTile(
              key: Key('reminder_item_${habit.id}'),
              habit: habit,
              icon: Icons.notifications_off_outlined,
              iconColor: const Color(0xFF94A3B8),
              subtitle: 'Ketuk untuk mengatur jam pengingat',
              onTap: () => _openEdit(context, habit),
            ),
        ],
        const SizedBox(height: 20),
        OutlinedButton.icon(
          key: const Key('reminder_permission_button'),
          icon: const Icon(Icons.notifications_outlined),
          label: const Text('Periksa izin notifikasi'),
          onPressed: () async {
            await (notificationService ?? NotificationService())
                .requestPermission();
            if (!context.mounted) return;
            showAppSnackBar(
              context,
              'Izin notifikasi sudah diperiksa. Jika notifikasi belum muncul, '
              'aktifkan di Pengaturan HP → Aplikasi → RutinKu → Notifikasi.',
            );
          },
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFF64748B),
          ),
        ),
      );

  void _openEdit(BuildContext context, HabitModel habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EditHabitBottomSheet(habit: habit),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    super.key,
    required this.habit,
    required this.icon,
    required this.iconColor,
    required this.subtitle,
    required this.onTap,
  });

  final HabitModel habit;
  final IconData icon;
  final Color iconColor;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor),
        title: Text(
          habit.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
      ),
    );
  }
}
