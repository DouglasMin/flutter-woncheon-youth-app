import type {
  APIGatewayRequestAuthorizerEvent,
  APIGatewayAuthorizerResult,
} from 'aws-lambda';
import { verifyAccessToken } from '../../libs/jwt.js';

function stageWildcardArn(methodArn: string): string {
  const arnParts = methodArn.split(':');
  const resourceParts = arnParts[5]?.split('/') ?? [];
  const [apiId, stage] = resourceParts;

  if (!apiId || !stage) return methodArn;

  return [
    ...arnParts.slice(0, 5),
    `${apiId}/${stage}/*/*`,
  ].join(':');
}

export const handler = async (
  event: APIGatewayRequestAuthorizerEvent,
): Promise<APIGatewayAuthorizerResult> => {
  const token = event.headers?.Authorization?.replace(/^Bearer\s+/, '');

  if (!token) {
    throw new Error('Unauthorized');
  }

  try {
    const payload = verifyAccessToken(token);

    return {
      principalId: payload.memberId,
      policyDocument: {
        Version: '2012-10-17',
        Statement: [
          {
            Action: 'execute-api:Invoke',
            Effect: 'Allow',
            Resource: stageWildcardArn(event.methodArn),
          },
        ],
      },
      context: {
        memberId: payload.memberId,
        name: payload.name,
      },
    };
  } catch {
    throw new Error('Unauthorized');
  }
};
