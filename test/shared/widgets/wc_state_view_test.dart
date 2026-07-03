import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

void main() {
  testWidgets('WCStateView renders action and handles taps', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: WCStateView(
            icon: FluentIcons.error_circle_24_regular,
            title: '불러올 수 없습니다',
            message: '잠시 후 다시 시도해주세요',
            actionLabel: '다시 시도',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('불러올 수 없습니다'), findsOneWidget);
    expect(find.text('잠시 후 다시 시도해주세요'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    expect(tapped, isTrue);
  });

  testWidgets('WCCard exposes compact density padding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: WCCard(density: WCCardDensity.compact, child: Text('작은 카드')),
        ),
      ),
    );

    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text('작은 카드'), matching: find.byType(Container))
          .first,
    );

    expect(container.padding, const EdgeInsets.fromLTRB(16, 14, 16, 14));
  });
}
