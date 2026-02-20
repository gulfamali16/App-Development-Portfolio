// Widget tests for the Video Downloader app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:video_downloader_app/main.dart';

void main() {
  testWidgets('MyApp renders without crashing', (WidgetTester tester) async {
    // Build the app and trigger an initial frame.
    await tester.pumpWidget(const MyApp());

    // Allow async initState operations (database init) to settle.
    await tester.pump();

    // The app title 'Video Downloader' should appear in the home screen header.
    expect(find.text('Video Downloader'), findsWidgets);
  });

  testWidgets('Home screen shows Analyze Link button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Analyze Link'), findsOneWidget);
  });

  testWidgets('Home screen shows platform toggle buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('YouTube'), findsWidgets);
    expect(find.text('Instagram'), findsOneWidget);
  });
}
