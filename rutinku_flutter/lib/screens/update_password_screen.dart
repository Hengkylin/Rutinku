import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_input_decoration.dart';

/// Halaman membuat password baru. Dibuka otomatis oleh `App` saat Supabase
/// memancarkan `AuthChangeEvent.passwordRecovery` (link reset dari email).
class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  static const _navy = Color(0xFF1E293B);

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  late final AuthService _auth = widget.authService ?? AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await _auth.updatePassword(_passwordController.text);
      if (!mounted) return;

      showAppSnackBar(context, 'Password berhasil diperbarui');
      // Sesi recovery sudah login, jadi langsung ke Beranda.
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (route) => false,
      );
    } on AuthException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, isError: true);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Terjadi kesalahan: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: _navy,
        elevation: 0,
        title: const Text(
          'Password Baru',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    icon: Icons.password_rounded,
                    title: 'Buat Password Baru',
                    subtitle:
                        'Masukkan password baru untuk akun RutinKu Anda. '
                        'Gunakan minimal ${Validators.minPasswordLength} karakter.',
                  ),
                  const SizedBox(height: 28),
                  _buildForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPasswordField(
              fieldKey: const Key('update_password_field'),
              controller: _passwordController,
              label: 'Password Baru',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              onToggle: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              validator: Validators.validatePassword,
              action: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              fieldKey: const Key('update_password_confirm_field'),
              controller: _confirmController,
              label: 'Konfirmasi Password Baru',
              icon: Icons.verified_user_outlined,
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (value) => Validators.validatePasswordConfirmation(
                value,
                _passwordController.text,
              ),
              action: TextInputAction.done,
              onSubmitted: (_) => _handleSubmit(),
            ),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required Key fieldKey,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
    required FormFieldValidator<String> validator,
    required TextInputAction action,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      obscureText: obscure,
      autofillHints: const [AutofillHints.newPassword],
      textInputAction: action,
      enabled: !_isLoading,
      onFieldSubmitted: onSubmitted,
      decoration: authInputDecoration(
        label,
        icon,
        suffix: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF64748B),
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      key: const Key('update_password_submit_button'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      onPressed: _isLoading ? null : _handleSubmit,
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Simpan Password',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
    );
  }
}
