import 'package:flutter_test/flutter_test.dart';
import 'package:rutinku_flutter/models/habit_model.dart';

/// Unit test logika inti HabitRecord & HabitModel (serialisasi, status
/// selesai, check-in, progres, streak, progres mingguan) dengan tanggal
/// acuan tetap Jumat 2026-11-20 agar tidak bergantung pada jam perangkat.
void main() {
  final today = DateTime(2026, 11, 20);
  DateTime daysAgo(int n) => today.subtract(Duration(days: n));
  String key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  HabitRecord done(DateTime d) => HabitRecord(date: key(d), status: 'completed');

  group('HabitRecord', () {
    test('nilai default: status completed & currentValue 0', () {
      final r = HabitRecord(date: '2026-11-20');
      expect(r.status, 'completed');
      expect(r.currentValue, 0);
      expect(r.mood, isNull);
    });

    test('toMap -> fromMap menghasilkan record yang sama', () {
      final r = HabitRecord(
        date: '2026-11-20',
        status: 'pending',
        mood: 'happy',
        note: '5 halaman',
        momentImagePath: '/foto.jpg',
        currentValue: 2,
      );
      expect(HabitRecord.fromMap(r.toMap()), r);
    });

    test('fromMap data lama tanpa status & currentValue memakai default', () {
      final r = HabitRecord.fromMap({'date': '2026-11-20'});
      expect(r.status, 'completed');
      expect(r.currentValue, 0);
    });

    test('fromMap menerima currentValue bertipe double', () {
      final r = HabitRecord.fromMap({'date': '2026-11-20', 'currentValue': 3.0});
      expect(r.currentValue, 3);
    });

    test('copyWith status mempertahankan mood, catatan, foto, dan progres', () {
      final r = HabitRecord(
        date: '2026-11-20',
        mood: 'sad',
        note: 'capek',
        momentImagePath: '/a.jpg',
        currentValue: 4,
      );
      final updated = r.copyWith(status: 'pending');
      expect(updated.status, 'pending');
      expect(updated.mood, 'sad');
      expect(updated.note, 'capek');
      expect(updated.momentImagePath, '/a.jpg');
      expect(updated.currentValue, 4);
    });

    test('copyWith clearMomentImagePath menghapus foto', () {
      final r = HabitRecord(date: '2026-11-20', momentImagePath: '/a.jpg');
      expect(r.copyWith(clearMomentImagePath: true).momentImagePath, isNull);
    });

    test('== dan hashCode konsisten; currentValue berbeda tidak sama', () {
      final a = HabitRecord(date: '2026-11-20', mood: 'happy');
      final b = HabitRecord(date: '2026-11-20', mood: 'happy');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == a.copyWith(currentValue: 1), isFalse);
    });
  });

  group('HabitModel serialisasi', () {
    test('nilai default: target 1, tanpa satuan, tanpa record', () {
      final h = HabitModel(id: '1', title: 'Baca');
      expect(h.targetValue, 1);
      expect(h.unit, isNull);
      expect(h.records, isEmpty);
    });

    test('toJson -> fromJson mempertahankan semua field', () {
      final h = HabitModel(
        id: '1',
        title: 'Minum Air',
        records: [HabitRecord(date: '2026-11-20', currentValue: 3)],
        parentHabitId: 'p',
        category: 'Kesehatan',
        reminderTime: '07:30',
        targetValue: 8,
        unit: 'gelas',
      );
      expect(HabitModel.fromJson(h.toJson()).toMap(), h.toMap());
    });

    test('fromMap format lama completedDates diubah menjadi record completed',
        () {
      final h = HabitModel.fromMap({
        'id': '1',
        'title': 'Lari',
        'completedDates': ['2026-11-18', '2026-11-19'],
      });
      expect(h.records.length, 2);
      expect(h.records.every((r) => r.status == 'completed'), isTrue);
      expect(h.isCompletedOn(DateTime(2026, 11, 19)), isTrue);
    });

    test('fromMap data lama tanpa targetValue & unit memakai default', () {
      final h = HabitModel.fromMap({'id': '1', 'title': 'Lari', 'records': []});
      expect(h.targetValue, 1);
      expect(h.unit, isNull);
    });

    test('fromMap tanpa id & title menjadi string kosong (tidak crash)', () {
      final h = HabitModel.fromMap({});
      expect(h.id, '');
      expect(h.title, '');
      expect(h.records, isEmpty);
    });

    test('copyWith clearParentHabitId & clearUnit mengosongkan field', () {
      final h = HabitModel(id: '1', title: 'A', parentHabitId: 'p', unit: 'menit');
      final c = h.copyWith(clearParentHabitId: true, clearUnit: true);
      expect(c.parentHabitId, isNull);
      expect(c.unit, isNull);
    });

    test('copyWith tanpa argumen menghasilkan data yang sama', () {
      final h = HabitModel(
          id: '1', title: 'A', category: 'X', reminderTime: '08:00', targetValue: 2);
      expect(h.copyWith().toMap(), h.toMap());
    });
  });

  group('HabitModel status harian', () {
    test('tanpa record -> belum selesai', () {
      expect(HabitModel(id: '1', title: 'A').isCompletedOn(today), isFalse);
    });

    test('target 1: hanya status completed yang dianggap selesai', () {
      final pending = HabitModel(id: '1', title: 'A', records: [
        HabitRecord(date: key(today), status: 'pending'),
      ]);
      expect(pending.isCompletedOn(today), isFalse);
      expect(HabitModel(id: '1', title: 'A', records: [done(today)])
          .isCompletedOn(today), isTrue);
    });

    test('target > 1: selesai ditentukan currentValue, bukan status', () {
      HabitModel withValue(int v) => HabitModel(
            id: '1',
            title: 'Minum',
            targetValue: 3,
            records: [HabitRecord(date: key(today), status: 'pending', currentValue: v)],
          );
      expect(withValue(2).isCompletedOn(today), isFalse);
      expect(withValue(3).isCompletedOn(today), isTrue);
    });

    test('isRestOn hanya true untuk status rest', () {
      final h = HabitModel(id: '1', title: 'A', records: [
        HabitRecord(date: key(today), status: 'rest'),
        HabitRecord(date: key(daysAgo(1)), status: 'skipped'),
      ]);
      expect(h.isRestOn(today), isTrue);
      expect(h.isRestOn(daysAgo(1)), isFalse);
    });

    test('getRecordOn mengabaikan jam (23:59 tetap tanggal yang sama)', () {
      final h = HabitModel(id: '1', title: 'A', records: [done(today)]);
      expect(h.getRecordOn(DateTime(2026, 11, 20, 23, 59)), isNotNull);
      expect(h.getRecordOn(DateTime(2026, 11, 21, 0, 1)), isNull);
    });
  });

  group('HabitModel.toggleCheckIn', () {
    test('tanpa record -> menambah record completed', () {
      final h = HabitModel(id: '1', title: 'A').toggleCheckIn(today);
      expect(h.isCompletedOn(today), isTrue);
      expect(h.records.single.status, 'completed');
    });

    test('completed -> pending tanpa menghapus mood, catatan, dan foto', () {
      final h = HabitModel(id: '1', title: 'A', records: [
        HabitRecord(
            date: key(today), mood: 'happy', note: 'mantap', momentImagePath: '/a.jpg'),
      ]).toggleCheckIn(today);
      final r = h.getRecordOn(today)!;
      expect(r.status, 'pending');
      expect(r.mood, 'happy');
      expect(r.note, 'mantap');
      expect(r.momentImagePath, '/a.jpg');
    });

    test('record skipped -> menjadi completed', () {
      final h = HabitModel(id: '1', title: 'A', records: [
        HabitRecord(date: key(today), status: 'skipped'),
      ]).toggleCheckIn(today);
      expect(h.getRecordOn(today)!.status, 'completed');
    });

    test('habit progresif di bawah target: ditolak (instance yang sama)', () {
      final h = HabitModel(id: '1', title: 'Minum', targetValue: 3, records: [
        HabitRecord(date: key(today), status: 'pending', currentValue: 1),
      ]);
      expect(identical(h.toggleCheckIn(today), h), isTrue);
    });

    test('habit progresif yang sudah mencapai target boleh ditandai completed',
        () {
      final h = HabitModel(id: '1', title: 'Minum', targetValue: 2, records: [
        HabitRecord(date: key(today), status: 'pending', currentValue: 2),
      ]).toggleCheckIn(today);
      expect(h.getRecordOn(today)!.status, 'completed');
      expect(h.getRecordOn(today)!.currentValue, 2);
    });

    test('tidak mengubah objek asli (immutable)', () {
      final original = HabitModel(id: '1', title: 'A');
      original.toggleCheckIn(today);
      expect(original.records, isEmpty);
    });
  });

  group('HabitModel.incrementProgress', () {
    test('+1 pertama membuat record pending bernilai 1', () {
      final h = HabitModel(id: '1', title: 'Minum', targetValue: 3)
          .incrementProgress(today);
      final r = h.getRecordOn(today)!;
      expect(r.currentValue, 1);
      expect(r.status, 'pending');
    });

    test('mencapai target otomatis berstatus completed', () {
      var h = HabitModel(id: '1', title: 'Minum', targetValue: 2);
      h = h.incrementProgress(today).incrementProgress(today);
      expect(h.getRecordOn(today)!.status, 'completed');
      expect(h.isCompletedOn(today), isTrue);
    });

    test('target 1: sekali +1 langsung completed', () {
      final h = HabitModel(id: '1', title: 'A').incrementProgress(today);
      expect(h.isCompletedOn(today), isTrue);
      expect(h.getRecordOn(today)!.currentValue, 1);
    });

    test('mempertahankan mood & catatan pada record yang sudah ada', () {
      final h = HabitModel(id: '1', title: 'Minum', targetValue: 5, records: [
        HabitRecord(date: key(today), status: 'pending', mood: 'ok', note: 'pagi', currentValue: 1),
      ]).incrementProgress(today);
      final r = h.getRecordOn(today)!;
      expect(r.currentValue, 2);
      expect(r.mood, 'ok');
      expect(r.note, 'pagi');
    });

    test('tidak mengubah objek asli (immutable)', () {
      final original = HabitModel(id: '1', title: 'Minum', targetValue: 3);
      original.incrementProgress(today);
      expect(original.records, isEmpty);
    });
  });

  group('HabitModel.streakCountOn', () {
    test('tanpa record -> 0', () {
      expect(HabitModel(id: '1', title: 'A').streakCountOn(today), 0);
    });

    test('3 hari berturut-turut sampai hari ini -> 3', () {
      final h = HabitModel(id: '1', title: 'A',
          records: [done(today), done(daysAgo(1)), done(daysAgo(2))]);
      expect(h.streakCountOn(today), 3);
    });

    test('hari ini belum check-in: streak dihitung dari kemarin (toleransi)', () {
      final h = HabitModel(id: '1', title: 'A',
          records: [done(daysAgo(1)), done(daysAgo(2))]);
      expect(h.streakCountOn(today), 2);
    });

    test('ada hari terlewat di tengah -> streak putus', () {
      final h = HabitModel(id: '1', title: 'A',
          records: [done(today), done(daysAgo(2))]);
      expect(h.streakCountOn(today), 1);
    });

    test('hari istirahat (rest) menjembatani tanpa menambah hitungan', () {
      final h = HabitModel(id: '1', title: 'A', records: [
        done(today),
        HabitRecord(date: key(daysAgo(1)), status: 'rest'),
        done(daysAgo(2)),
      ]);
      expect(h.streakCountOn(today), 2);
    });

    test('kemarin dan hari ini terlewat -> 0', () {
      final h = HabitModel(id: '1', title: 'A', records: [done(daysAgo(2))]);
      expect(h.streakCountOn(today), 0);
    });

    test('habit progresif hanya dihitung jika target tercapai', () {
      final h = HabitModel(id: '1', title: 'Minum', targetValue: 2, records: [
        HabitRecord(date: key(today), status: 'completed', currentValue: 2),
        HabitRecord(date: key(daysAgo(1)), status: 'pending', currentValue: 1),
      ]);
      expect(h.streakCountOn(today), 1);
    });
  });

  group('HabitModel.weeklyProgressOn', () {
    test('7 dari 7 hari selesai -> 1.0', () {
      final h = HabitModel(id: '1', title: 'A',
          records: [for (var i = 0; i < 7; i++) done(daysAgo(i))]);
      expect(h.weeklyProgressOn(today), 1.0);
    });

    test('hanya 7 hari terakhir yang dihitung (hari ke-8 diabaikan)', () {
      final h = HabitModel(id: '1', title: 'A',
          records: [done(today), done(daysAgo(7))]);
      expect(h.weeklyProgressOn(today), closeTo(1 / 7, 1e-9));
    });
  });
}
