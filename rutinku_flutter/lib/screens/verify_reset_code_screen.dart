import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_input_decoration.dart';
import 'update_password_screen.dart';

/// Langkah 2 reset password: memasukkan kode 6 digit dari email.
/// Jika kode benar, Supabase membuat sesi recovery dan layar ini diganti
/// dengan [UpdatePasswordScreen].
class VerifyResetCodeScreen extends StatefulWidget {
  const VerifyResetCodeScreen({
    super.key,
    required this.email,
    this.authService,
  });

  /// Email tujuan kode (dari layar Lupa Password).
  final String email;
  final AuthService? authService;

  @override
  State<VerifyResetCodeScreen> createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen> {
  static const _navy = Color(0xFF1E293B);

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  late final AuthService _auth = widget.authService ?? AuthService();

  bool _isVerifying = false;
  bool _isResending = false;

  bool get _isBusy => _isVerifying || _isResending;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isVerifying = true);
    try {
      await _auth.verifyRecoveryCode(
        widget.email,
        Validators.normalize(_codeController.text),
      );
      if (!mounted) return;

      // Kode sudah terpakai; ganti layar agar tidak bisa kembali ke sini.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => UpdatePasswordScreen(authService: _auth),
        ),
      );
    } on AuthException catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          AuthService.recoveryCodeErrorMessage(e),
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Terjadi kesalahan: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleResend() async {
    setState(() => _isResending = true);
    try {
      await _auth.resetPassword(widget.email);
      if (!mounted) return;
      _codeController.clear();
      showAppSnackBar(context, 'Kode baru telah dikirim ke email Anda');
    } on AuthException catch (e) {
      // Mis. "For security purposes, you can only request this after N seconds."
      if (mounted) showAppSnackBar(context, e.message, isError: true);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Terjadi kesalahan: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
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
          'Masukkan Kode',
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
                  AuthHeader(
                    icon: Icons.mark_email_read_outlined,
                    title: 'Cek Email Anda',
                    subtitle:
                        'Kami telah mengirim kode ${Validators.otpLength} digit '
                        'ke ${widget.email}. Kode hanya bisa dipakai sekali dan '
                        'berlaku terbatas.',
                  ),
                  const SizedBox(height: 28),
                  _buildForm(),
                  const SizedBox(height: 12),
                  _buildResendButton(),
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
            TextFormField(
              key: const Key('reset_code_field'),
              controller: _codeController,
              enabled: !_isBusy,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: _navy,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(Validators.otpLength),
              ],
              onFieldSubmitted: (_) => _handleVerify(),
              decoration: authInputDecoration('Kode Reset', Icons.pin_outlined),
              validator: Validators.validateOtpCode,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('reset_code_submit_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: _isBusy ? null : _handleVerify,
              child: _isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Verifikasi Kode',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResendButton() {
    return TextButton(
      key: const Key('reset_code_resend_button'),
      onPressed: _isBusy ? null : _handleResend,
      style: TextButton.styleFrom(foregroundColor: _navy),
      child: Text(
        _isResending ? 'Mengirim ulang...' : 'Tidak menerima kode? Kirim ulang kode',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
