import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutinku_flutter/screens/dashboard_screen.dart';
import 'package:rutinku_flutter/screens/template_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TemplateScreen Tests', () {
    testWidgets('renders categories, items, and custom option correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TemplateScreen(),
        ),
      );

      // Verify app bar title
      expect(find.text('Templat Tugas'), findsOneWidget);

      // Verify category Kesehatan and sample items
      expect(find.text('Kesehatan'), findsOneWidget);
      expect(
          find.text('Minum air putih, jaga kesehatan'), findsOneWidget);
      expect(find.text('Menyikat gigi'), findsOneWidget);
      expect(find.text('Mandi'), findsOneWidget);

      // Verify pop: true has fire emoji
      expect(find.text('🔥'), findsWidgets);

      // Scroll to verify Kehidupan and custom option
      await tester.scrollUntilVisible(
        find.text('Kehidupan'),
        300.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Kehidupan'), findsOneWidget);
      expect(find.text('Belajar'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Buat Kebiasaan Sendiri'),
        300.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Buat Kebiasaan Sendiri'), findsOneWidget);
    });

    testWidgets('tapping template item returns Map with title and category',
        (tester) async {
      dynamic poppedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                poppedResult = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemplateScreen(),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Minum air putih, jaga kesehatan'));
      await tester.pumpAndSettle();

      expect(poppedResult, {
        'title': 'Minum air putih, jaga kesehatan',
        'category': 'Kesehatan',
      });
    });

    testWidgets('tapping Buat Kebiasaan Sendiri returns custom string',
        (tester) async {
      dynamic poppedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                poppedResult = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemplateScreen(),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Buat Kebiasaan Sendiri'),
        500.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Buat Kebiasaan Sendiri'));
      await tester.pumpAndSettle();

      expect(poppedResult, 'custom');
    });

    testWidgets(
        'selecting template pre-fills AddHabitBottomSheet on DashboardScreen',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      // Wait for initial fetch
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap FAB to open TemplateScreen
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Tap a template
      await tester.tap(find.text('Minum air putih, jaga kesehatan'));
      await tester.pumpAndSettle();

      // Verify AddHabitBottomSheet is shown with prefilled data
      expect(find.text('Tambah kebiasaan'), findsOneWidget);
      expect(find.text('Minum air putih, jaga kesehatan'), findsOneWidget);
      expect(find.text('Kesehatan'), findsOneWidget);
    });
  });
}
