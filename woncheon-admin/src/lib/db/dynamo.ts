import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({ region: process.env.AWS_REGION ?? "ap-northeast-2" });

export const docClient = DynamoDBDocumentClient.from(client, {
  marshallOptions: { removeUndefinedValues: true },
});

// Lazy — validated at runtime, not build time
export const TABLE_NAME = process.env.DYNAMO_TABLE_NAME ?? "woncheon-dev";
