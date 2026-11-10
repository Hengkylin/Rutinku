import 'package:flutter_test/flutter_test.dart';
import 'package:rutinku_flutter/utils/validators.dart';

void main() {
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
}

