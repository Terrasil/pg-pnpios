import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pnpios/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Aplikacja uruchamia główny widok', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const BookFinderApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}