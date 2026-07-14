import type { APIGatewayProxyHandler } from 'aws-lambda';
import { GetCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { error, success } from '../../libs/response.js';
import type { NoticeRecord } from '../../types/notice.js';
import { toNoticeDetail } from '../../types/notice.js';

export const handler: APIGatewayProxyHandler = async (event) => {
  const noticeId = event.pathParameters?.noticeId;
  if (!noticeId) {
    return error('VALIDATION_ERROR', 'noticeId가 필요합니다.', 400);
  }

  const result = await docClient.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: `NOTICE#${noticeId}`, SK: '#META' },
    }),
  );

  const item = result.Item as NoticeRecord | undefined;
  if (!item || item.status !== 'published') {
    return error('NOT_FOUND', '공지사항을 찾을 수 없습니다.', 404);
  }

  return success(toNoticeDetail(item));
};
