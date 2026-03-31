import type { APIGatewayProxyResult } from 'aws-lambda';

const headers = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Credentials': 'true',
};

export function success(data: unknown, statusCode = 200): APIGatewayProxyResult {
  return {
    statusCode,
    headers,
    body: JSON.stringify({ success: true, data }),
  };
}

export function error(
  code: string,
  message: string,
  statusCode = 400,
): APIGatewayProxyResult {
  return {
    statusCode,
    headers,
    body: JSON.stringify({
      success: false,
      error: { code, message },
    }),
  };
}
