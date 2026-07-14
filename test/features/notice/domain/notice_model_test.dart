import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/features/notice/domain/notice_model.dart';

void main() {
  test('NoticeListResponse parses notice list JSON', () {
    final response = NoticeListResponse.fromJson({
      'items': [
        {
          'noticeId': 'NOTICE01',
          'title': '이번 주 공지',
          'contentPreview': '청년부 모임 안내입니다.',
          'pinned': true,
          'publishedAt': '2026-07-03T01:05:00.000Z',
        },
      ],
      'hasMore': false,
      'nextCursor': null,
    });

    expect(response.items, hasLength(1));
    expect(response.items.single.noticeId, 'NOTICE01');
    expect(response.items.single.pinned, isTrue);
    expect(response.hasMore, isFalse);
    expect(response.nextCursor, isNull);
  });

  test('NoticeDetail parses notice detail JSON', () {
    final detail = NoticeDetail.fromJson({
      'noticeId': 'NOTICE01',
      'title': '이번 주 공지',
      'content': '청년부 모임 안내입니다.',
      'pinned': false,
      'publishedAt': '2026-07-03T01:05:00.000Z',
    });

    expect(detail.title, '이번 주 공지');
    expect(detail.content, '청년부 모임 안내입니다.');
  });
}
