import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rutinku_flutter/app.dart';
import 'package:rutinku_flutter/routes/app_routes.dart';
import 'package:rutinku_flutter/screens/forgot_password_screen.dart';
import 'package:rutinku_flutter/screens/login_screen.dart';
import 'package:rutinku_flutter/screens/register_screen.dart';
import 'package:rutinku_flutter/screens/update_password_screen.dart';
import 'package:rutinku_flutter/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AuthService palsu (mocktail) agar pengujian tidak menembak Supabase.
class MockAuthService extends Mock implements AuthService {}

const _green = Color(0xFF16A34A);

void main() {
  late MockAuthService auth;

  setUp(() => auth = MockAuthService());

  Widget wrap(Widget home, {Map<String, WidgetBuilder> routes = const {}}) {
    return MaterialApp(home: home, routes: routes);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
  }

  group('LoginScreen', () {
    testWidgets('tombol "Lupa Password?" membuka layar Lupa Password',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          LoginScreen(authService: auth),
          routes: {
            AppRoutes.forgotPassword: (_) =>
                ForgotPasswordScreen(authService: auth),
          },
        ),
      );

      expect(find.text('Lupa Password?'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('login_forgot_password_link')));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });
  });

  group('ForgotPasswordScreen', () {
    final emailField = find.byKey(const Key('forgot_password_email_field'));
    final submit = find.byKey(const Key('forgot_password_submit_button'));

    testWidgets('email tidak valid ditolak dan resetPassword tidak dipanggil',
        (tester) async {
      await tester.pumpWidget(wrap(ForgotPasswordScreen(authService: auth)));

      await tester.enterText(emailField, 'bukan-email');
      await tapVisible(tester, submit);
      await tester.pump();

      expect(find.text('Format email tidak valid'), findsOneWidget);
      verifyNever(() => auth.resetPassword(any()));
    });

    testWidgets('sukses: loading tampil lalu SnackBar hijau', (tester) async {
      final request = Completer<void>();
      when(() => auth.resetPassword(any())).thenAnswer((_) => request.future);
      await tester.pumpWidget(wrap(ForgotPasswordScreen(authService: auth)));

      await tester.enterText(emailField, '  user@mail.com  ');
      await tapVisible(tester, submit);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      request.complete();
      await tester.pumpAndSettle();

      verify(() => auth.resetPassword('user@mail.com')).called(1);
      expect(find.text('Link reset telah dikirim ke email Anda'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, _green);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('gagal: pesan error Supabase tampil di SnackBar merah',
        (tester) async {
      when(() => auth.resetPassword(any()))
          .thenThrow(const AuthException('Email rate limit exceeded'));
      await tester.pumpWidget(wrap(ForgotPasswordScreen(authService: auth)));

      await tester.enterText(emailField, 'user@mail.com');
      await tapVisible(tester, submit);
      await tester.pumpAndSettle();

      expect(find.text('Email rate limit exceeded'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red.shade600);
    });
  });

  group('UpdatePasswordScreen', () {
    final passwordField = find.byKey(const Key('update_password_field'));
    final confirmField = find.byKey(const Key('update_password_confirm_field'));
    final submit = find.byKey(const Key('update_password_submit_button'));

    testWidgets('password < 6 karakter dan konfirmasi berbeda ditolak',
        (tester) async {
      await tester.pumpWidget(wrap(UpdatePasswordScreen(authService: auth)));

      await tester.enterText(passwordField, '12345');
      await tester.enterText(confirmField, '54321');
      await tapVisible(tester, submit);
      await tester.pump();

      expect(find.text('Password minimal 6 karakter'), findsOneWidget);
      expect(
        find.text('Password dan Konfirmasi Password harus cocok'),
        findsOneWidget,
      );
      verifyNever(() => auth.updatePassword(any()));
    });

    testWidgets('sukses: updatePassword dipanggil, SnackBar, lalu ke Beranda',
        (tester) async {
      when(() => auth.updatePassword(any())).thenAnswer((_) async {});
      await tester.pumpWidget(
        wrap(
          UpdatePasswordScreen(authService: auth),
          routes: {
            AppRoutes.dashboard: (_) => const Scaffold(body: Text('BERANDA')),
          },
        ),
      );

      await tester.enterText(passwordField, 'rahasiaBaru1');
      await tester.enterText(confirmField, 'rahasiaBaru1');
      await tapVisible(tester, submit);
      await tester.pumpAndSettle();

      verify(() => auth.updatePassword('rahasiaBaru1')).called(1);
      expect(find.text('BERANDA'), findsOneWidget);
      expect(find.text('Password berhasil diperbarui'), findsOneWidget);
    });
  });

  group('RegisterScreen - verifikasi email', () {
    testWidgets('register tanpa sesi menampilkan dialog cek email, lalu ke Login',
        (tester) async {
      when(() => auth.register(any(), any()))
          .thenAnswer((_) async => AuthResponse());
      await tester.pumpWidget(
        wrap(
          RegisterScreen(authService: auth),
          routes: {AppRoutes.login: (_) => const Text('LOGIN')},
        ),
      );

      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'baru@mail.com',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'rahasia1',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm_password_field')),
        'rahasia1',
      );
      await tapVisible(tester, find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      verify(() => auth.register('baru@mail.com', 'rahasia1')).called(1);
      expect(
        find.textContaining('Silakan cek email Anda untuk verifikasi'),
        findsOneWidget,
      );
      expect(find.text('LOGIN'), findsNothing); // belum pindah sebelum dialog ditutup

      await tester.tap(find.byKey(const Key('register_verify_email_ok')));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN'), findsOneWidget);
    });
  });

  group('App - listener AuthChangeEvent.passwordRecovery', () {
    late StreamController<AuthState> authEvents;

    setUp(() {
      authEvents = StreamController<AuthState>();
      when(() => auth.onAuthStateChange).thenAnswer((_) => authEvents.stream);
      when(() => auth.currentUser).thenReturn(null);
    });

    tearDown(() => authEvents.close());

    testWidgets('passwordRecovery membuka UpdatePasswordScreen (sekali saja)',
        (tester) async {
      await tester.pumpWidget(App(home: const Text('HOME'), authService: auth));

      authEvents.add(const AuthState(AuthChangeEvent.passwordRecovery, null));
      await tester.pumpAndSettle();
      expect(find.byType(UpdatePasswordScreen), findsOneWidget);

      // Event ganda (mis. replay dari Supabase) tidak menumpuk layar.
      authEvents.add(const AuthState(AuthChangeEvent.passwordRecovery, null));
      await tester.pumpAndSettle();
      expect(
        find.byType(UpdatePasswordScreen, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('link email kedaluwarsa menampilkan SnackBar merah, bukan diam',
        (tester) async {
      await tester.pumpWidget(
        App(home: const Scaffold(body: Text('HOME')), authService: auth),
      );

      authEvents.addError(
        const AuthException(
          'Email link is invalid or has expired',
          statusCode: 'otp_expired',
          code: 'access_denied',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('sudah kedaluwarsa atau sudah pernah dipakai'),
        findsOneWidget,
      );
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red.shade600);
      expect(find.byType(UpdatePasswordScreen), findsNothing);
    });

    testWidgets('error auth lain (mis. refresh token) tidak menampilkan pesan',
        (tester) async {
      await tester.pumpWidget(
        App(home: const Scaffold(body: Text('HOME')), authService: auth),
      );

      authEvents.addError(const AuthException('Invalid Refresh Token'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('event lain tidak membuka UpdatePasswordScreen', (tester) async {
      await tester.pumpWidget(App(home: const Text('HOME'), authService: auth));

      authEvents.add(const AuthState(AuthChangeEvent.signedIn, null));
      await tester.pumpAndSettle();

      expect(find.byType(UpdatePasswordScreen), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
    });
  });
}
