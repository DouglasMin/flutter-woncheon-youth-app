import type { APIGatewayProxyHandler } from 'aws-lambda';
import { PutCommand, GetCommand } from '@aws-sdk/lib-dynamodb';
import { ulid } from 'ulid';
import { docClient, TABLE_NAME } from '../../libs/dynamo.js';
import { success, error } from '../../libs/response.js';
import { parseBody, INVALID_BODY_RESPONSE } from '../../libs/parse-body.js';
import { getMemberId, UNAUTHORIZED_RESPONSE } from '../../libs/auth-context.js';
import type { Member } from '../../types/member.js';

export const handler: APIGatewayProxyHandler = async (event) => {
  const memberId = getMemberId(event);
  if (!memberId) return UNAUTHORIZED_RESPONSE;

  const prayerId = event.pathParameters?.prayerId;
  if (!prayerId) return error('VALIDATION_ERROR', 'prayerId가 필요합니다.', 400);

  const body = parseBody(event.body);
  if (!body) return INVALID_BODY_RESPONSE;

  const { content } = body as { content?: string };
  if (!content || content.trim().length === 0) {
    return error('VALIDATION_ERROR', '내용을 입력해주세요.', 400);
  }
  if (content.length > 200) {
    return error('VALIDATION_ERROR', '댓글은 200자 이내로 입력해주세요.', 400);
  }

  const memberResult = await docClient.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: `MEMBER#${memberId}`, SK: '#META' },
      ProjectionExpression: '#n',
      ExpressionAttributeNames: { '#n': 'name' },
    }),
  );
  const member = memberResult.Item as Pick<Member, 'name'> | undefined;
  const authorName = member?.name ?? '알 수 없음';

  const commentId = ulid();
  const createdAt = new Date().toISOString();

  await docClient.send(
    new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        PK: `PRAYER#${prayerId}`,
        SK: `COMMENT#${createdAt}#${commentId}`,
        commentId,
        prayerId,
        memberId,
        authorName,
        content: content.trim(),
        createdAt,
      },
    }),
  );

  return success({ commentId, authorName, content: content.trim(), createdAt }, 201);
};
