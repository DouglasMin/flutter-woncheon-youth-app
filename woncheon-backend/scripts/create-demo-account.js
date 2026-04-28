#!/usr/bin/env node
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const bcrypt = require('bcryptjs');
const { ulid } = require('ulid');

const client = new DynamoDBClient({ 
  region: 'ap-northeast-2'
});
const docClient = DynamoDBDocumentClient.from(client);

const DEMO_ACCOUNT = {
  name: 'appreview',
  password: 'Appreview2026!',
  birthDate: '1990-01-01',
  gender: 'M',
};

async function createDemoAccount() {
  const memberId = ulid();
  const passwordHash = await bcrypt.hash(DEMO_ACCOUNT.password, 10);
  const now = new Date().toISOString();

  const item = {
    PK: `MEMBER#${memberId}`,
    SK: '#META',
    GSI1PK: `NAME#${DEMO_ACCOUNT.name}`,
    GSI1SK: '#META',
    memberId,
    name: DEMO_ACCOUNT.name,
    passwordHash,
    isFirstLogin: true, // 비번변경 필수
    birthDate: DEMO_ACCOUNT.birthDate,
    gender: DEMO_ACCOUNT.gender,
    createdAt: now,
    updatedAt: now,
  };

  await docClient.send(
    new PutCommand({
      TableName: 'woncheon-dev',
      Item: item,
      ConditionExpression: 'attribute_not_exists(PK)', // 중복 방지
    })
  );

  console.log('✅ Demo account created:');
  console.log(`   Name: ${DEMO_ACCOUNT.name}`);
  console.log(`   Password: ${DEMO_ACCOUNT.password}`);
  console.log(`   MemberId: ${memberId}`);
}

createDemoAccount().catch((err) => {
  if (err.name === 'ConditionalCheckFailedException') {
    console.log('⚠️  Demo account already exists');
  } else {
    console.error('❌ Error:', err);
    process.exit(1);
  }
});
