import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dice_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(LudoFunApp());

    // You can remove the counter tests since your app doesn’t have them.
    expect(find.text('Ludo Fun!'), findsOneWidget);
  });
}
