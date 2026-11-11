import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rutinku_flutter/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock GoTrueClient (Supabase Auth) agar pengujian tidak menembak server.
class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockGoTrueClient client;
  late AuthService service;

  setUpAll(() {
    registerFallbackValue(UserAttributes());
  });

  setUp(() {
    client = MockGoTrueClient();
    service = AuthService(client: client);
  });

  group('AuthService.resetPassword', () {
    test('memanggil resetPasswordForEmail dengan deep link aplikasi', () async {
      when(
        () => client.resetPasswordForEmail(
          any(),
          redirectTo: any(named: 'redirectTo'),
        ),
      ).thenAnswer((_) async {});

      await service.resetPassword('user@mail.com');

      verify(
        () => client.resetPasswordForEmail(
          'user@mail.com',
          redirectTo: AuthService.authRedirectUrl,
        ),
      ).called(1);
    });

    test('meneruskan AuthException dari Supabase', () {
      when(
        () => client.resetPasswordForEmail(
          any(),
          redirectTo: any(named: 'redirectTo'),
        ),
      ).thenThrow(const AuthException('Email rate limit exceeded'));

      expect(
        service.resetPassword('user@mail.com'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService.updatePassword', () {
    test('memanggil updateUser dengan UserAttributes(password)', () async {
      when(() => client.updateUser(any())).thenAnswer(
        (_) async => UserResponse.fromJson({
          'id': 'user-1',
          'aud': 'authenticated',
          'created_at': '2026-11-11T00:00:00Z',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
        }),
      );

      await service.updatePassword('rahasiaBaru1');

      final attributes =
          verify(() => client.updateUser(captureAny())).captured.single
              as UserAttributes;
      expect(attributes.password, 'rahasiaBaru1');
    });

    test('meneruskan AuthException (mis. sesi recovery kedaluwarsa)', () {
      when(() => client.updateUser(any()))
          .thenThrow(const AuthException('Auth session missing!'));

      expect(
        service.updatePassword('rahasiaBaru1'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService.linkErrorMessage', () {
    test('link kedaluwarsa / sudah dipakai (otp_expired) diberi pesan jelas', () {
      const error = AuthException(
        'Email link is invalid or has expired',
        statusCode: 'otp_expired',
        code: 'access_denied',
      );
      expect(
        AuthService.linkErrorMessage(error),
        contains('sudah kedaluwarsa atau sudah pernah dipakai'),
      );
    });

    test('link dibuka di perangkat lain (code verifier hilang)', () {
      const error =
          AuthException('Code verifier could not be found in local storage.');
      expect(
        AuthService.linkErrorMessage(error),
        contains('HP yang sama'),
      );
    });

    test('error yang bukan dari link email diabaikan (null)', () {
      expect(
        AuthService.linkErrorMessage(
          const AuthException('Invalid Refresh Token: Refresh Token Not Found'),
        ),
        isNull,
      );
      expect(AuthService.linkErrorMessage(Exception('lain')), isNull);
    });
  });

  test('onAuthStateChange meneruskan stream dari Supabase', () async {
    final controller = StreamController<AuthState>();
    addTearDown(controller.close);
    when(() => client.onAuthStateChange).thenAnswer((_) => controller.stream);

    final first = service.onAuthStateChange.first;
    controller.add(const AuthState(AuthChangeEvent.passwordRecovery, null));

    expect((await first).event, AuthChangeEvent.passwordRecovery);
  });
}
