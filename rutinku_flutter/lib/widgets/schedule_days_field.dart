import 'package:flutter/material.dart';

import '../models/habit_model.dart';

/// Pilihan hari jadwal rutinitas (Sen..Min), dipakai bersama oleh form
/// tambah dan edit rutinitas.
///
/// Nilai = daftar hari terpilih memakai `DateTime.weekday` (1 = Senin ...
/// 7 = Minggu). Ketujuh hari terpilih berarti "setiap hari"; `HabitModel`
/// menyimpannya sebagai list kosong. Minimal satu hari wajib dipilih.
class ScheduleDaysField extends StatelessWidget {
  const ScheduleDaysField({
    super.key,
    required this.initialDays,
    required this.onChanged,
    this.enabled = true,
  });

  /// Hari yang terpilih di awal (semua 7 hari = setiap hari).
  final List<int> initialDays;
  final ValueChanged<List<int>> onChanged;
  final bool enabled;

  static const List<int> allDays = [1, 2, 3, 4, 5, 6, 7];
  static const List<int> weekdays = [1, 2, 3, 4, 5];
  static const List<int> weekend = [6, 7];

  /// Hari terpilih awal untuk sebuah rutinitas (harian -> semua hari).
  static List<int> initialFor(HabitModel habit) =>
      habit.isDaily ? List.of(allDays) : List.of(habit.scheduledDays);

  static String? validate(List<int>? days) =>
      (days == null || days.isEmpty) ? 'Pilih minimal 1 hari' : null;

  /// Ringkasan pilihan, mis. "Setiap hari" atau "Sen, Rab, Jum".
  static String summary(List<int> days) {
    final normalized = HabitModel.normalizeScheduledDays(days);
    if (days.isEmpty) return '';
    if (normalized.isEmpty) return 'Setiap hari';
    return normalized.map((d) => HabitModel.dayShortNames[d - 1]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<int>>(
      key: const Key('schedule_days_field'),
      initialValue: initialDays,
      validator: validate,
      builder: (state) {
        final selected = state.value ?? const <int>[];
        void setDays(Iterable<int> days) {
          final sorted = days.toSet().toList()..sort();
          state.didChange(sorted);
          onChanged(sorted);
        }

        Widget preset(String key, String label, List<int> days) {
          final active = selected.length == days.length &&
              days.every(selected.contains);
          return ChoiceChip(
            key: Key(key),
            label: Text(label),
            selected: active,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            selectedColor: const Color(0xFFE2E8F0),
            onSelected: enabled ? (_) => setDays(days) : null,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    key: Key('schedule_day_$day'),
                    label: Text(HabitModel.dayShortNames[day - 1]),
                    selected: selected.contains(day),
                    showCheckmark: false,
                    selectedColor: const Color(0xFFD9F99D),
                    onSelected: enabled
                        ? (on) => setDays(on
                            ? [...selected, day]
                            : selected.where((d) => d != day))
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                preset('schedule_preset_daily', 'Setiap hari', allDays),
                preset('schedule_preset_weekdays', 'Hari kerja', weekdays),
                preset('schedule_preset_weekend', 'Akhir pekan', weekend),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              state.hasError ? state.errorText! : summary(selected),
              key: const Key('schedule_days_summary'),
              style: TextStyle(
                fontSize: 12,
                color: state.hasError
                    ? Theme.of(context).colorScheme.error
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        );
      },
    );
  }
}
