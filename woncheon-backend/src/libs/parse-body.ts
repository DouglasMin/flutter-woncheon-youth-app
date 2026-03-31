import { error } from './response.js';

export function parseBody(body: string | null): Record<string, unknown> | null {
  try {
    return JSON.parse(body ?? '{}') as Record<string, unknown>;
  } catch {
    return null;
  }
}

export const INVALID_BODY_RESPONSE = error('VALIDATION_ERROR', '잘못된 요청 형식입니다.', 400);
