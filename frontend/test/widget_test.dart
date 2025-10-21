import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medrush/main.dart';

void main() {
  testWidgets('MedRush app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MedRushApp());

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
