import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:rutinku_flutter/models/habit_model.dart';
import 'package:rutinku_flutter/repositories/habit_repository.dart';
import 'package:rutinku_flutter/screens/analytics_screen.dart';
import 'package:rutinku_flutter/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final today = DateTime.now();
  DateTime daysAgo(int i) => DateTime(today.year, today.month, today.day - i);
  String key(int i) => DateFormat('yyyy-MM-dd').format(daysAgo(i));

  Future<void> pumpScreen(
    WidgetTester tester,
    List<HabitModel> habits, {
    Size size = const Size(360, 690),
    double textScale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({
      HabitRepository.storageKey:
          json.encode(habits.map((h) => h.toMap()).toList()),
    });
    // Ukuran layar HP agar overflow tata letak ikut terdeteksi.
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          // Simulasi pengaturan ukuran teks sistem pengguna.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: const AnalyticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('data kosong menampilkan pesan kosong', (tester) async {
    await pumpScreen(tester, []);

    expect(find.text('Belum ada data analitik'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
  });

  testWidgets('menampilkan ringkasan, grafik, dan selisih positif hijau',
      (tester) async {
    // Minggu ini 7/7 selesai, minggu lalu 0/7 (dilewati) → +100%.
    final habit = HabitModel(
      id: '1',
      title: 'Minum Air',
      records: [
        for (var i = 0; i < 7; i++) HabitRecord(date: key(i)),
        for (var i = 7; i < 14; i++)
          HabitRecord(date: key(i), status: 'skipped'),
      ],
    );
    final expectedMissedDay =
        AnalyticsService([habit]).getMostMissedDay(); // hari dari data nyata

    await pumpScreen(tester, [habit]);

    final consistent = find.byKey(const Key('analytics_most_consistent'));
    expect(
      find.descendant(of: consistent, matching: find.text('Minum Air')),
      findsOneWidget,
    );
    final missed = find.byKey(const Key('analytics_most_missed_day'));
    expect(
      find.descendant(of: missed, matching: find.text(expectedMissedDay!)),
      findsOneWidget,
    );

    expect(find.byType(BarChart), findsOneWidget);
    final delta = tester.widget<Text>(
      find.byKey(const Key('analytics_weekly_delta')),
    );
    expect(delta.data, '+100% dari minggu lalu');
    expect(delta.style?.color, const Color(0xFF16A34A));
  });

  group('layar sempit (issue #8)', () {
    final longHabit = HabitModel(
      id: '1',
      title: 'Membaca Buku Harian',
      records: [
        for (var i = 0; i < 7; i++) HabitRecord(date: key(i)),
        for (var i = 7; i < 14; i++)
          HabitRecord(date: key(i), status: 'skipped'),
      ],
    );
    final consistent = find.byKey(const Key('analytics_most_consistent'));
    final missed = find.byKey(const Key('analytics_most_missed_day'));

    testWidgets('layar 360dp: kartu ringkasan berdampingan', (tester) async {
      await pumpScreen(tester, [longHabit]);

      expect(tester.getTopLeft(missed).dy, tester.getTopLeft(consistent).dy);
      expect(
        tester.getTopLeft(missed).dx,
        greaterThan(tester.getTopRight(consistent).dx),
      );
    });

    testWidgets('layar 320dp: kartu ditumpuk dan judul tidak terpotong',
        (tester) async {
      await pumpScreen(tester, [longHabit], size: const Size(320, 640));

      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(missed).dy,
        greaterThan(tester.getBottomLeft(consistent).dy),
      );
      // Kartu memakai lebar penuh sehingga judul muat utuh. Di test semua
      // huruf berupa kotak selebar ukuran font (17px), jadi judul ini butuh
      // 2 baris di 320dp tetapi 3 baris (terpotong) jika kartu berdampingan.
      final title = find.descendant(
        of: consistent,
        matching: find.text('Membaca Buku Harian'),
      );
      expect(title, findsOneWidget);
      expect(
        (tester.renderObject(title) as dynamic).didExceedMaxLines as bool,
        isFalse,
      );
    });

    testWidgets('layar 320dp + teks 130%: grafik tanpa overflow',
        (tester) async {
      await pumpScreen(
        tester,
        [longHabit],
        size: const Size(320, 640),
        textScale: 1.3,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('analytics_weekly_delta')),
        200,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('Minggu Lalu'), findsOneWidget);
      expect(find.text('Minggu Ini'), findsOneWidget);
    });
  });

  group('formatProgressDelta', () {
    test('format tanda, desimal koma, dan nilai nol', () {
      expect(
        AnalyticsScreen.formatProgressDelta(500 / 28),
        '+17,9% dari minggu lalu',
      );
      expect(AnalyticsScreen.formatProgressDelta(-5), '-5% dari minggu lalu');
      expect(AnalyticsScreen.formatProgressDelta(0), 'Sama dengan minggu lalu');
    });
  });
}
