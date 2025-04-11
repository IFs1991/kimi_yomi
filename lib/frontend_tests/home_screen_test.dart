import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:your_app/lib/screens/home_screen.dart';
import 'package:your_app/lib/widgets/diagnosis_card.dart';
import 'package:your_app/lib/widgets/compatibility_chart.dart';

void main() {
  testWidgets('HomeScreen displays diagnosis results and compatibility chart', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: HomeScreen()));

    // Verify that the diagnosis card is displayed.
    expect(find.byType(DiagnosisCard), findsOneWidget);

    // Verify that the compatibility chart is displayed.
    expect(find.byType(CompatibilityChart), findsOneWidget);

    // You can add more specific tests here, such as checking for specific text or widget properties.
    // For example:
    // expect(find.text('Your Diagnosis Result'), findsOneWidget);
    // expect(find.text('Compatibility Chart'), findsOneWidget);
  });
};