import { beforeEach, describe, expect, it, vi } from 'vitest';

const { publishNoticeToAllDevices, send } = vi.hoisted(() => ({
  publishNoticeToAllDevices: vi.fn(),
  send: vi.fn(),
}));

vi.mock('../../src/libs/dynamo.js', () => ({
  docClient: { send },
  TABLE_NAME: 'woncheon-test',
}));

vi.mock('../../src/libs/device-notifications.js', () => ({
  publishNoticeToAllDevices,
}));

import { handler } from '../../src/functions/notice/sendNotification.js';

function image(values: {
  noticeId: string;
  title?: string;
  content?: string;
  status: 'draft' | 'published';
  notifiedAt?: string;
}) {
  return {
    noticeId: { S: values.noticeId },
    title: { S: values.title ?? '공지 제목' },
    content: { S: values.content ?? '공지 내용' },
    status: { S: values.status },
    ...(values.notifiedAt ? { notifiedAt: { S: values.notifiedAt } } : {}),
  };
}

describe('notice stream notification worker', () => {
  beforeEach(() => {
    publishNoticeToAllDevices.mockReset();
    send.mockReset();
    delete process.env.NOTICE_PUSH_ENABLED;
  });

  it('sends one push and records notifiedAt when a draft is first published', async () => {
    process.env.NOTICE_PUSH_ENABLED = 'true';
    send.mockResolvedValue({});
    publishNoticeToAllDevices.mockResolvedValue({
      total: 2,
      successCount: 2,
      failureCount: 0,
    });

    await handler(
      {
        Records: [
          {
            dynamodb: {
              OldImage: image({ noticeId: 'NOTICE01', status: 'draft' }),
              NewImage: image({
                noticeId: 'NOTICE01',
                title: '이번 주 공지',
                content: '청년부 모임 안내입니다.',
                status: 'published',
              }),
            },
          },
        ],
      } as never,
      {} as never,
      vi.fn(),
    );

    expect(send).toHaveBeenCalledTimes(2);
    expect(send.mock.calls[0][0].input).toMatchObject({
      TableName: 'woncheon-test',
      Key: { PK: 'NOTICE#NOTICE01', SK: '#META' },
      ConditionExpression:
        '#status = :published AND attribute_not_exists(notifiedAt) AND (attribute_not_exists(notificationStatus) OR notificationStatus = :pending)',
    });
    expect(publishNoticeToAllDevices).toHaveBeenCalledWith({
      noticeId: 'NOTICE01',
      title: '이번 주 공지',
      body: '청년부 모임 안내입니다.',
    });
    expect(send.mock.calls[1][0].input.UpdateExpression).toContain('notifiedAt');
    expect(send.mock.calls[1][0].input.ExpressionAttributeValues).toMatchObject({
      ':status': 'sent',
      ':total': 2,
      ':success': 2,
      ':failure': 0,
    });
  });

  it('does not send push when a published notice is edited', async () => {
    await handler(
      {
        Records: [
          {
            dynamodb: {
              OldImage: image({ noticeId: 'NOTICE02', status: 'published' }),
              NewImage: image({
                noticeId: 'NOTICE02',
                title: '수정된 공지',
                status: 'published',
              }),
            },
          },
        ],
      } as never,
      {} as never,
      vi.fn(),
    );

    expect(send).not.toHaveBeenCalled();
    expect(publishNoticeToAllDevices).not.toHaveBeenCalled();
  });

  it('claims the notice but skips SNS fan-out when notice push is disabled', async () => {
    process.env.NOTICE_PUSH_ENABLED = 'false';
    send.mockResolvedValue({});

    await handler(
      {
        Records: [
          {
            dynamodb: {
              OldImage: image({ noticeId: 'NOTICE03', status: 'draft' }),
              NewImage: image({
                noticeId: 'NOTICE03',
                title: '푸시 비활성 공지',
                status: 'published',
              }),
            },
          },
        ],
      } as never,
      {} as never,
      vi.fn(),
    );

    expect(send).toHaveBeenCalledTimes(2);
    expect(publishNoticeToAllDevices).not.toHaveBeenCalled();
    expect(send.mock.calls[1][0].input.ExpressionAttributeValues).toMatchObject({
      ':status': 'disabled',
      ':total': 0,
      ':success': 0,
      ':failure': 0,
    });
  });
});
