import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

void main() {
  testWidgets('WCPageScaffold renders shared header and page padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const WCPageScaffold(
          header: WCHeader(eyebrow: '오늘', title: '홈', subtitle: '함께 연결되는 화면'),
          child: Text('본문'),
        ),
      ),
    );

    expect(find.text('오늘'), findsOneWidget);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('함께 연결되는 화면'), findsOneWidget);
    expect(find.text('본문'), findsOneWidget);

    final contentPadding = tester.widget<Padding>(
      find.ancestor(of: find.text('본문'), matching: find.byType(Padding)).first,
    );
    expect(
      contentPadding.padding,
      const EdgeInsets.symmetric(horizontal: WCSpacing.pageX),
    );
  });
}
