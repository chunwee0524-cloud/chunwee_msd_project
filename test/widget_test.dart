import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:chunwee_msdproject/app.dart';

void main() {
  testWidgets('App loads and shows bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Diary'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Switch to Water tab', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Water'));
    await tester.pumpAndSettle();

    expect(find.text('Water Intake'), findsOneWidget);
  });
}