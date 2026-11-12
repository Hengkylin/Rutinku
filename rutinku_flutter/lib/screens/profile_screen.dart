import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/profile_repository.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/profile_form.dart';
import 'log_viewer_screen.dart';

/// Halaman Profil pengguna yang mendelegasikan logika form sepenuhnya ke [ProfileForm].
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.repository});

  final ProfileRepository? repository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _navy = Color(0xFF1E293B);
  static const _lime = Color(0xFFD9F99D);

  late final ProfileRepository _repository =
      widget.repository ?? ProfileRepository();

  String? _initialName;
  String? _initialPhone;

  String? get _currentEmail {
    try {
      return Supabase.instance.client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialProfile();
  }

  Future<void> _loadInitialProfile() async {
    final saved = await _repository.getSavedProfile();
    if (!mounted) return;
    setState(() {
      _initialName = saved.name;
      _initialPhone = saved.phone;
    });
  }

  void _onSaveSuccess() {
    showAppSnackBar(context, 'Profil berhasil diperbarui!');
  }

  /// Pintu masuk ke Log Aplikasi untuk melaporkan masalah.
  Widget _buildLogEntry() {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: const Key('profile_log_entry'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: const Icon(Icons.receipt_long_rounded, color: _navy),
        title: const Text(
          'Log Aplikasi',
          style: TextStyle(fontWeight: FontWeight.w600, color: _navy),
        ),
        subtitle: const Text('Lihat & salin log untuk melaporkan masalah'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const LogViewerScreen()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _currentEmail;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: _navy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _navy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: _lime,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: _navy,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Akun RutinKu',
                                style: TextStyle(
                                  color: _lime,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email ?? 'Pengguna Lokal',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
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
                    child: ProfileForm(
                      initialName: _initialName,
                      initialPhone: _initialPhone,
                      repository: _repository,
                      onSaveSuccess: _onSaveSuccess,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLogEntry(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

