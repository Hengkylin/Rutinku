/// Kumpulan fungsi statis murni untuk aturan input pengguna
/// (normalisasi & validasi). Tidak bergantung pada UI maupun data.
class Validators {
  const Validators._();

  static const int minNameLength = 3;
  static const int minPhoneDigits = 10;
  static const int minTargetValue = 1;
  static const int minPasswordLength = 6;

  /// Panjang kode reset password dari email. Harus sama dengan pengaturan
  /// "Email OTP Length" di Supabase Dashboard.
  static const int otpLength = 6;
  static final RegExp _digitsOnlyRegex = RegExp(r'^\d+$');
  static final RegExp _startsWithDigitRegex = RegExp(r'^\d');
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Karakter yang tampil kosong tetapi TIDAK dibuang oleh `String.trim()`:
  /// soft hyphen, Hangul filler, zero-width space/joiner, tanda arah teks,
  /// word joiner, braille blank, dsb. Dipakai untuk membuat nama "kosong".
  static final RegExp _invisibleCharsRegex = RegExp(
    '[\u00AD\u034F\u115F\u1160\u17B4\u17B5\u180E\u200B-\u200F'
    '\u202A-\u202E\u2060-\u2064\u206A-\u206F\u2800\u3164\uFEFF\uFFA0]',
  );
  static final RegExp _whitespaceRunRegex = RegExp(r'\s+');
  static final RegExp _letterOrDigitRegex =
      RegExp(r'[\p{L}\p{N}]', unicode: true);

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

  /// Menormalkan nama kebiasaan: membuang karakter tak terlihat, merapikan
  /// spasi berurutan menjadi satu spasi, lalu trim.
  static String normalizeHabitTitle(String? value) => (value ?? '')
      .replaceAll(_invisibleCharsRegex, '')
      .replaceAll(_whitespaceRunRegex, ' ')
      .trim();

  /// Validasi nama kebiasaan (form tambah & edit rutinitas): setelah
  /// dinormalkan wajib diisi, minimal [minNameLength] karakter, dan memuat
  /// minimal satu huruf atau angka (menolak nama seperti "..." atau "---").
  static String? validateHabitTitle(String? value) {
    final title = normalizeHabitTitle(value);
    if (title.isEmpty) return 'Nama kebiasaan tidak boleh kosong';
    if (title.length < minNameLength) return 'Minimal $minNameLength karakter';
    if (!_letterOrDigitRegex.hasMatch(title)) {
      return 'Nama kebiasaan harus berisi huruf atau angka';
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

  /// Validasi kode reset password: wajib diisi, hanya angka, tepat
  /// [otpLength] digit.
  static String? validateOtpCode(String? value) {
    final code = normalize(value);
    if (code.isEmpty) return 'Kode wajib diisi';
    if (!_digitsOnlyRegex.hasMatch(code)) return 'Kode harus berupa angka';
    if (code.length != otpLength) return 'Kode harus $otpLength digit';
    return null;
  }

  /// Validasi satuan target (opsional): harus berupa teks seperti "gelas".
  /// Ditolak jika diawali angka (mis. "8" atau "8 gelas"), karena jumlahnya
  /// seharusnya diisi di Target harian; jika tidak, target tetap 1 dan
  /// tombol [+] tidak muncul di kartu.
  static String? validateUnit(String? value) {
    final unit = normalizeOptional(value);
    if (unit == null) return null;
    if (_startsWithDigitRegex.hasMatch(unit)) {
      return 'Isi teks, mis. gelas. Jumlahnya diisi di Target harian.';
    }
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
