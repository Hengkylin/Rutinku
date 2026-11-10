import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/validators.dart';

/// Layer Data untuk mengelola pembaruan profil pengguna ke Supabase.
class ProfileRepository {
  static const String tableName = 'users';
  static const String _prefNameKey = 'rutinku_profile_name';
  static const String _prefPhoneKey = 'rutinku_profile_phone';

  ProfileRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Memperbarui profil pengguna (`name` dan `phone` opsional) pada tabel
  /// `users` di Supabase, atau menjalankan simulasi asinkron jika tabel belum
  /// tersedia di skema cloud. Melempar [Exception] yang jelas jika gagal.
  Future<void> updateProfile(String name, String? phone) async {
    final nameError = Validators.validateName(name);
    if (nameError != null) {
      throw Exception('Gagal memperbarui profil: $nameError.');
    }

    final phoneError = Validators.validatePhone(phone);
    if (phoneError != null) {
      throw Exception('Gagal memperbarui profil: $phoneError.');
    }

    final trimmedName = name.trim();
    final trimmedPhone =
        (phone == null || phone.trim().isEmpty) ? null : phone.trim();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception(
          'Gagal memperbarui profil: sesi login tidak ditemukan. Silakan login kembali.',
        );
      }

      try {
        await _supabase
            .from(tableName)
            .update({
              'name': trimmedName,
              'phone': trimmedPhone,
            })
            .eq('id', user.id);
      } on PostgrestException catch (e) {
        // Simulasi Future.delayed apabila tabel `users` belum disiapkan di Supabase.
        if (e.code == '42P01' || e.code == 'PGRST205') {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        } else {
          rethrow;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefNameKey, trimmedName);
      if (trimmedPhone != null) {
        await prefs.setString(_prefPhoneKey, trimmedPhone);
      } else {
        await prefs.remove(_prefPhoneKey);
      }
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
}

