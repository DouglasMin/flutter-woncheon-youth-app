import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/home/presentation/home_page.dart';

void main() {
  testWidgets('VerseHeroCard exposes verse, reference, and open affordance', (
    tester,
  ) async {
    var opened = false;
    var shuffled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: VerseHeroCard(
            verse: const {
              'short': '내게 능력 주시는 자 안에서',
              'full': '내게 능력 주시는 자 안에서 내가 모든 것을 할 수 있느니라',
              'ref': '빌립보서 4:13',
            },
            onShuffle: () => shuffled = true,
            onTap: () => opened = true,
          ),
        ),
      ),
    );

    expect(find.textContaining('내게 능력 주시는 자 안에서'), findsOneWidget);
    expect(find.text('빌립보서 4:13'), findsOneWidget);
    expect(find.text('말씀 열기'), findsOneWidget);

    await tester.tap(find.text('말씀 열기'));
    expect(opened, isTrue);

    await tester.tap(find.byTooltip('말씀 바꾸기'));
    expect(shuffled, isTrue);
  });
}
