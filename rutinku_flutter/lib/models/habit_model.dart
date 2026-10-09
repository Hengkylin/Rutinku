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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompletedToday': isCompletedToday,
      'category': category,
      'reminderTime': reminderTime,
      'currentStreak': currentStreak,
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      isCompletedToday: map['isCompletedToday'] as bool? ?? false,
      category: map['category'] as String?,
      reminderTime: map['reminderTime'] as String?,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
    );
  }
}