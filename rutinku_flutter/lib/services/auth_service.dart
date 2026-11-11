import 'package:supabase_flutter/supabase_flutter.dart';

/// Pembungkus tipis untuk Supabase Auth (`GoTrueClient`).
/// [client] dapat diinjeksi (mis. mock saat pengujian); default memakai
/// `Supabase.instance.client.auth`, yang baru diakses saat dipakai.
class AuthService {
  AuthService({this._client});

  final GoTrueClient? _client;

  GoTrueClient get _auth => _client ?? Supabase.instance.client.auth;

  /// Pesan yang ramah pengguna untuk error saat membuka link dari email
  /// (deep link, mis. link verifikasi pendaftaran). Mengembalikan `null` jika
  /// [error] bukan berasal dari link, mis. refresh token kedaluwarsa, agar
  /// tidak ditampilkan ke pengguna.
  static String? linkErrorMessage(Object error) {
    if (error is! AuthException) return null;

    // Supabase menolak token di link: sudah lewat batas waktu, atau sudah
    // pernah dipakai (link hanya berlaku sekali / sudah ada link yang lebih baru).
    if (error.statusCode == 'otp_expired' || error.code == 'access_denied') {
      return 'Link dari email tidak valid: sudah kedaluwarsa atau sudah pernah '
          'dipakai. Link hanya bisa dipakai sekali, silakan minta link baru '
          'dan buka email yang paling baru.';
    }

    // PKCE: kode verifikasi hanya tersimpan di perangkat yang meminta link.
    if (error.message.contains('Code verifier could not be found')) {
      return 'Link harus dibuka di HP yang sama tempat Anda mendaftar atau '
          'meminta link tersebut.';
    }
    return null;
  }

  /// Pesan untuk error saat memverifikasi kode reset password.
  static String recoveryCodeErrorMessage(AuthException error) {
    if (error.code == 'otp_expired' || error.statusCode == 'otp_expired') {
      return 'Kode salah atau sudah kedaluwarsa. Periksa email terbaru, atau '
          'tekan "Kirim ulang kode".';
    }
    return error.message;
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

  /// Mengirim email reset password. Template email "Reset Password" di
  /// Supabase berisi kode 6 digit (`{{ .Token }}`), bukan link, sehingga
  /// tidak bisa "terpakai" oleh pemindai keamanan email.
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  /// Memverifikasi kode reset dari email. Jika benar, Supabase membuat sesi
  /// recovery (pengguna login) sehingga password baru bisa disimpan.
  Future<void> verifyRecoveryCode(String email, String code) async {
    await _auth.verifyOTP(email: email, token: code, type: OtpType.recovery);
  }

  /// Mengganti password pengguna yang sedang login (termasuk sesi recovery
  /// dari kode reset password).
  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> logout() => _auth.signOut();
}
