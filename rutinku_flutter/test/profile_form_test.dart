import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinku_flutter/repositories/profile_repository.dart';
import 'package:rutinku_flutter/widgets/profile_form.dart';

/// Repository palsu agar pengujian tidak menembak Supabase sungguhan.
class FakeProfileRepository extends ProfileRepository {
  FakeProfileRepository({this.error});

  final Object? error;
  int calls = 0;
  String? savedName;
  String? savedPhone;

  @override
  Future<void> updateProfile(String name, String? phone) async {
    calls++;
    savedName = name;
    savedPhone = phone;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (error != null) throw error!;
  }
}

void main() {
  Future<void> pumpForm(
    WidgetTester tester, {
    required FakeProfileRepository repository,
    VoidCallback? onSaveSuccess,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileForm(
              repository: repository,
              onSaveSuccess: onSaveSuccess,
            ),
          ),
        ),
      ),
    );
  }

  final nameField = find.byKey(const Key('profile_name_field'));
  final phoneField = find.byKey(const Key('profile_phone_field'));
  final saveButton = find.byKey(const Key('profile_save_button'));

  testWidgets('nama kosong menampilkan error dan repository tidak dipanggil',
      (tester) async {
    final repo = FakeProfileRepository();
    await pumpForm(tester, repository: repo);

    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('Nama wajib diisi'), findsOneWidget);
    expect(repo.calls, 0);
  });

  testWidgets('telepon bukan angka menampilkan error validasi',
      (tester) async {
    final repo = FakeProfileRepository();
    await pumpForm(tester, repository: repo);

    await tester.enterText(nameField, 'Hengky');
    await tester.enterText(phoneField, '0812abc');
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('Nomor telepon harus berupa angka'), findsOneWidget);
    expect(repo.calls, 0);
  });

  testWidgets(
      'input valid: loading tampil, data ter-trim dikirim, callback sukses dipanggil',
      (tester) async {
    final repo = FakeProfileRepository();
    var successCount = 0;
    await pumpForm(
      tester,
      repository: repo,
      onSaveSuccess: () => successCount++,
    );

    await tester.enterText(nameField, '  Hengky  ');
    await tester.enterText(phoneField, '   ');
    await tester.tap(saveButton);
    await tester.pump();

    // Status loading saat request berjalan
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(repo.calls, 1);
    expect(repo.savedName, 'Hengky');
    expect(repo.savedPhone, isNull);
    expect(successCount, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('repository gagal: SnackBar merah tampil tanpa prefix Exception',
      (tester) async {
    final repo = FakeProfileRepository(
      error: Exception('Gagal memperbarui profil di database: timeout'),
    );
    var successCount = 0;
    await pumpForm(
      tester,
      repository: repo,
      onSaveSuccess: () => successCount++,
    );

    await tester.enterText(nameField, 'Hengky');
    await tester.enterText(phoneField, '081234567890');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(repo.savedPhone, '081234567890');
    expect(successCount, 0);
    expect(
      find.text('Gagal memperbarui profil di database: timeout'),
      findsOneWidget,
    );
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, Colors.red.shade600);
  });
}

