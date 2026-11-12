import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutinku_flutter/screens/log_viewer_screen.dart';

void main() {
  late String storedLogs;
  late int clearCalls;

  setUp(() {
    storedLogs = '2026-11-12 08:00:00.000 INFO    [rutinku.app] mulai\n'
        '2026-11-12 08:00:01.000 SEVERE  [rutinku.sync] Gagal backup\n';
    clearCalls = 0;
  });

  Widget screen() => MaterialApp(
        home: LogViewerScreen(
          readLogs: () async => storedLogs,
          clearLogs: () async {
            clearCalls++;
            storedLogs = '';
          },
        ),
      );

  testWidgets('menampilkan isi log', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.textContaining('[rutinku.sync] Gagal backup'), findsOneWidget);
  });

  testWidgets('Salin menyalin seluruh log ke clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('log_copy_button')));
    await tester.pumpAndSettle();

    expect(copied, storedLogs);
    expect(find.textContaining('Log disalin'), findsOneWidget);
  });

  testWidgets('Hapus meminta konfirmasi lalu mengosongkan log', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('log_clear_button')));
    await tester.pumpAndSettle();
    expect(clearCalls, 0); // belum dihapus sebelum dikonfirmasi

    await tester.tap(find.byKey(const Key('log_clear_confirm')));
    await tester.pumpAndSettle();

    expect(clearCalls, 1);
    expect(find.text('Belum ada log'), findsOneWidget);
  });

  testWidgets('Muat ulang membaca log terbaru', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    storedLogs += '2026-11-12 08:00:02.000 INFO    [rutinku.auth] baru\n';
    await tester.tap(find.byKey(const Key('log_reload_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('[rutinku.auth] baru'), findsOneWidget);
  });

  testWidgets('log kosong menampilkan pesan kosong', (tester) async {
    storedLogs = '';
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('Belum ada log'), findsOneWidget);
  });
}
