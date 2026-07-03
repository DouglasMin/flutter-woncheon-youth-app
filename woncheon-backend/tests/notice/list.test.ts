import { describe, expect, it } from 'vitest';
import { toNoticeListItem } from '../../src/types/notice.js';

describe('notice mapping', () => {
  it('maps a DynamoDB notice item to the app list shape', () => {
    const item = {
      noticeId: 'NOTICE01',
      title: '이번 주 청년부 안내',
      content: '금요 성령집회 후 청년부 모임이 있습니다.',
      status: 'published',
      pinned: true,
      createdAt: '2026-07-03T01:00:00.000Z',
      updatedAt: '2026-07-03T01:10:00.000Z',
      publishedAt: '2026-07-03T01:20:00.000Z',
    };

    expect(toNoticeListItem(item)).toEqual({
      noticeId: 'NOTICE01',
      title: '이번 주 청년부 안내',
      contentPreview: '금요 성령집회 후 청년부 모임이 있습니다.',
      pinned: true,
      publishedAt: '2026-07-03T01:20:00.000Z',
    });
  });

  it('truncates long content previews', () => {
    const longContent = '가'.repeat(160);
    const item = {
      noticeId: 'NOTICE02',
      title: '긴 공지',
      content: longContent,
      status: 'published',
      pinned: false,
      createdAt: '2026-07-03T01:00:00.000Z',
      updatedAt: '2026-07-03T01:10:00.000Z',
      publishedAt: '2026-07-03T01:20:00.000Z',
    };

    expect(toNoticeListItem(item).contentPreview).toBe(`${'가'.repeat(120)}...`);
  });
});
