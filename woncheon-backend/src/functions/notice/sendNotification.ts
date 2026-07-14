import type { DynamoDBStreamHandler } from 'aws-lambda';
import { UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { publishNoticeToAllDevices } from '../../libs/device-notifications.js';
import { makeNoticePreview, shouldSendNoticeNotification } from '../../types/notice.js';

type StreamImage = Record<string, { S?: string; BOOL?: boolean; N?: string }>;

function isNoticePushEnabled(): boolean {
  return process.env.NOTICE_PUSH_ENABLED === 'true';
}

function readString(image: StreamImage | undefined, key: string): string | undefined {
  return image?.[key]?.S;
}

function noticeFromImage(image: StreamImage | undefined) {
  const noticeId = readString(image, 'noticeId');
  const status = readString(image, 'status');
  if (!noticeId || (status !== 'draft' && status !== 'published')) {
    return undefined;
  }

  return {
    noticeId,
    title: readString(image, 'title') ?? '',
    content: readString(image, 'content') ?? '',
    status,
    notifiedAt: readString(image, 'notifiedAt'),
  };
}

async function claimNotification(noticeId: string): Promise<boolean> {
  try {
    await docClient.send(
      new UpdateCommand({
        TableName: TABLE_NAME,
        Key: { PK: `NOTICE#${noticeId}`, SK: '#META' },
        UpdateExpression:
          'SET notificationStatus = :sending, notificationClaimedAt = :now',
        ConditionExpression:
          '#status = :published AND attribute_not_exists(notifiedAt) AND (attribute_not_exists(notificationStatus) OR notificationStatus = :pending)',
        ExpressionAttributeNames: { '#status': 'status' },
        ExpressionAttributeValues: {
          ':published': 'published',
          ':pending': 'pending',
          ':sending': 'sending',
          ':now': new Date().toISOString(),
        },
      }),
    );
    return true;
  } catch (error) {
    console.warn(`Notice notification claim skipped for ${noticeId}:`, error);
    return false;
  }
}

export const handler: DynamoDBStreamHandler = async (event) => {
  for (const record of event.Records) {
    const previous = noticeFromImage(record.dynamodb?.OldImage as StreamImage | undefined);
    const next = noticeFromImage(record.dynamodb?.NewImage as StreamImage | undefined);
    if (!next || !shouldSendNoticeNotification(previous, next)) continue;

    const claimed = await claimNotification(next.noticeId);
    if (!claimed) continue;

    const result = isNoticePushEnabled()
      ? await publishNoticeToAllDevices({
          noticeId: next.noticeId,
          title: next.title,
          body: makeNoticePreview(next.content),
        })
      : { total: 0, successCount: 0, failureCount: 0 };

    const notificationStatus = !isNoticePushEnabled()
      ? 'disabled'
      : result.failureCount === 0
      ? 'sent'
      : result.successCount > 0
      ? 'partial_fail'
      : 'failed';

    await docClient.send(
      new UpdateCommand({
        TableName: TABLE_NAME,
        Key: { PK: `NOTICE#${next.noticeId}`, SK: '#META' },
        UpdateExpression:
          'SET notifiedAt = :now, notificationStatus = :status, notificationRecipientCount = :total, notificationSuccessCount = :success, notificationFailureCount = :failure',
        ExpressionAttributeValues: {
          ':now': new Date().toISOString(),
          ':status': notificationStatus,
          ':total': result.total,
          ':success': result.successCount,
          ':failure': result.failureCount,
        },
      }),
    );
  }
};
