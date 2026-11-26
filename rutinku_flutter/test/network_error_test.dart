import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rutinku_flutter/services/auth_service.dart';

/// Bug APK release: login gagal dengan
/// "ClientException with SocketException: Failed host lookup ...".
/// Penyebab: izin INTERNET hanya ada di manifest debug/profile, bukan main.
void main() {
  group('AndroidManifest (build release)', () {
    test('manifest main meminta izin INTERNET', () {
      // `flutter test` berjalan dari folder proyek (rutinku_flutter/).
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(
        manifest,
        contains('android.permission.INTERNET'),
        reason: 'Tanpa izin ini APK release tidak bisa menghubungi Supabase',
      );
    });
  });

  group('AuthService.errorMessage', () {
    const hostLookup =
        "ClientException with SocketException: Failed host lookup: "
        "'abc.supabase.co' (OS Error: No address associated with hostname, "
        "errno = 7), uri=https://abc.supabase.co/auth/v1/token";

    test('error jaringan dari Supabase -> pesan ramah, bukan teks mentah', () {
      expect(
        AuthService.errorMessage(AuthException(hostLookup)),
        AuthService.networkErrorMessage,
      );
    });

    test('exception jaringan biasa (SocketException) -> pesan ramah', () {
      expect(
        AuthService.errorMessage(const SocketException('Network is unreachable')),
        AuthService.networkErrorMessage,
      );
    });

    test('error auth lain tetap memakai pesan dari Supabase', () {
      expect(
        AuthService.errorMessage(AuthException('Invalid login credentials')),
        'Invalid login credentials',
      );
    });

    test('error tak dikenal diberi awalan "Terjadi kesalahan"', () {
      expect(
        AuthService.errorMessage(StateError('aneh')),
        startsWith('Terjadi kesalahan: '),
      );
    });

    test('kode reset: error jaringan juga diterjemahkan', () {
      expect(
        AuthService.recoveryCodeErrorMessage(AuthException(hostLookup)),
        AuthService.networkErrorMessage,
      );
    });
  });
}
