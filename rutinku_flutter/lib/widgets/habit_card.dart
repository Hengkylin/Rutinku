import 'package:flutter/material.dart';

import '../models/habit_model.dart';
import 'edit_habit_bottom_sheet.dart';

class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  const HabitCard({
    super.key,
    required this.habit,
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
    // Gunakan reminderTime/currentStreak jika ada, atau fallback ke mock data
    final mockTime = habit.reminderTime != null && habit.reminderTime!.isNotEmpty
        ? habit.reminderTime!
        : (habit.title.toLowerCase().contains('air')
            ? 'Sepanjang hari'
            : '07:00');
    final mockStreak = habit.currentStreak > 0
        ? '${habit.currentStreak} hari'
        : (habit.title.toLowerCase().contains('air') ? '8 hari' : '12 hari');

    return GestureDetector(
      onLongPress: onLongPress, // Tahan lama untuk memunculkan edit/hapus
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            // 1. Ikon Sebelah Kiri
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(habit.title),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getIconData(habit.title),
                color: _getIconColor(habit.title),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),

            // 2. Teks Judul dan Informasi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: habit.isCompletedToday
                          ? Colors.grey.shade400
                          : const Color(0xFF334155),
                      decoration: habit.isCompletedToday
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mockTime,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.local_fire_department_outlined,
                        size: 14,
                        color: Color(0xFFF97316),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mockStreak,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFF97316),
                        ),
                      ),
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

            // 3. Tombol Check-in Kanan
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: habit.isCompletedToday
                      ? const Color(0xFFD9F99D) // Warna lime green saat selesai
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: habit.isCompletedToday
                      ? Colors.black87
                      : Colors.grey.shade400,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
