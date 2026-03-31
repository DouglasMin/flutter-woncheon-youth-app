import type { APIGatewayProxyEvent } from 'aws-lambda';
import { error } from './response.js';

export function getMemberId(event: APIGatewayProxyEvent): string | null {
  const memberId = event.requestContext.authorizer?.memberId;
  if (typeof memberId !== 'string' || memberId.length === 0) {
    return null;
  }
  return memberId;
}

export const UNAUTHORIZED_RESPONSE = error('UNAUTHORIZED', '인증 정보가 유효하지 않습니다.', 401);
