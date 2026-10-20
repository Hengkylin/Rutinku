import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rutinku_flutter/notifiers/sync_notifier.dart';
import 'package:rutinku_flutter/screens/sync_screen.dart';

import 'api_sync_test.dart';

void main() {
  testWidgets('SyncScreen renders loading state initially when fetching', (tester) async {
    final mockClient = MockClient((request) async {
      // Delay to test loading state
      await Future.delayed(const Duration(milliseconds: 500));
      return http.Response('[]', 200);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncHttpClientProvider.overrideWithValue(mockClient),
        ],
        child: const MaterialApp(
          home: SyncScreen(),
        ),
      ),
    );

    // Initial post frame callback triggers fetchData() -> Loading
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Menyinkronkan data...'), findsOneWidget);

    // Finish async call
    await tester.pumpAndSettle();
  });

  testWidgets('SyncScreen renders Empty State when API returns empty list', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response('[]', 200);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncHttpClientProvider.overrideWithValue(mockClient),
        ],
        child: const MaterialApp(
          home: SyncScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Data di cloud masih kosong'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
  });

  testWidgets('SyncScreen renders Success State with ListView and Backup button', (tester) async {
    final mockData = [
      {'userId': 1, 'id': 1, 'title': 'Kebiasaan Cloud 1', 'completed': false},
      {'userId': 1, 'id': 2, 'title': 'Kebiasaan Cloud 2', 'completed': true},
    ];

    final mockClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode(mockData),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('{"id": 201}', 201);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncHttpClientProvider.overrideWithValue(mockClient),
        ],
        child: const MaterialApp(
          home: SyncScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kebiasaan Cloud 1'), findsOneWidget);
    expect(find.text('Kebiasaan Cloud 2'), findsOneWidget);
    expect(find.text('Backup Data Lokal ke Cloud'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);

    // Tap backup button
    await tester.tap(find.text('Backup Data Lokal ke Cloud'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('SyncScreen renders Error State with warning icon and Coba Lagi button', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response('Internal Server Error', 500);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncHttpClientProvider.overrideWithValue(mockClient),
        ],
        child: const MaterialApp(
          home: SyncScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
