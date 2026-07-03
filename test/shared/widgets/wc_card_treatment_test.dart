import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

void main() {
  testWidgets('WCCard uses the standard card radius', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: WCCard(child: Text('카드'))),
      ),
    );

    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text('카드'), matching: find.byType(Container))
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.borderRadius, BorderRadius.circular(WCRadius.card));
  });
}
