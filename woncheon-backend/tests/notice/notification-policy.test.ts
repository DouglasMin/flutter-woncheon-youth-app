import { describe, expect, it } from 'vitest';
import { shouldSendNoticeNotification } from '../../src/types/notice.js';

describe('notice notification policy', () => {
  it('sends when a draft is first published', () => {
    expect(
      shouldSendNoticeNotification({ status: 'draft' }, { status: 'published' }),
    ).toBe(true);
  });

  it('does not send when a published notice is edited', () => {
    expect(
      shouldSendNoticeNotification(
        { status: 'published' },
        { status: 'published' },
      ),
    ).toBe(false);
  });

  it('does not send when a previously notified notice is republished', () => {
    expect(
      shouldSendNoticeNotification(
        { status: 'draft', notifiedAt: '2026-07-03T01:00:00.000Z' },
        { status: 'published', notifiedAt: '2026-07-03T01:00:00.000Z' },
      ),
    ).toBe(false);
  });

  it('sends for a newly created published notice with no notifiedAt', () => {
    expect(
      shouldSendNoticeNotification(undefined, { status: 'published' }),
    ).toBe(true);
  });
});
