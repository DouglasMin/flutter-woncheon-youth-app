import type { APIGatewayProxyEvent, Callback, Context } from 'aws-lambda';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { handler } from '../../src/functions/notice/list.js';
import { toNoticeListItem } from '../../src/types/notice.js';
import type { NoticeRecord } from '../../src/types/notice.js';

const { mockDocClientSend } = vi.hoisted(() => ({
  mockDocClientSend: vi.fn(),
}));

vi.mock('../../src/libs/dynamo.js', () => ({
  docClient: { send: mockDocClientSend },
  TABLE_NAME: 'woncheon-test',
}));

const mockContext = {} as Context;
const mockCallback: Callback = vi.fn();

function makeEvent(
  queryStringParameters: Record<string, string>,
): APIGatewayProxyEvent {
  return {
    queryStringParameters,
    pathParameters: null,
    headers: {},
    multiValueHeaders: {},
    httpMethod: 'GET',
    isBase64Encoded: false,
    path: '/notices',
    resource: '/notices',
    body: null,
    multiValueQueryStringParameters: null,
    stageVariables: null,
    requestContext: {} as APIGatewayProxyEvent['requestContext'],
  };
}

function makeNotice(overrides: Partial<NoticeRecord>): NoticeRecord {
  const noticeId = overrides.noticeId ?? 'NOTICE';
  const createdAt = overrides.createdAt ?? '2026-07-14T00:00:00.000Z';

  return {
    PK: `NOTICE#${noticeId}`,
    SK: '#META',
    GSI2PK: 'NOTICE_LIST',
    GSI2SK: `${createdAt}#${noticeId}`,
    noticeId,
    title: '공지',
    content: '공지 내용',
    status: 'published',
    pinned: false,
    createdAt,
    updatedAt: '2026-07-14T00:00:00.000Z',
    publishedAt: '2026-07-14T00:00:00.000Z',
    ...overrides,
  };
}

beforeEach(() => {
  mockDocClientSend.mockReset();
});

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

  it('does not return an empty page when drafts are present before published notices', async () => {
    mockDocClientSend.mockResolvedValueOnce({
      Items: [
        makeNotice({ noticeId: 'DRAFT01', status: 'draft' }),
        makeNotice({ noticeId: 'NOTICE01', status: 'published' }),
      ],
      LastEvaluatedKey: undefined,
    });

    const res = await handler(
      makeEvent({ limit: '2' }),
      mockContext,
      mockCallback,
    );
    const body = JSON.parse(res.body) as {
      data: { items: Array<{ noticeId: string }>; hasMore: boolean };
    };

    expect(body.data.items.map((item) => item.noticeId)).toEqual(['NOTICE01']);
    expect(body.data.hasMore).toBe(false);
    expect(mockDocClientSend.mock.calls[0][0].input.Limit).toBe(6);
  });

  it('uses the last returned notice as cursor when a widened query returns more than the public limit', async () => {
    mockDocClientSend.mockResolvedValueOnce({
      Items: [
        makeNotice({ noticeId: 'NOTICE01' }),
        makeNotice({ noticeId: 'NOTICE02' }),
        makeNotice({ noticeId: 'NOTICE03' }),
      ],
      LastEvaluatedKey: undefined,
    });

    const res = await handler(
      makeEvent({ limit: '2' }),
      mockContext,
      mockCallback,
    );
    const body = JSON.parse(res.body) as {
      data: {
        items: Array<{ noticeId: string }>;
        hasMore: boolean;
        nextCursor: string | null;
      };
    };

    expect(body.data.items.map((item) => item.noticeId)).toEqual([
      'NOTICE01',
      'NOTICE02',
    ]);
    expect(body.data.hasMore).toBe(true);
    expect(
      JSON.parse(Buffer.from(body.data.nextCursor!, 'base64').toString('utf-8')),
    ).toMatchObject({
      PK: 'NOTICE#NOTICE02',
      SK: '#META',
      GSI2PK: 'NOTICE_LIST',
    });
  });
});
