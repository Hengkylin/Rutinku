import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rutinku_flutter/screens/dashboard_screen.dart'; // Sesuaikan path jika error

void main() {
  testWidgets('Dashboard UI States & Form Validation Test', (WidgetTester tester) async {
    // 1. Bungkus screen dengan ProviderScope dan MaterialApp
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // --- UJI KONDISI 1: Initial Loading ---
    // Saat pertama kali dirender, CircularProgressIndicator loading harus muncul
    expect(
      find.byWidgetPredicate(
        (w) => w is CircularProgressIndicator && w.value == null,
      ),
      findsOneWidget,
    );

    // Tunggu mock delay 2 detik selesai
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // --- UJI KONDISI 2: Empty State ---
    // Indikator loading hilang, diganti dengan teks empty state
    expect(
      find.byWidgetPredicate(
        (w) => w is CircularProgressIndicator && w.value == null,
      ),
      findsNothing,
    );
    expect(find.text('Belum ada rutinitas.\nYuk, buat kebiasaan pertamamu!'), findsOneWidget);

    // --- UJI KONDISI 5: Validasi Form ---
    // Buka bottom sheet / dialog form
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle(); // Tunggu animasi dialog selesai

    // Tekan tombol simpan saat teks kosong
    await tester.tap(find.text('Simpan'));
    await tester.pump(); // Render ulang UI untuk menampilkan error

    // Pastikan teks validasi merah muncul
    expect(find.text('Nama kebiasaan tidak boleh kosong'), findsOneWidget);
  });
}