import { QueryCommand, BatchWriteCommand } from '@aws-sdk/lib-dynamodb';
import { docClient, TABLE_NAME } from './dynamo.js';

/**
 * Delete all items under a PK, optionally filtered by SK prefix.
 * Handles pagination (LastEvaluatedKey) and retries (UnprocessedItems).
 */
export async function deleteItemsByPK(
  pk: string,
  skPrefix?: string,
): Promise<number> {
  let lastKey: Record<string, unknown> | undefined;
  let totalDeleted = 0;

  do {
    const result = await docClient.send(
      new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: skPrefix
          ? 'PK = :pk AND begins_with(SK, :prefix)'
          : 'PK = :pk',
        ExpressionAttributeValues: skPrefix
          ? { ':pk': pk, ':prefix': skPrefix }
          : { ':pk': pk },
        ProjectionExpression: 'PK, SK',
        Limit: 250,
        ExclusiveStartKey: lastKey,
      }),
    );

    const items = result.Items ?? [];
    if (items.length > 0) {
      const deleteRequests = items.map((item) => ({
        DeleteRequest: { Key: { PK: item.PK, SK: item.SK } },
      }));

      for (let i = 0; i < deleteRequests.length; i += 25) {
        let unprocessed = deleteRequests.slice(i, i + 25);

        while (unprocessed.length > 0) {
          const batchResult = await docClient.send(
            new BatchWriteCommand({
              RequestItems: { [TABLE_NAME]: unprocessed },
            }),
          );
          const remaining = batchResult.UnprocessedItems?.[TABLE_NAME];
          unprocessed = (remaining ?? []) as typeof unprocessed;

          // Brief pause before retry if there are unprocessed items
          if (unprocessed.length > 0) {
            await new Promise((r) => setTimeout(r, 100));
          }
        }
      }

      totalDeleted += items.length;
    }

    lastKey = result.LastEvaluatedKey;
  } while (lastKey);

  return totalDeleted;
}
