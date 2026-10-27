import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/habit_model.dart';
import 'habit_repository.dart';

/// Repository Cloud Sync berbasis Supabase dengan strategi "Cloud Save JSONB".
///
/// Seluruh kebiasaan lokal (string JSON di SharedPreferences) disimpan apa
/// adanya ke kolom JSONB `sync_data` pada tabel `user_data`:
/// `{ 'user_id': <uuid>, 'sync_data': { 'habits': '<localJsonString>' } }`.
class SyncRepository {
  static const String tableName = 'user_data';

  /// [client] opsional agar mudah diganti saat pengujian. Jika null,
  /// `Supabase.instance.client` diakses secara lazy (saat dibutuhkan).
  SyncRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Pengguna yang sedang login (null jika belum login).
  User? get currentUser => _supabase.auth.currentUser;

  /// Email pengguna aktif, ditampilkan di SyncScreen.
  String? get currentUserEmail => currentUser?.email;

  /// Keluar dari akun Supabase.
  Future<void> signOut() => _supabase.auth.signOut();

  User _requireUser() {
    final user = currentUser;
    if (user == null) {
      throw Exception('Anda belum login. Silakan login terlebih dahulu.');
    }
    return user;
  }

  /// BACKUP: membaca string JSON kebiasaan dari SharedPreferences lokal lalu
  /// melakukan upsert ke tabel `user_data`. Mengembalikan true jika sukses.
  Future<bool> backupHabitsToCloud() async {
    final user = _requireUser();

    final prefs = await SharedPreferences.getInstance();
    final String localJsonString =
        prefs.getString(HabitRepository.storageKey) ?? '[]';

    await _supabase.from(tableName).upsert(
      {
        'user_id': user.id,
        'sync_data': {'habits': localJsonString},
      },
      onConflict: 'user_id',
    );
    return true;
  }

  /// FETCH: mengambil `sync_data` milik user dari Supabase dan
  /// memetakannya menjadi [HabitModel]. TIDAK mengubah data lokal.
  /// Mengembalikan list kosong jika user belum pernah mem-backup.
  Future<List<HabitModel>> fetchHabitsFromCloud() async {
    final jsonString = await _fetchRemoteHabitsString();
    return jsonString == null ? [] : _parseHabits(jsonString);
  }

  /// RESTORE: mengambil data dari cloud lalu MENIMPA string JSON kebiasaan di
  /// SharedPreferences lokal. Data divalidasi lebih dulu sebelum menimpa.
  Future<List<HabitModel>> restoreHabitsFromCloud() async {
    final jsonString = await _fetchRemoteHabitsString();
    if (jsonString == null) return [];

    final habits = _parseHabits(jsonString); // validasi sebelum menimpa
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(HabitRepository.storageKey, jsonString);
    return habits;
  }

  /// Query `.from('user_data').select().eq('user_id', id)` dan mengambil
  /// string `sync_data.habits`. Null jika baris belum ada.
  Future<String?> _fetchRemoteHabitsString() async {
    final user = _requireUser();

    final row = await _supabase
        .from(tableName)
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) return null;

    final syncData = row['sync_data'];
    if (syncData is! Map) {
      throw const FormatException('Format sync_data di cloud tidak valid');
    }

    final habits = syncData['habits'];
    if (habits == null) return null;
    if (habits is String) return habits;
    // Toleransi jika habits tersimpan sebagai array JSONB langsung.
    if (habits is List) return jsonEncode(habits);
    throw const FormatException('Format habits di cloud tidak valid');
  }

  List<HabitModel> _parseHabits(String jsonString) {
    if (jsonString.trim().isEmpty) return [];
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! List) {
      throw const FormatException('Format data habits bukan list JSON');
    }
    return decoded
        .map((item) => HabitModel.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
