import 'dart:convert';
import 'package:intl/intl.dart';

class HabitRecord {
  final String date; // Format: yyyy-MM-dd
  final String status; // 'completed', 'skipped', 'rest', 'pending'
  final String? mood;
  final String? note;
  final String? momentImagePath;

  /// Progres angka pada tanggal ini (mis. 3 gelas). Dipakai jika
  /// `HabitModel.targetValue > 1`.
  final int currentValue;

  HabitRecord({
    required this.date,
    this.status = 'completed',
    this.mood,
    this.note,
    this.momentImagePath,
    this.currentValue = 0,
  });

  HabitRecord copyWith({
    String? date,
    String? status,
    String? mood,
    String? note,
    String? momentImagePath,
    bool clearMomentImagePath = false,
    int? currentValue,
  }) {
    return HabitRecord(
      date: date ?? this.date,
      status: status ?? this.status,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      momentImagePath: clearMomentImagePath
          ? null
          : (momentImagePath ?? this.momentImagePath),
      currentValue: currentValue ?? this.currentValue,
    );
  }

  Map<String, dynamic> toMap() => {
    'date': date,
    'status': status,
    'mood': mood,
    'note': note,
    'momentImagePath': momentImagePath,
    'currentValue': currentValue,
  };

  factory HabitRecord.fromMap(Map<String, dynamic> map) => HabitRecord(
    date: map['date'] ?? '',
    status: map['status'] ?? 'completed',
    mood: map['mood'] as String?,
    note: map['note'] as String?,
    momentImagePath: map['momentImagePath'] as String?,
    // Data JSON lama belum punya field ini.
    currentValue: (map['currentValue'] as num?)?.toInt() ?? 0,
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
          momentImagePath == other.momentImagePath &&
          currentValue == other.currentValue;

  @override
  int get hashCode =>
      date.hashCode ^
      status.hashCode ^
      mood.hashCode ^
      note.hashCode ^
      momentImagePath.hashCode ^
      currentValue.hashCode;
}

class HabitModel {
  final String id;
  final String title;
  final List<HabitRecord> records;
  final String? parentHabitId;
  final String? category;
  final String? reminderTime;

  /// Target angka harian. `1` = kebiasaan biasa (cukup check-in sekali).
  final int targetValue;

  /// Satuan target, mis. "gelas", "menit", "halaman".
  final String? unit;

  HabitModel({
    required this.id,
    required this.title,
    this.records = const [],
    this.parentHabitId,
    this.category,
    this.reminderTime,
    this.targetValue = 1,
    this.unit,
  });

  static String _dateKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  /// Selesai jika: target 1 → status record 'completed';
  /// target > 1 → `currentValue` record sudah mencapai target.
  bool isCompletedOn(DateTime date) {
    final record = getRecordOn(date);
    if (record == null) return false;
    if (targetValue <= 1) return record.status == 'completed';
    return record.currentValue >= targetValue;
  }

  bool isRestOn(DateTime date) => getRecordOn(date)?.status == 'rest';

  HabitRecord? getRecordOn(DateTime date) {
    final dateStr = _dateKey(date);
    for (final r in records) {
      if (r.date == dateStr) return r;
    }
    return null;
  }

  HabitRecord? get todayRecord => getRecordOn(DateTime.now());

  bool get isCompletedToday => isCompletedOn(DateTime.now());

  /// Mengembalikan salinan habit dengan progres tanggal [date] bertambah 1.
  /// Record baru dibuat berstatus 'pending'; status otomatis menjadi
  /// 'completed' begitu `currentValue >= targetValue`.
  /// Dipakai bersama oleh notifier (optimistic UI) dan repository (persisten).
  HabitModel incrementProgress(DateTime date) {
    final dateStr = _dateKey(date);
    final updatedRecords = List<HabitRecord>.from(records);
    final index = updatedRecords.indexWhere((r) => r.date == dateStr);

    var record = index == -1
        ? HabitRecord(date: dateStr, status: 'pending', currentValue: 1)
        : updatedRecords[index].copyWith(
            currentValue: updatedRecords[index].currentValue + 1,
          );
    if (record.currentValue >= targetValue) {
      record = record.copyWith(status: 'completed');
    }

    if (index == -1) {
      updatedRecords.add(record);
    } else {
      updatedRecords[index] = record;
    }
    return copyWith(records: updatedRecords);
  }

  /// Mengembalikan salinan habit dengan status check-in tanggal [date]
  /// dibalik (completed <-> pending) via `copyWith`, sehingga `currentValue`,
  /// mood, catatan, dan foto tetap utuh.
  /// Habit progresif (`targetValue > 1`) tidak bisa ditandai 'completed'
  /// sebelum `currentValue` mencapai target; dalam kasus itu habit
  /// dikembalikan tanpa perubahan.
  /// Dipakai bersama oleh notifier (optimistic UI) dan repository (persisten).
  HabitModel toggleCheckIn(DateTime date) {
    final dateStr = _dateKey(date);
    final updatedRecords = List<HabitRecord>.from(records);
    final index = updatedRecords.indexWhere((r) => r.date == dateStr);
    final existing = index == -1 ? null : updatedRecords[index];

    if (existing?.status == 'completed') {
      updatedRecords[index] = existing!.copyWith(status: 'pending');
      return copyWith(records: updatedRecords);
    }

    final reachedTarget =
        targetValue <= 1 || (existing?.currentValue ?? 0) >= targetValue;
    if (!reachedTarget) return this;

    if (existing == null) {
      updatedRecords.add(HabitRecord(date: dateStr, status: 'completed'));
    } else {
      updatedRecords[index] = existing.copyWith(status: 'completed');
    }
    return copyWith(records: updatedRecords);
  }

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
    int? targetValue,
    String? unit,
    bool clearUnit = false,
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
      targetValue: targetValue ?? this.targetValue,
      unit: clearUnit ? null : (unit ?? this.unit),
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
      'targetValue': targetValue,
      'unit': unit,
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
      // Fallback untuk data JSON lama yang belum memiliki field ini.
      targetValue: (map['targetValue'] as num?)?.toInt() ?? 1,
      unit: map['unit'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory HabitModel.fromJson(String source) =>
      HabitModel.fromMap(json.decode(source) as Map<String, dynamic>);
}