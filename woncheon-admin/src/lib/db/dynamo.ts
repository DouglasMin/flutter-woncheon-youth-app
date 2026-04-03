import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({ region: process.env.AWS_REGION ?? "ap-northeast-2" });

export const docClient = DynamoDBDocumentClient.from(client, {
  marshallOptions: { removeUndefinedValues: true },
});

const tableName = process.env.DYNAMO_TABLE_NAME;
if (!tableName) {
  throw new Error("DYNAMO_TABLE_NAME environment variable is required");
}
export const TABLE_NAME = tableName;
