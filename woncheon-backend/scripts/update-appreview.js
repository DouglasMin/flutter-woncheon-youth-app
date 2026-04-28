#!/usr/bin/env node
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: 'ap-northeast-2' });
const docClient = DynamoDBDocumentClient.from(client);

async function updateAppreview() {
  // 1. appreview 계정 찾기
  const queryResult = await docClient.send(
    new QueryCommand({
      TableName: 'woncheon-dev',
      IndexName: 'GSI1',
      KeyConditionExpression: 'GSI1PK = :pk',
      ExpressionAttributeValues: {
        ':pk': 'NAME#appreview',
      },
    })
  );

  if (!queryResult.Items || queryResult.Items.length === 0) {
    console.log('❌ appreview 계정을 찾을 수 없습니다.');
    return;
  }

  const member = queryResult.Items[0];
  console.log(`✅ appreview 계정 찾음: ${member.memberId}`);

  // 2. isFirstLogin을 true로 변경
  await docClient.send(
    new UpdateCommand({
      TableName: 'woncheon-dev',
      Key: {
        PK: member.PK,
        SK: member.SK,
      },
      UpdateExpression: 'SET isFirstLogin = :true',
      ExpressionAttributeValues: {
        ':true': true,
      },
    })
  );

  console.log('✅ isFirstLogin을 true로 변경 완료');
  console.log(`\nMemberId: ${member.memberId}`);
  console.log('이제 Supabase에 목장 정보를 추가하세요.');
}

updateAppreview().catch((err) => {
  console.error('❌ Error:', err);
  process.exit(1);
});
