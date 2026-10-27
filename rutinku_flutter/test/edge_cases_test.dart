import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/screens/calendar_screen.dart';
import 'package:rutinku_flutter/services/notification_service.dart';
import 'package:rutinku_flutter/widgets/add_habit_bottom_sheet.dart';
import 'package:rutinku_flutter/widgets/edit_habit_bottom_sheet.dart';

/// Pertemuan Ke-7: Uji input tidak valid & edge cases (Habit Form,
/// Empty State, dan izin notifikasi yang aman).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('AddHabitBottomSheet - validasi input tidak valid', () {
    testWidgets('menolak nama kebiasaan kosong', (tester) async {
      await tester.pumpWidget(wrap(const AddHabitBottomSheet()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan'));
      await tester.pump();

      expect(find.text('Nama kebiasaan tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('menolak nama kebiasaan yang hanya berisi spasi', (tester) async {
      await tester.pumpWidget(wrap(const AddHabitBottomSheet()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '     ');
      await tester.tap(find.text('Simpan'));
      await tester.pump();

      expect(find.text('Nama kebiasaan tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('menolak nama kebiasaan kurang dari 3 karakter', (tester) async {
      await tester.pumpWidget(wrap(const AddHabitBottomSheet()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '  ab  ');
      await tester.tap(find.text('Simpan'));
      await tester.pump();

      expect(find.text('Minimal 3 karakter'), findsOneWidget);
      expect(find.text('Nama kebiasaan tidak boleh kosong'), findsNothing);
    });

    testWidgets('nama valid tidak menampilkan pesan error', (tester) async {
      await tester.pumpWidget(wrap(const AddHabitBottomSheet()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Minum Air');
      await tester.tap(find.text('Simpan'));
      await tester.pump();

      expect(find.text('Nama kebiasaan tidak boleh kosong'), findsNothing);
      expect(find.text('Minimal 3 karakter'), findsNothing);

      // Selesaikan proses simpan async agar tidak ada timer tersisa
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });
  });

  group('EditHabitBottomSheet - validasi input tidak valid', () {
    final habit = HabitModel(id: 'h1', title: 'Baca Buku', category: 'Belajar');

    testWidgets('menolak ketika nama dikosongkan', (tester) async {
      await tester.pumpWidget(wrap(EditHabitBottomSheet(habit: habit)));
      await tester.pumpAndSettle();

      // Form terisi otomatis dengan data lama
      expect(find.text('Baca Buku'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.tap(find.text('Simpan perubahan'));
      await tester.pump();

      expect(find.text('Nama kebiasaan tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('menolak ketika nama hanya berisi spasi', (tester) async {
      await tester.pumpWidget(wrap(EditHabitBottomSheet(habit: habit)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '   ');
      await tester.tap(find.text('Simpan perubahan'));
      await tester.pump();

      expect(find.text('Nama kebiasaan tidak boleh kosong'), findsOneWidget);
    });
  });

  group('Empty State', () {
    testWidgets('CalendarScreen menampilkan empty state saat data kosong',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Belum ada kebiasaan yang dibuat.'), findsOneWidget);
      expect(find.byIcon(Icons.event_busy_rounded), findsOneWidget);
    });
  });

  group('NotificationService - izin notifikasi aman', () {
    test('requestPermission tidak melempar exception tanpa native channel',
        () async {
      await expectLater(
        NotificationService().requestPermission(),
        completes,
      );
    });

    test('init lalu requestPermission berulang tetap aman', () async {
      final service = NotificationService();
      await service.init();
      await expectLater(service.requestPermission(), completes);
      await expectLater(service.requestPermission(), completes);
    });
  });
}
