import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/shared/widgets/tab_shell.dart';

void main() {
  testWidgets('WCTabBar shows a selected pill and reports taps', (
    tester,
  ) async {
    var tapped = -1;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: WCTabBar(
            currentIndex: 1,
            onTap: (index) => tapped = index,
          ),
        ),
      ),
    );

    final selected = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('기도'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(selected.decoration, isA<BoxDecoration>());

    await tester.tap(find.text('목장'));
    expect(tapped, 2);
  });
}
