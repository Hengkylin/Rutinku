/// Kumpulan fungsi statis murni untuk validasi input pengguna.
class Validators {
  const Validators._();

  static final RegExp _digitsOnlyRegex = RegExp(r'^\d+$');

  /// Validasi nama pengguna: wajib diisi dan minimal 3 karakter.
  static String? validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Nama wajib diisi';
    }
    if (trimmed.length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  /// Validasi nomor telepon: opsional, namun jika diisi harus berupa angka
  /// dan minimal 10 digit.
  static String? validatePhone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    if (!_digitsOnlyRegex.hasMatch(trimmed)) {
      return 'Nomor telepon harus berupa angka';
    }
    if (trimmed.length < 10) {
      return 'Nomor telepon minimal 10 digit';
    }
    return null;
  }
}

