import 'package:supabase_flutter/supabase_flutter.dart';

/// Pembungkus tipis untuk Supabase Auth (`GoTrueClient`).
/// [client] dapat diinjeksi (mis. mock saat pengujian); default memakai
/// `Supabase.instance.client.auth`, yang baru diakses saat dipakai.
class AuthService {
  AuthService({this._client});

  final GoTrueClient? _client;

  GoTrueClient get _auth => _client ?? Supabase.instance.client.auth;

  /// Deep link tujuan link di email (reset password). Harus sama dengan
  /// intent-filter di `android/app/src/main/AndroidManifest.xml` dan
  /// didaftarkan di Supabase Dashboard → Authentication → URL Configuration
  /// → Redirect URLs.
  static const String authRedirectUrl = 'io.supabase.rutinku://login-callback/';

  /// Pesan yang ramah pengguna untuk error saat membuka link dari email
  /// (deep link). Mengembalikan `null` jika [error] bukan berasal dari link,
  /// mis. refresh token kedaluwarsa, agar tidak ditampilkan ke pengguna.
  static String? linkErrorMessage(Object error) {
    if (error is! AuthException) return null;

    // Supabase menolak token di link: sudah lewat batas waktu, atau sudah
    // pernah dipakai (link hanya berlaku sekali / sudah ada link yang lebih baru).
    if (error.statusCode == 'otp_expired' || error.code == 'access_denied') {
      return 'Link dari email tidak valid: sudah kedaluwarsa atau sudah pernah '
          'dipakai. Link hanya bisa dipakai sekali, silakan minta link baru '
          'dan buka email yang paling baru.';
    }

    // PKCE: kode verifikasi hanya tersimpan di perangkat yang meminta reset.
    if (error.message.contains('Code verifier could not be found')) {
      return 'Link harus dibuka di HP yang sama tempat Anda meminta reset '
          'password. Silakan minta link baru dari HP ini.';
    }
    return null;
  }

  User? get currentUser => _auth.currentUser;

  /// Perubahan status auth dari Supabase (signedIn, passwordRecovery, dst.).
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  Future<AuthResponse> login(String email, String password) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> register(String email, String password) {
    return _auth.signUp(email: email, password: password);
  }

  /// Mengirim email berisi link reset password. Link membuka aplikasi lewat
  /// [authRedirectUrl] dan memicu event `AuthChangeEvent.passwordRecovery`.
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email, redirectTo: authRedirectUrl);
  }

  /// Mengganti password pengguna yang sedang login (termasuk sesi recovery
  /// dari link reset password).
  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> logout() => _auth.signOut();
}
