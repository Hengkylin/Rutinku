import 'package:flutter_test/flutter_test.dart';
import 'package:rutinku_flutter/app.dart';

void main() {
  testWidgets('App renders login screen test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Halaman Login'), findsWidgets);
  });
}
