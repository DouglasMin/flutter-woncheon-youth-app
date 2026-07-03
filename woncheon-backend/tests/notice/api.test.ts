import { beforeEach, describe, expect, it, vi } from 'vitest';

const { send } = vi.hoisted(() => ({
  send: vi.fn(),
}));

vi.mock('../../src/libs/dynamo.js', () => ({
  docClient: { send },
  TABLE_NAME: 'woncheon-test',
}));

import { handler as getNotice } from '../../src/functions/notice/get.js';
import { handler as listNotices } from '../../src/functions/notice/list.js';

describe('notice app api', () => {
  beforeEach(() => {
    send.mockReset();
  });

  it('lists published notices from GSI2 using the app response shape', async () => {
    send.mockResolvedValueOnce({
      Items: [
        {
          noticeId: 'NOTICE01',
          title: '이번 주 공지',
          content: '청년부 모임 안내입니다.',
          status: 'published',
          pinned: false,
          createdAt: '2026-07-03T01:00:00.000Z',
          updatedAt: '2026-07-03T01:00:00.000Z',
          publishedAt: '2026-07-03T01:05:00.000Z',
        },
      ],
    });

    const response = await listNotices(
      { queryStringParameters: { limit: '10' } } as never,
      {} as never,
      vi.fn(),
    );

    expect(response).toBeDefined();
    expect(send).toHaveBeenCalledTimes(1);
    expect(send.mock.calls[0][0].input).toMatchObject({
      TableName: 'woncheon-test',
      IndexName: 'GSI2',
      KeyConditionExpression: 'GSI2PK = :pk',
      FilterExpression: '#status = :published',
      ExpressionAttributeValues: {
        ':pk': 'NOTICE_LIST',
        ':published': 'published',
      },
    });
    expect(JSON.parse(response!.body)).toEqual({
      success: true,
      data: {
        items: [
          {
            noticeId: 'NOTICE01',
            title: '이번 주 공지',
            contentPreview: '청년부 모임 안내입니다.',
            pinned: false,
            publishedAt: '2026-07-03T01:05:00.000Z',
          },
        ],
        nextCursor: null,
        hasMore: false,
      },
    });
  });

  it('returns 404 for missing or unpublished notice detail', async () => {
    send.mockResolvedValueOnce({
      Item: {
        noticeId: 'NOTICE02',
        title: '임시 저장',
        content: '아직 게시 전입니다.',
        status: 'draft',
        pinned: false,
        createdAt: '2026-07-03T01:00:00.000Z',
        updatedAt: '2026-07-03T01:00:00.000Z',
      },
    });

    const response = await getNotice(
      { pathParameters: { noticeId: 'NOTICE02' } } as never,
      {} as never,
      vi.fn(),
    );

    expect(response).toBeDefined();
    expect(response!.statusCode).toBe(404);
    expect(JSON.parse(response!.body)).toMatchObject({
      success: false,
      error: { code: 'NOT_FOUND' },
    });
  });
});
