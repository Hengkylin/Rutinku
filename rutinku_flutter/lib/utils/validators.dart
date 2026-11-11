/// Kumpulan fungsi statis murni untuk aturan input pengguna
/// (normalisasi & validasi). Tidak bergantung pada UI maupun data.
class Validators {
  const Validators._();

  static const int minNameLength = 3;
  static const int minPhoneDigits = 10;
  static const int minTargetValue = 1;
  static const int minPasswordLength = 6;
  static final RegExp _digitsOnlyRegex = RegExp(r'^\d+$');
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Menormalkan input teks: `null` dianggap string kosong, spasi di
  /// awal/akhir dibuang.
  static String normalize(String? value) => value?.trim() ?? '';

  /// Menormalkan input opsional: mengembalikan `null` jika kosong setelah
  /// di-trim, selain itu mengembalikan nilai yang sudah di-trim.
  static String? normalizeOptional(String? value) {
    final normalized = normalize(value);
    return normalized.isEmpty ? null : normalized;
  }

  /// Validasi nama pengguna: wajib diisi dan minimal [minNameLength] karakter.
  static String? validateName(String? value) {
    final name = normalize(value);
    if (name.isEmpty) return 'Nama wajib diisi';
    if (name.length < minNameLength) {
      return 'Nama minimal $minNameLength karakter';
    }
    return null;
  }

  /// Validasi nomor telepon: opsional, namun jika diisi harus berupa angka
  /// dan minimal [minPhoneDigits] digit.
  static String? validatePhone(String? value) {
    final phone = normalizeOptional(value);
    if (phone == null) return null;
    if (!_digitsOnlyRegex.hasMatch(phone)) {
      return 'Nomor telepon harus berupa angka';
    }
    if (phone.length < minPhoneDigits) {
      return 'Nomor telepon minimal $minPhoneDigits digit';
    }
    return null;
  }

  /// Validasi email: wajib diisi (setelah di-trim) dan berformat email.
  static String? validateEmail(String? value) {
    final email = normalize(value);
    if (email.isEmpty) return 'Email tidak boleh kosong';
    if (!_emailRegex.hasMatch(email)) return 'Format email tidak valid';
    return null;
  }

  /// Validasi password: wajib diisi dan minimal [minPasswordLength] karakter.
  /// Password tidak di-trim karena spasi bisa jadi bagian dari password.
  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password tidak boleh kosong';
    if (password.length < minPasswordLength) {
      return 'Password minimal $minPasswordLength karakter';
    }
    return null;
  }

  /// Validasi konfirmasi password: wajib diisi dan harus sama dengan
  /// [password].
  static String? validatePasswordConfirmation(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Konfirmasi password tidak boleh kosong';
    if (value != password) return 'Password dan Konfirmasi Password harus cocok';
    return null;
  }

  /// Mengubah input target harian menjadi angka; `null` jika bukan angka bulat.
  static int? parseTargetValue(String? value) => int.tryParse(normalize(value));

  /// Validasi target harian: wajib diisi, angka bulat, minimal [minTargetValue].
  static String? validateTargetValue(String? value) {
    if (normalize(value).isEmpty) return 'Target wajib diisi';
    final target = parseTargetValue(value);
    if (target == null) return 'Target harus berupa angka';
    if (target < minTargetValue) return 'Target minimal $minTargetValue';
    return null;
  }
}
