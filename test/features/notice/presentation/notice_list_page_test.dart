import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/features/notice/domain/notice_model.dart';
import 'package:woncheon_youth/features/notice/presentation/notice_list_page.dart';

void main() {
  testWidgets('NoticeCard exposes title, preview, and pinned badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoticeCard(
            notice: const NoticeItem(
              noticeId: 'NOTICE01',
              title: '이번 주 공지',
              contentPreview: '청년부 모임 안내입니다.',
              pinned: true,
              publishedAt: '2026-07-03T01:05:00.000Z',
            ),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('이번 주 공지'), findsOneWidget);
    expect(find.text('청년부 모임 안내입니다.'), findsOneWidget);
    expect(find.text('고정'), findsOneWidget);
  });
}
