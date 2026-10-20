import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/repositories/sync_repository.dart';

/// Kelas MockClient sederhana yang meng-implements http.Client
/// untuk memanipulasi respons HTTP saat pengujian API Cloud Sync.
typedef MockRequestHandler = Future<http.Response> Function(http.BaseRequest request);

class MockClient implements http.Client {
  final MockRequestHandler _handler;

  MockClient(this._handler);

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final request = http.Request('GET', url);
    if (headers != null) request.headers.addAll(headers);
    return _handler(request);
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final request = http.Request('POST', url);
    if (headers != null) request.headers.addAll(headers);
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List<int>) {
        request.bodyBytes = body;
      } else if (body is Map) {
        request.bodyFields = Map<String, String>.from(body);
      }
    }
    return _handler(request);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
      request: response.request,
    );
  }

  @override
  void close() {}

  @override
  Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      throw UnimplementedError();

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) =>
      throw UnimplementedError();

  @override
  Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      throw UnimplementedError();

  @override
  Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      throw UnimplementedError();

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) =>
      throw UnimplementedError();

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) =>
      throw UnimplementedError();
}

void main() {
  group('Tugas Pertemuan Ke-6: 6 Unit Test Wajib Cloud Sync & Vertical Slice', () {
    late SyncRepository syncRepository;

    setUp(() {
      syncRepository = SyncRepository();
    });

    // -------------------------------------------------------------------------
    // 1. Model Valid
    // -------------------------------------------------------------------------
    test(
      '1. Model Valid: HabitModel.fromMap berhasil membuat objek jika diberi map JSON yang benar',
      () {
        final validMap = {
          'id': 'habit-001',
          'title': 'Olahraga 30 Menit',
          'records': [
            {
              'date': '2026-10-20',
              'status': 'completed',
              'mood': 'semangat',
              'note': 'Lari santai di lapangan',
            },
          ],
          'parentHabitId': null,
          'category': 'Kesehatan',
          'reminderTime': '06:30',
        };

        final habit = HabitModel.fromMap(validMap);

        expect(habit, isA<HabitModel>());
        expect(habit.id, 'habit-001');
        expect(habit.title, 'Olahraga 30 Menit');
        expect(habit.category, 'Kesehatan');
        expect(habit.reminderTime, '06:30');
        expect(habit.records.length, 1);
        expect(habit.records.first.date, '2026-10-20');
        expect(habit.records.first.status, 'completed');
        expect(habit.records.first.mood, 'semangat');
        expect(habit.records.first.note, 'Lari santai di lapangan');
      },
    );

    // -------------------------------------------------------------------------
    // 2. Model Invalid
    // -------------------------------------------------------------------------
    test(
      '2. Model Invalid: HabitModel.fromMap melempar TypeError atau Exception jika diberi map dengan tipe data yang salah',
      () {
        // Kasus A: id berupa angka (int) padahal seharusnya string
        final invalidIdMap = {
          'id': 9999,
          'title': 'Kebiasaan dengan ID Angka',
        };

        expect(
          () => HabitModel.fromMap(invalidIdMap),
          throwsA(anyOf(isA<TypeError>(), isA<Exception>())),
          reason: 'Harus melempar TypeError atau Exception saat id bertipe int',
        );

        // Kasus B: records memiliki struktur salah (bukan List of Map)
        final invalidRecordsMap = {
          'id': 'habit-002',
          'title': 'Kebiasaan dengan Records Rusak',
          'records': [123, 456],
        };

        expect(
          () => HabitModel.fromMap(invalidRecordsMap),
          throwsA(anyOf(isA<TypeError>(), isA<Exception>())),
          reason: 'Harus melempar TypeError atau Exception saat records memiliki struktur salah',
        );
      },
    );

    // -------------------------------------------------------------------------
    // 3. API Sukses
    // -------------------------------------------------------------------------
    test(
      '3. API Sukses: fetchHabitsFromCloud merespons HTTP 200 dengan JSON array valid dan mengembalikan List<HabitModel>',
      () async {
        final mockResponseData = [
          {'userId': 1, 'id': 1, 'title': 'Lari Pagi 20 Menit', 'completed': true},
          {'userId': 1, 'id': 2, 'title': 'Minum Air 2 Liter', 'completed': false},
          {'userId': 1, 'id': 3, 'title': 'Meditasi 10 Menit', 'completed': true},
          {'userId': 1, 'id': 4, 'title': 'Membaca Buku 15 Menit', 'completed': false},
          {'userId': 1, 'id': 5, 'title': 'Tidur Sebelum Jam 23.00', 'completed': true},
          {'userId': 1, 'id': 6, 'title': 'Data ke-6 (seharusnya tidak diambil)', 'completed': false},
        ];

        final mockClient = MockClient((request) async {
          expect(request.url.toString(), SyncRepository.endpoint);
          expect(request.method, 'GET');
          return http.Response(
            jsonEncode(mockResponseData),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final habits = await syncRepository.fetchHabitsFromCloud(mockClient);

        expect(habits, isA<List<HabitModel>>());
        expect(habits.length, 5, reason: 'Hanya mengambil maksimal 5 data pertama');
        expect(habits[0].id, '1');
        expect(habits[0].title, 'Lari Pagi 20 Menit');
        expect(habits[1].id, '2');
        expect(habits[1].title, 'Minum Air 2 Liter');
        expect(habits[4].id, '5');
        expect(habits[4].title, 'Tidur Sebelum Jam 23.00');
      },
    );

    // -------------------------------------------------------------------------
    // 4. Data Kosong
    // -------------------------------------------------------------------------
    test(
      '4. Data Kosong: fetchHabitsFromCloud merespons HTTP 200 dengan [] dan mengembalikan list kosong (panjang 0)',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.toString(), SyncRepository.endpoint);
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final habits = await syncRepository.fetchHabitsFromCloud(mockClient);

        expect(habits, isA<List<HabitModel>>());
        expect(habits, isEmpty);
        expect(habits.length, 0);
      },
    );

    // -------------------------------------------------------------------------
    // 5. HTTP Gagal
    // -------------------------------------------------------------------------
    test(
      '5. HTTP Gagal: fetchHabitsFromCloud merespons HTTP 404 atau 500, dan memastikan fungsi melempar Exception',
      () async {
        // Menguji respons HTTP 404
        final mockClient404 = MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        expect(
          () => syncRepository.fetchHabitsFromCloud(mockClient404),
          throwsA(isA<Exception>()),
          reason: 'Harus melempar Exception saat HTTP 404',
        );

        // Menguji respons HTTP 500
        final mockClient500 = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });

        expect(
          () => syncRepository.fetchHabitsFromCloud(mockClient500),
          throwsA(isA<Exception>()),
          reason: 'Harus melempar Exception saat HTTP 500',
        );
      },
    );

    // -------------------------------------------------------------------------
    // 6. JSON Rusak
    // -------------------------------------------------------------------------
    test(
      '6. JSON Rusak: fetchHabitsFromCloud merespons HTTP 200 tetapi dengan body teks "{ invalid_json " (JSON rusak), dan pastikan melempar FormatException',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('{ invalid_json ', 200);
        });

        expect(
          () => syncRepository.fetchHabitsFromCloud(mockClient),
          throwsA(isA<FormatException>()),
          reason: 'Harus membiarkan jsonDecode melempar FormatException saat JSON rusak',
        );
      },
    );

    // -------------------------------------------------------------------------
    // Test Tambahan: Backup Habits ke Cloud (POST HTTP 201)
    // -------------------------------------------------------------------------
    test(
      'Bonus Test: backupHabitsToCloud melakukan POST dan mengembalikan true jika status 201 (Created)',
      () async {
        final mockClient201 = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), SyncRepository.endpoint);
          return http.Response('{"id": 201}', 201);
        });

        final testHabits = [
          HabitModel(id: 'local-1', title: 'Belajar Coding'),
          HabitModel(id: 'local-2', title: 'Membaca Dokumentasi'),
        ];

        final success = await syncRepository.backupHabitsToCloud(mockClient201, testHabits);
        expect(success, isTrue);

        final mockClient500 = MockClient((request) async {
          return http.Response('Server Error', 500);
        });

        final failed = await syncRepository.backupHabitsToCloud(mockClient500, testHabits);
        expect(failed, isFalse);
      },
    );
  });
}
