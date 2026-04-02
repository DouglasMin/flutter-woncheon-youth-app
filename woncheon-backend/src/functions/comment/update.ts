import type { APIGatewayProxyHandler } from 'aws-lambda';
import { QueryCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success, error } from '../../libs/response.js';
import { parseBody, INVALID_BODY_RESPONSE } from '../../libs/parse-body.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';

export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const prayerId = event.pathParameters?.prayerId;
  const commentId = event.pathParameters?.commentId;
  if (!prayerId || !commentId) {
    return error('VALIDATION_ERROR', 'prayerId와 commentId가 필요합니다.', 400);
  }

  const body = parseBody(event.body);
  if (!body) return INVALID_BODY_RESPONSE;

  const { content } = body as { content?: string };
  if (!content || content.trim().length === 0) {
    return error('VALIDATION_ERROR', '내용을 입력해주세요.', 400);
  }
  if (content.length > 200) {
    return error('VALIDATION_ERROR', '댓글은 200자 이내로 입력해주세요.', 400);
  }

  // Find the comment
  const result = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      KeyConditionExpression: 'PK = :pk AND begins_with(SK, :prefix)',
      ExpressionAttributeValues: {
        ':pk': `PRAYER#${prayerId}`,
        ':prefix': 'COMMENT#',
      },
    }),
  );

  const comment = result.Items?.find((i) => i.commentId === commentId);
  if (!comment) return error('NOT_FOUND', '댓글을 찾을 수 없습니다.', 404);
  if (comment.memberId !== memberId) {
    return error('FORBIDDEN', '본인의 댓글만 수정할 수 있습니다.', 403);
  }

  await docClient.send(
    new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { PK: comment.PK as string, SK: comment.SK as string },
      UpdateExpression: 'SET content = :content, updatedAt = :now',
      ExpressionAttributeValues: {
        ':content': content.trim(),
        ':now': new Date().toISOString(),
      },
    }),
  );

  return success({ message: '수정되었습니다.' });
};
