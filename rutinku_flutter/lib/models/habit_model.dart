import 'dart:convert';
import 'package:intl/intl.dart';

class HabitRecord {
  final String date; // Format: yyyy-MM-dd
  final String status; // 'completed', 'skipped', 'rest'
  final String? mood;
  final String? note;
  final String? momentImagePath;

  HabitRecord({
    required this.date,
    this.status = 'completed',
    this.mood,
    this.note,
    this.momentImagePath,
  });

  HabitRecord copyWith({
    String? date,
    String? status,
    String? mood,
    String? note,
    String? momentImagePath,
    bool clearMomentImagePath = false,
  }) {
    return HabitRecord(
      date: date ?? this.date,
      status: status ?? this.status,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      momentImagePath: clearMomentImagePath
          ? null
          : (momentImagePath ?? this.momentImagePath),
    );
  }

  Map<String, dynamic> toMap() => {
    'date': date,
    'status': status,
    'mood': mood,
    'note': note,
    'momentImagePath': momentImagePath,
  };

  factory HabitRecord.fromMap(Map<String, dynamic> map) => HabitRecord(
    date: map['date'] ?? '',
    status: map['status'] ?? 'completed',
    mood: map['mood'] as String?,
    note: map['note'] as String?,
    momentImagePath: map['momentImagePath'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitRecord &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          status == other.status &&
          mood == other.mood &&
          note == other.note &&
          momentImagePath == other.momentImagePath;

  @override
  int get hashCode =>
      date.hashCode ^
      status.hashCode ^
      mood.hashCode ^
      note.hashCode ^
      momentImagePath.hashCode;
}

class HabitModel {
  final String id;
  final String title;
  final List<HabitRecord> records;
  final String? parentHabitId;
  final String? category;
  final String? reminderTime;

  HabitModel({
    required this.id,
    required this.title,
    this.records = const [],
    this.parentHabitId,
    this.category,
    this.reminderTime,
  });

  bool isCompletedOn(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return records.any((r) => r.date == dateStr && r.status == 'completed');
  }

  bool isRestOn(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return records.any((r) => r.date == dateStr && r.status == 'rest');
  }

  HabitRecord? getRecordOn(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    for (final r in records) {
      if (r.date == dateStr) return r;
    }
    return null;
  }

  HabitRecord? get todayRecord => getRecordOn(DateTime.now());

  bool get isCompletedToday => isCompletedOn(DateTime.now());

  int get streakCount {
    int streak = 0;
    DateTime checkDate = DateTime.now();
    // Jika hari ini belum selesai atau sedang libur, toleransi mundur mulai dari kemarin
    if (!isCompletedOn(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    // Hitung mundur terus: jika selesai -> streak++, jika libur (rest) -> jembatani tanpa memutus streak
    while (isCompletedOn(checkDate) || isRestOn(checkDate)) {
      if (isCompletedOn(checkDate)) {
        streak++;
      }
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double get weeklyProgress {
    int completedDays = 0;
    final today = DateTime.now();
    for (int i = 0; i < 7; i++) {
      if (isCompletedOn(today.subtract(Duration(days: i)))) {
        completedDays++;
      }
    }
    return completedDays / 7.0; // Mengembalikan nilai 0.0 hingga 1.0
  }

  HabitModel copyWith({
    String? id,
    String? title,
    List<HabitRecord>? records,
    String? parentHabitId,
    bool clearParentHabitId = false,
    String? category,
    String? reminderTime,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      records: records ?? this.records,
      parentHabitId: clearParentHabitId
          ? null
          : (parentHabitId ?? this.parentHabitId),
      category: category ?? this.category,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'records': records.map((r) => r.toMap()).toList(),
      'parentHabitId': parentHabitId,
      'category': category,
      'reminderTime': reminderTime,
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      records:
          (map['records'] as List<dynamic>?)
              ?.map((e) => HabitRecord.fromMap(e as Map<String, dynamic>))
              .toList() ??
          (map['completedDates'] as List<dynamic>?)
              ?.map((e) => HabitRecord(date: e.toString(), status: 'completed'))
              .toList() ??
          [],
      parentHabitId: map['parentHabitId'] as String?,
      category: map['category'] as String?,
      reminderTime: map['reminderTime'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory HabitModel.fromJson(String source) =>
      HabitModel.fromMap(json.decode(source) as Map<String, dynamic>);
}