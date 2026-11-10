import 'package:flutter/material.dart';

import '../repositories/profile_repository.dart';
import '../utils/validators.dart';
import 'app_snackbar.dart';

/// Form Profil: hanya mengurus input dan status UI.
/// Aturan input didelegasikan ke [Validators], request ke [ProfileRepository].
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

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void didUpdateWidget(covariant ProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncInitialValue(_nameController, oldWidget.initialName, widget.initialName);
    _syncInitialValue(
      _phoneController,
      oldWidget.initialPhone,
      widget.initialPhone,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Memperbarui isi field saat nilai awal berubah, selama pengguna belum
  /// mengubah isi field tersebut.
  void _syncInitialValue(
    TextEditingController controller,
    String? oldValue,
    String? newValue,
  ) {
    if (newValue != oldValue && controller.text == (oldValue ?? '')) {
      controller.text = newValue ?? '';
    }
  }

  // ---------------------------------------------------------------------------
  // Status UI & aksi
  // ---------------------------------------------------------------------------

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  bool _validateForm() => _formKey.currentState?.validate() ?? false;

  Future<void> _handleSubmit() async {
    if (!_validateForm()) return;

    _setLoading(true);
    try {
      await _repository.updateProfile(
        Validators.normalize(_nameController.text),
        Validators.normalizeOptional(_phoneController.text),
      );
      _setLoading(false);
      if (mounted) widget.onSaveSuccess?.call();
    } catch (e) {
      _setLoading(false);
      _showError(e);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    showAppSnackBar(
      context,
      error.toString().replaceFirst('Exception: ', ''),
      isError: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNameField(),
          const SizedBox(height: 16),
          _buildPhoneField(),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return _buildTextField(
      fieldKey: const Key('profile_name_field'),
      controller: _nameController,
      label: 'Nama Lengkap',
      hint: 'Masukkan minimal ${Validators.minNameLength} karakter',
      icon: Icons.person_outline_rounded,
      validator: Validators.validateName,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPhoneField() {
    return _buildTextField(
      fieldKey: const Key('profile_phone_field'),
      controller: _phoneController,
      label: 'Nomor Telepon (Opsional)',
      hint: 'Contoh: 081234567890',
      icon: Icons.phone_outlined,
      validator: Validators.validatePhone,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleSubmit(),
    );
  }

  /// Satu-satunya pembuat [TextFormField] di form ini agar gaya & perilaku
  /// field tidak diduplikasi.
  Widget _buildTextField({
    required Key fieldKey,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required FormFieldValidator<String> validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      enabled: !_isLoading,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: _fieldDecoration(label: label, hint: hint, icon: icon),
      validator: validator,
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    OutlineInputBorder border(BorderSide side) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: side,
        );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: border(BorderSide.none),
      focusedBorder: border(const BorderSide(color: _navy, width: 1.6)),
      errorBorder: border(BorderSide(color: Colors.red.shade400)),
      focusedErrorBorder:
          border(BorderSide(color: Colors.red.shade600, width: 1.6)),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      key: const Key('profile_save_button'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      onPressed: _isLoading ? null : _handleSubmit,
      child: _isLoading ? _buildLoadingIndicator() : _buildSaveLabel(),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildSaveLabel() {
    return const Text(
      'Simpan',
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    );
  }
}
