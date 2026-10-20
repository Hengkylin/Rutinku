import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/habit_model.dart';
import '../notifiers/habit_notifier.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final habitState = ref.watch(habitNotifierProvider);
    final habits = habitState.value ?? [];
    final currentSelectedDay = _selectedDay;

    final completedCount =
        habits.where((h) => h.isCompletedOn(currentSelectedDay)).length;
    final totalCount = habits.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Riwayat Check-in',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Widget Table Calendar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.only(bottom: 12),
            child: TableCalendar<HabitModel>(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) {
                return habits.where((h) => h.isCompletedOn(day)).toList();
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Color(0xFF64748B),
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Color(0xFF64748B),
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: Color(0xFF6D28D9),
                  fontWeight: FontWeight.bold,
                ),
                markerDecoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                markerSize: 6,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Header Agenda Hari Terpilih
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_note, color: Color(0xFF475569), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMMM yyyy').format(currentSelectedDay),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                if (totalCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: completedCount == totalCount
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$completedCount/$totalCount Selesai',
                      style: TextStyle(
                        color: completedCount == totalCount
                            ? const Color(0xFF15803D)
                            : const Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Daftar Rutinitas
          Expanded(
            child: habitState.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Terjadi kesalahan: $err')),
              data: (habits) {
                if (habits.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada kebiasaan yang dibuat.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    final isCompleted = habit.isCompletedOn(currentSelectedDay);

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isCompleted
                              ? const Color(0xFFD9F99D)
                              : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          ref
                              .read(habitNotifierProvider.notifier)
                              .toggleCheckIn(habit.id, currentSelectedDay);
                        },
                        leading: GestureDetector(
                          onTap: () {
                            ref
                                .read(habitNotifierProvider.notifier)
                                .toggleCheckIn(habit.id, currentSelectedDay);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? const Color(0xFFD9F99D)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check
                                  : Icons.circle_outlined,
                              color: isCompleted
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFF94A3B8),
                              size: 20,
                            ),
                          ),
                        ),
                        title: Text(
                          habit.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? Colors.grey.shade400
                                : const Color(0xFF1E293B),
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: habit.category != null &&
                                habit.category!.isNotEmpty
                            ? Text(
                                habit.category!,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        trailing: habit.reminderTime != null &&
                                habit.reminderTime!.isNotEmpty
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    habit.reminderTime!,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
