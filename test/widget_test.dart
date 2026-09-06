import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_boilerplate/shared/widgets/app_button.dart';

void main() {
  testWidgets('AppButton shows a spinner and disables tap while loading',
      (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Go',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Go'), findsNothing);

    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(tapped, isFalse);
  });
}
