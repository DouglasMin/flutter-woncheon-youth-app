#!/usr/bin/env node
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const bcrypt = require('bcryptjs');

const client = new DynamoDBClient({ region: 'ap-northeast-2' });
const docClient = DynamoDBDocumentClient.from(client);

// 초기화할 사용자 이름 (appreview, 심민섭 제외)
const TEST_USERS = [
  '김지현',
  '노연수',
  '노은진',
  '민동익',
  '방하진',
  '유정석',
  '유형석',
  '조성주',
  '조은주',
];

const DEFAULT_PASSWORD = 'woncheon2025';

async function resetUser(name) {
  // 1. 이름으로 회원 찾기
  const queryResult = await docClient.send(
    new QueryCommand({
      TableName: 'woncheon-dev',
      IndexName: 'GSI1',
      KeyConditionExpression: 'GSI1PK = :pk',
      ExpressionAttributeValues: {
        ':pk': `NAME#${name}`,
      },
    })
  );

  if (!queryResult.Items || queryResult.Items.length === 0) {
    console.log(`⚠️  ${name} 계정을 찾을 수 없습니다.`);
    return;
  }

  const member = queryResult.Items[0];
  const passwordHash = await bcrypt.hash(DEFAULT_PASSWORD, 10);

  // 2. 비밀번호 초기화 + isFirstLogin = true
  await docClient.send(
    new UpdateCommand({
      TableName: 'woncheon-dev',
      Key: {
        PK: member.PK,
        SK: member.SK,
      },
      UpdateExpression: 'SET passwordHash = :hash, isFirstLogin = :true, updatedAt = :now',
      ExpressionAttributeValues: {
        ':hash': passwordHash,
        ':true': true,
        ':now': new Date().toISOString(),
      },
    })
  );

  console.log(`✅ ${name} 초기화 완료 (비밀번호: ${DEFAULT_PASSWORD})`);
}

async function resetAllTestUsers() {
  console.log(`총 ${TEST_USERS.length}명 초기화 시작...\n`);
  
  for (const name of TEST_USERS) {
    await resetUser(name);
  }
  
  console.log('\n✅ 모든 테스트 계정 초기화 완료');
  console.log('appreview 계정은 유지됨');
}

resetAllTestUsers().catch((err) => {
  console.error('❌ Error:', err);
  process.exit(1);
});
