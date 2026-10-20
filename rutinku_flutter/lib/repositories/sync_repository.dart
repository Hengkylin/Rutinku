import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/habit_model.dart';

class SyncRepository {
  static const String endpoint = 'https://jsonplaceholder.typicode.com/todos';

  /// Mengambil data dari mock backend API (JSONPlaceholder).
  /// Memetakan respons JSON menjadi [HabitModel] dan mengambil 5 data pertama.
  /// Melempar [Exception] jika HTTP status bukan 200.
  /// Membiarkan [jsonDecode] melempar [FormatException] jika JSON rusak.
  Future<List<HabitModel>> fetchHabitsFromCloud(http.Client client) async {
    final response = await client.get(Uri.parse(endpoint));

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data dari cloud (HTTP ${response.statusCode})');
    }

    // Biarkan jsonDecode melempar FormatException jika JSON rusak
    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw const FormatException('Format respons tidak berupa list JSON');
    }

    final List<dynamic> jsonList = decoded;
    return jsonList.take(5).map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return HabitModel(
        id: map['id']?.toString() ?? '',
        title: map['title'] as String? ?? '',
        category: map['category'] as String? ?? 'Cloud Sync',
        records: map['records'] != null
            ? (map['records'] as List<dynamic>)
                .map((e) => HabitRecord.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList()
            : (map['completedDates'] != null
                ? (map['completedDates'] as List<dynamic>)
                    .map((e) => HabitRecord(date: e.toString(), status: 'completed'))
                    .toList()
                : (map['completed'] == true
                    ? [
                        HabitRecord(
                          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          status: 'completed',
                        ),
                      ]
                    : [])),
        parentHabitId: map['parentHabitId'] as String?,
        reminderTime: map['reminderTime'] as String?,
      );
    }).toList();
  }

  /// Mengirimkan data habits ke mock backend API dengan metode POST.
  /// Mengembalikan true jika respons HTTP adalah 201 (Created).
  Future<bool> backupHabitsToCloud(http.Client client, List<HabitModel> habits) async {
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(habits.map((h) => h.toMap()).toList()),
    );

    return response.statusCode == 201;
  }
}
