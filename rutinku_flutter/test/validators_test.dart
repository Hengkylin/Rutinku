import 'package:flutter_test/flutter_test.dart';
import 'package:rutinku_flutter/utils/validators.dart';

void main() {
  group('Validators.normalize & normalizeOptional', () {
    test('normalize membuang spasi dan mengubah null menjadi string kosong', () {
      expect(Validators.normalize(null), '');
      expect(Validators.normalize('  Hengky  '), 'Hengky');
    });

    test('normalizeOptional mengembalikan null jika kosong setelah di-trim', () {
      expect(Validators.normalizeOptional(null), isNull);
      expect(Validators.normalizeOptional('   '), isNull);
      expect(Validators.normalizeOptional(' 0812345678 '), '0812345678');
    });
  });

  group('Validators.validateName', () {
    test('mengembalikan pesan error jika nilai null atau kosong', () {
      expect(Validators.validateName(null), isNotNull);
      expect(Validators.validateName(''), isNotNull);
      expect(Validators.validateName('   '), isNotNull);
    });

    test('mengembalikan pesan error jika kurang dari 3 karakter', () {
      expect(Validators.validateName('A'), isNotNull);
      expect(Validators.validateName('Ab'), isNotNull);
      expect(Validators.validateName('  ab  '), isNotNull);
    });

    test('mengembalikan null (valid) jika minimal 3 karakter', () {
      expect(Validators.validateName('Adi'), isNull);
      expect(Validators.validateName('Hengky'), isNull);
      expect(Validators.validateName('  Budi Santoso  '), isNull);
    });
  });

  group('Validators.validatePhone', () {
    test('mengembalikan null (valid) jika kosong atau null karena opsional', () {
      expect(Validators.validatePhone(null), isNull);
      expect(Validators.validatePhone(''), isNull);
      expect(Validators.validatePhone('   '), isNull);
    });

    test('mengembalikan pesan error jika mengandung karakter selain angka', () {
      expect(Validators.validatePhone('08123abc90'), isNotNull);
      expect(Validators.validatePhone('+62812345678'), isNotNull);
      expect(Validators.validatePhone('0812-3456-7890'), isNotNull);
    });

    test('mengembalikan pesan error jika berupa angka namun kurang dari 10 digit', () {
      expect(Validators.validatePhone('08123'), isNotNull);
      expect(Validators.validatePhone('081234567'), isNotNull);
    });

    test('mengembalikan null (valid) jika berupa angka minimal 10 digit', () {
      expect(Validators.validatePhone('0812345678'), isNull);
      expect(Validators.validatePhone('081234567890'), isNull);
      expect(Validators.validatePhone('  081234567890  '), isNull);
    });
  });

  group('Validators.validateEmail', () {
    test('wajib diisi dan harus berformat email', () {
      expect(Validators.validateEmail(null), 'Email tidak boleh kosong');
      expect(Validators.validateEmail('   '), 'Email tidak boleh kosong');
      expect(Validators.validateEmail('hengky'), 'Format email tidak valid');
      expect(Validators.validateEmail('a@b'), 'Format email tidak valid');
      expect(Validators.validateEmail('  user@mail.com  '), isNull);
    });
  });

  group('Validators.validatePassword & validatePasswordConfirmation', () {
    test('password wajib diisi dan minimal 6 karakter', () {
      expect(Validators.validatePassword(''), 'Password tidak boleh kosong');
      expect(Validators.validatePassword('12345'), 'Password minimal 6 karakter');
      expect(Validators.validatePassword('123456'), isNull);
    });

    test('konfirmasi wajib diisi dan harus sama dengan password', () {
      expect(
        Validators.validatePasswordConfirmation('', 'rahasia1'),
        'Konfirmasi password tidak boleh kosong',
      );
      expect(
        Validators.validatePasswordConfirmation('rahasia2', 'rahasia1'),
        'Password dan Konfirmasi Password harus cocok',
      );
      expect(Validators.validatePasswordConfirmation('rahasia1', 'rahasia1'), isNull);
    });
  });

  group('Validators.validateOtpCode', () {
    test('wajib diisi, hanya angka, dan tepat 6 digit', () {
      expect(Validators.validateOtpCode(''), 'Kode wajib diisi');
      expect(Validators.validateOtpCode('12a456'), 'Kode harus berupa angka');
      expect(Validators.validateOtpCode('12345'), 'Kode harus 6 digit');
      expect(Validators.validateOtpCode('1234567'), 'Kode harus 6 digit');
      expect(Validators.validateOtpCode(' 123456 '), isNull);
    });
  });

  group('Validators.validateUnit', () {
    test('opsional; teks valid, angka ditolak (angka diisi di Target harian)', () {
      expect(Validators.validateUnit(null), isNull);
      expect(Validators.validateUnit('   '), isNull);
      expect(Validators.validateUnit('gelas'), isNull);
      expect(Validators.validateUnit(' halaman '), isNull);
      expect(Validators.validateUnit('8'), isNotNull);
      expect(Validators.validateUnit('8 gelas'), isNotNull);
      expect(Validators.validateUnit('8'), contains('Target harian'));
    });
  });

  group('Validators.validateTargetValue', () {
    test('wajib diisi, harus angka bulat, dan minimal 1', () {
      expect(Validators.validateTargetValue(''), 'Target wajib diisi');
      expect(Validators.validateTargetValue('abc'), 'Target harus berupa angka');
      expect(Validators.validateTargetValue('0'), 'Target minimal 1');
      expect(Validators.validateTargetValue(' 8 '), isNull);
      expect(Validators.parseTargetValue(' 8 '), 8);
    });
  });
}

