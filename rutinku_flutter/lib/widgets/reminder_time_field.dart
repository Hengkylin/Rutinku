import 'package:flutter/material.dart';

/// Input jam pengingat harian per rutinitas (issue #9), dipakai bersama oleh
/// form tambah dan edit rutinitas.
///
/// - Jam dipilih lewat [showTimePicker]; picker dibuka di jam yang sudah
///   tersimpan (bukan jam sekarang) agar mudah digeser sedikit.
/// - Tombol silang menghapus pengingat. Nilai kosong berarti tanpa
///   pengingat, dan [HabitRepository] membatalkan notifikasinya.
/// - Nilai disimpan sebagai teks "HH:mm" di [controller].
class ReminderTimeField extends StatelessWidget {
  const ReminderTimeField({
    super.key,
    required this.controller,
    required this.decoration,
    this.enabled = true,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final bool enabled;

  /// Format jam pengingat yang disimpan di [HabitModel.reminderTime].
  static String format(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Membaca teks "HH:mm"; null jika kosong atau tidak valid.
  static TimeOfDay? parse(String? value) {
    final parts = (value ?? '').trim().split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: parse(controller.text) ?? TimeOfDay.now(),
      helpText: 'Pilih jam pengingat',
    );
    if (picked != null) controller.text = format(picked);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final time = value.text.trim();
        final hasReminder = time.isNotEmpty;
        return TextFormField(
          key: const Key('reminder_time_field'),
          controller: controller,
          enabled: enabled,
          readOnly: true,
          onTap: () => _pickTime(context),
          decoration: decoration.copyWith(
            hintText: 'Tanpa pengingat',
            prefixIcon: Icon(
              hasReminder
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              size: 20,
            ),
            suffixIcon: hasReminder && enabled
                ? IconButton(
                    key: const Key('reminder_time_clear'),
                    tooltip: 'Hapus pengingat',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: controller.clear,
                  )
                : null,
            helperText: hasReminder
                ? 'Notifikasi muncul setiap hari pukul $time'
                : 'Ketuk untuk memilih jam notifikasi rutinitas ini',
          ),
        );
      },
    );
  }
}
