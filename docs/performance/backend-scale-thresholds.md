# Backend Scale Thresholds

We do not redesign DynamoDB keys until a user-visible threshold is crossed.

## Prayer List

Current path:
- Query `GSI2PK = PRAYER_LIST`
- Optionally filter by date, member IDs, and blocked members
- Wider query window is used when server-side filtering is active

Redesign trigger:
- p95 `/prayers` latency over 800ms for 3 consecutive days, or
- group-prayer section regularly returns fewer than requested items while `LastEvaluatedKey` exists, or
- DynamoDB consumed reads for `/prayers` become a meaningful cost driver.

Candidate redesign:
- Add member-scoped list keys for group/member filtered reads.
- Preserve anonymity in API responses.
- Keep existing `PRAYER_LIST` for global feed.

## Notice List

Current path:
- Query `GSI2PK = NOTICE_LIST`
- Filter `status = published`

Redesign trigger:
- more than 100 unpublished/draft notices, or
- p95 `/notices` latency over 500ms for 3 consecutive days.

Candidate redesign:
- Write published notices to a published-only list key.
- Remove from published key when unpublished.
