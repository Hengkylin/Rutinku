import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/repositories/habit_repository.dart';

/// Issue #6: centang yang sudah tampil di layar harus benar-benar tersimpan
/// di SharedPreferences, walaupun beberapa perubahan terjadi bersamaan.
/// Data dibaca ulang langsung dari storage (seperti setelah force close).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime(2026, 11, 20);

  setUp(() {
    SharedPreferences.setMockInitialValues({
      HabitRepository.storageKey: json.encode([
        HabitModel(id: 'a', title: 'Minum Air').toMap(),
        HabitModel(id: 'b', title: 'Baca Buku').toMap(),
        HabitModel(id: 'c', title: 'Olahraga', targetValue: 3).toMap(),
      ]),
    });
  });

  /// Membaca isi storage persis seperti saat aplikasi dibuka ulang.
  Future<Map<String, HabitModel>> reloadFromStorage() async {
    final habits = await HabitRepository().fetchHabits();
    return {for (final h in habits) h.id: h};
  }

  test('mencentang beberapa rutinitas bersamaan: semua tersimpan', () async {
    final repo = HabitRepository();

    // Tanpa await di antaranya, seperti pengguna mengetuk cepat.
    await Future.wait([
      repo.toggleCheckIn('a', today),
      repo.toggleCheckIn('b', today),
      repo.incrementHabitProgress('c', today),
    ]);

    final saved = await reloadFromStorage();
    expect(saved['a']!.isCompletedOn(today), isTrue);
    expect(saved['b']!.isCompletedOn(today), isTrue);
    expect(saved['c']!.getRecordOn(today)!.currentValue, 1);
  });

  test('ketuk ganda pada rutinitas yang sama: storage sama dengan layar',
      () async {
    final repo = HabitRepository();

    // Centang lalu batalkan dengan cepat -> hasil akhir: belum selesai.
    await Future.wait([
      repo.toggleCheckIn('a', today),
      repo.toggleCheckIn('a', today),
    ]);

    final saved = await reloadFromStorage();
    expect(saved['a']!.isCompletedOn(today), isFalse);
  });

  test('progres +1 berulang dengan cepat tidak ada yang hilang', () async {
    final repo = HabitRepository();

    await Future.wait([
      repo.incrementHabitProgress('c', today),
      repo.incrementHabitProgress('c', today),
      repo.incrementHabitProgress('c', today),
    ]);

    final saved = await reloadFromStorage();
    expect(saved['c']!.getRecordOn(today)!.currentValue, 3);
    expect(saved['c']!.isCompletedOn(today), isTrue);
  });

  test('id yang tidak ada tidak menghambat operasi berikutnya',
      () async {
    final repo = HabitRepository();

    await repo.toggleCheckIn('tidak-ada', today); // diabaikan, tanpa error
    await repo.toggleCheckIn('a', today);

    final saved = await reloadFromStorage();
    expect(saved['a']!.isCompletedOn(today), isTrue);
  });
}
