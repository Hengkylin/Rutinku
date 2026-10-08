class HabitModel {
  final String id;
  final String title;
  final bool isCompletedToday;
  final String? category;
  final String? reminderTime;
  final int currentStreak;

  HabitModel({
    required this.id,
    required this.title,
    this.isCompletedToday = false,
    this.category,
    this.reminderTime,
    this.currentStreak = 0,
  });

  HabitModel copyWith({
    String? id,
    String? title,
    bool? isCompletedToday,
    String? category,
    String? reminderTime,
    int? currentStreak,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      category: category ?? this.category,
      reminderTime: reminderTime ?? this.reminderTime,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }
}