import type { APIGatewayRequestAuthorizerEvent } from 'aws-lambda';
import { describe, expect, it, vi } from 'vitest';
import { handler } from '../../src/functions/auth/authorizer.js';

const { mockVerifyAccessToken } = vi.hoisted(() => ({
  mockVerifyAccessToken: vi.fn(),
}));

vi.mock('../../src/libs/jwt.js', () => ({
  verifyAccessToken: mockVerifyAccessToken,
}));

function makeEvent(methodArn: string): APIGatewayRequestAuthorizerEvent {
  return {
    type: 'REQUEST',
    methodArn,
    headers: { Authorization: 'Bearer ACCESS' },
  } as APIGatewayRequestAuthorizerEvent;
}

describe('jwtAuthorizer', () => {
  it('allows the whole API stage so cached authorizer results work across routes', async () => {
    mockVerifyAccessToken.mockReturnValue({
      memberId: 'MEMBER01',
      name: '테스터',
    });

    const result = await handler(
      makeEvent(
        'arn:aws:execute-api:ap-northeast-2:863518440691:ul7b1ft3di/dev/GET/prayers',
      ),
    );

    expect(result.policyDocument.Statement[0]).toMatchObject({
      Effect: 'Allow',
      Resource:
        'arn:aws:execute-api:ap-northeast-2:863518440691:ul7b1ft3di/dev/*/*',
    });
  });
});
