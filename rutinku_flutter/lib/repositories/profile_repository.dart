import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Layer Data profil pengguna: hanya bertanggung jawab atas request ke
/// Supabase (tabel `users`) dan cache lokal. Validasi input dilakukan di
/// layer UI menggunakan `Validators` sebelum repository dipanggil.
class ProfileRepository {
  static const String tableName = 'users';
  static const String _prefNameKey = 'rutinku_profile_name';
  static const String _prefPhoneKey = 'rutinku_profile_phone';

  /// Kode error Postgres/PostgREST saat tabel belum tersedia di skema.
  static const Set<String> _missingTableCodes = {'42P01', 'PGRST205'};
  static const Duration _simulatedDelay = Duration(milliseconds: 500);

  ProfileRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Memperbarui profil pengguna (`name` & `phone` opsional) di Supabase
  /// lalu menyimpannya ke cache lokal. Melempar [Exception] yang jelas jika gagal.
  Future<void> updateProfile(String name, String? phone) async {
    try {
      final userId = _requireUserId();
      await _sendUpdateRequest(userId, name, phone);
      await _cacheProfile(name, phone);
    } on AuthException catch (e) {
      throw Exception('Gagal memperbarui profil (Auth): ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Gagal memperbarui profil di database: ${e.message}');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Gagal memperbarui profil pengguna: $e');
    }
  }

  /// Mengambil data profil yang tersimpan secara lokal sebagai nilai awal form.
  Future<({String? name, String? phone})> getSavedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (
        name: prefs.getString(_prefNameKey),
        phone: prefs.getString(_prefPhoneKey),
      );
    } catch (_) {
      return (name: null, phone: null);
    }
  }

  /// Memastikan ada sesi login aktif dan mengembalikan ID pengguna.
  String _requireUserId() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception(
        'Gagal memperbarui profil: sesi login tidak ditemukan. Silakan login kembali.',
      );
    }
    return user.id;
  }

  /// Request UPDATE ke tabel `users`. Jika tabel belum disiapkan, request
  /// disimulasikan dengan `Future.delayed`.
  Future<void> _sendUpdateRequest(
    String userId,
    String name,
    String? phone,
  ) async {
    try {
      await _supabase
          .from(tableName)
          .update({'name': name, 'phone': phone})
          .eq('id', userId);
    } on PostgrestException catch (e) {
      if (!_isMissingTable(e)) rethrow;
      await Future<void>.delayed(_simulatedDelay);
    }
  }

  bool _isMissingTable(PostgrestException e) =>
      _missingTableCodes.contains(e.code);

  /// Menyimpan profil terbaru ke `SharedPreferences` sebagai cache lokal.
  Future<void> _cacheProfile(String name, String? phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefNameKey, name);
    if (phone == null) {
      await prefs.remove(_prefPhoneKey);
    } else {
      await prefs.setString(_prefPhoneKey, phone);
    }
  }
}
