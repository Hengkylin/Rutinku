import 'package:flutter/material.dart';

import '../repositories/profile_repository.dart';
import '../utils/validators.dart';

/// Komponen Form Profil mandiri yang memisahkan UI dari logika validasi dan data.
class ProfileForm extends StatefulWidget {
  const ProfileForm({
    super.key,
    this.initialName,
    this.initialPhone,
    this.onSaveSuccess,
    this.repository,
  });

  final String? initialName;
  final String? initialPhone;
  final VoidCallback? onSaveSuccess;
  final ProfileRepository? repository;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  static const _navy = Color(0xFF1E293B);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final ProfileRepository _repository =
      widget.repository ?? ProfileRepository();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void didUpdateWidget(covariant ProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialName != oldWidget.initialName &&
        _nameController.text == (oldWidget.initialName ?? '')) {
      _nameController.text = widget.initialName ?? '';
    }
    if (widget.initialPhone != oldWidget.initialPhone &&
        _phoneController.text == (oldWidget.initialPhone ?? '')) {
      _phoneController.text = widget.initialPhone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _navy, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.6),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await _repository.updateProfile(
        Validators.normalize(_nameController.text),
        Validators.normalizeOptional(_phoneController.text),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onSaveSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('profile_name_field'),
            controller: _nameController,
            enabled: !_isLoading,
            textInputAction: TextInputAction.next,
            decoration: _fieldDecoration(
              label: 'Nama Lengkap',
              hint: 'Masukkan minimal 3 karakter',
              icon: Icons.person_outline_rounded,
            ),
            validator: Validators.validateName,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('profile_phone_field'),
            controller: _phoneController,
            enabled: !_isLoading,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSubmit(),
            decoration: _fieldDecoration(
              label: 'Nomor Telepon (Opsional)',
              hint: 'Contoh: 081234567890',
              icon: Icons.phone_outlined,
            ),
            validator: Validators.validatePhone,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            key: const Key('profile_save_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
                    'Simpan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}

