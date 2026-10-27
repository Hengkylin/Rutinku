import 'package:supabase_flutter/supabase_flutter.dart';

/// Pembungkus tipis untuk `Supabase.instance.client.auth`.
class AuthService {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  User? get currentUser => _auth.currentUser;

  Future<AuthResponse> login(String email, String password) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> register(String email, String password) {
    return _auth.signUp(email: email, password: password);
  }

  Future<void> logout() => _auth.signOut();
}
