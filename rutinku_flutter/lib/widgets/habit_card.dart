import 'package:flutter/material.dart';

import '../models/habit_model.dart';
import 'edit_habit_bottom_sheet.dart';

class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final String? parentName;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  const HabitCard({
    super.key,
    required this.habit,
    this.parentName,
    required this.onToggle,
    required this.onLongPress,
  });

  // Fungsi pembantu sementara untuk mencocokkan ikon berdasarkan teks judul
  // (Nantinya data ini sebaiknya dimasukkan ke dalam HabitModel)
  IconData _getIconData(String title) {
    final t = title.toLowerCase();
    if (t.contains('air')) return Icons.water_drop_outlined;
    if (t.contains('jalan')) return Icons.directions_walk;
    if (t.contains('tidur')) return Icons.dark_mode_outlined;
    return Icons.menu_book_outlined;
  }

  // Fungsi pembantu warna latar ikon
  Color _getIconBackgroundColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('air')) return const Color(0xFFFFF1ED); // Light orange/peach
    if (t.contains('jalan')) return const Color(0xFFF0FDF4); // Light green
    if (t.contains('tidur')) return const Color(0xFFF5F3FF); // Light purple
    return const Color(0xFFEFF6FF); // Light blue
  }

  // Fungsi pembantu warna ikon
  Color _getIconColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('air')) return const Color(0xFFFB923C);
    if (t.contains('jalan')) return const Color(0xFF4ADE80);
    if (t.contains('tidur')) return const Color(0xFFA78BFA);
    return const Color(0xFF60A5FA);
  }

  @override
  Widget build(BuildContext context) {
    final todayRecord = habit.todayRecord;
    final status = todayRecord?.status;
    final isCompleted = status == 'completed';
    final isSkipped = status == 'skipped';
    final isRest = status == 'rest';
    final todayMood = todayRecord?.mood;

    // Gunakan reminderTime jika ada, atau fallback ke mock data
    final mockTime = habit.reminderTime != null && habit.reminderTime!.isNotEmpty
        ? habit.reminderTime!
        : (habit.title.toLowerCase().contains('air')
            ? 'Sepanjang hari'
            : '07:00');

    // Penyesuaian warna kartu berdasarkan status hari ini
    Color cardBgColor = Colors.white;
    Color cardBorderColor = Colors.grey.shade200;
    if (isRest) {
      cardBgColor = const Color(0xFFF8FAFC);
      cardBorderColor = const Color(0xFFCBD5E1);
    } else if (isSkipped) {
      cardBgColor = const Color(0xFFF8FAFC);
      cardBorderColor = const Color(0xFFE2E8F0);
    }

    return GestureDetector(
      onLongPress: onLongPress, // Tahan lama untuk memunculkan aksi
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorderColor, width: 1.5),
        ),
        child: Row(
          children: [
            // 1. Ikon Sebelah Kiri
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isRest
                    ? const Color(0xFFE2E8F0)
                    : _getIconBackgroundColor(habit.title),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isRest ? Icons.hotel_outlined : _getIconData(habit.title),
                color: isRest
                    ? const Color(0xFF64748B)
                    : _getIconColor(habit.title),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),

            // 2. Teks Judul dan Informasi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (parentName != null && parentName!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.subdirectory_arrow_right,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Sesudah: $parentName',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          habit.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isCompleted || isSkipped || isRest
                                ? Colors.grey.shade500
                                : const Color(0xFF334155),
                            decoration: (isCompleted || isSkipped)
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRest) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Libur',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ] else if (isSkipped) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Dilewati',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Progress mingguan
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: habit.weeklyProgress,
                            minHeight: 4,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              habit.weeklyProgress >= 1.0
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(habit.weeklyProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mockTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (habit.streakCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFFEDD5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 10)),
                              const SizedBox(width: 3),
                              Text(
                                '${habit.streakCount} hari',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (todayMood != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE9D5FF),
                            ),
                          ),
                          child: Text(
                            todayMood,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Tombol Ikon Pensil (Edit)
            IconButton(
              icon: Icon(
                Icons.edit,
                color: Colors.grey.shade400,
                size: 20,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: EditHabitBottomSheet(habit: habit),
                  ),
                );
              },
            ),

            // 3. Tombol Status / Check-in Kanan
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFD9F99D)
                      : (isRest
                          ? const Color(0xFFE2E8F0)
                          : (isSkipped
                              ? const Color(0xFFFEE2E2)
                              : Colors.grey.shade100)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check
                      : (isRest
                          ? Icons.hotel_outlined
                          : (isSkipped
                              ? Icons.skip_next_outlined
                              : Icons.check)),
                  color: isCompleted
                      ? Colors.black87
                      : (isRest
                          ? const Color(0xFF475569)
                          : (isSkipped
                              ? const Color(0xFFDC2626)
                              : Colors.grey.shade400)),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
