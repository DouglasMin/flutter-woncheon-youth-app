import { readFileSync } from 'fs';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';
import { ulid } from 'ulid';
import bcrypt from 'bcryptjs';

const DEFAULT_PASSWORD = 'woncheon2025';
const TABLE_NAME = process.env.TABLE_NAME ?? 'woncheon-dev';
const REGION = 'ap-northeast-2';

const client = new DynamoDBClient({ region: REGION });
const docClient = DynamoDBDocumentClient.from(client);

async function migrate() {
  const csvPath = process.argv[2] ?? './scripts/member.csv';
  const csv = readFileSync(csvPath, 'utf-8');
  const lines = csv.trim().split('\n');

  // 헤더: 이름,생년월일,성별 (처음 3컬럼만 사용)
  const header = lines[0].split(',').map((h) => h.trim());
  const nameIdx = header.findIndex((h) => h === '이름');
  const birthIdx = header.findIndex((h) => h === '생년월일');
  const genderIdx = header.findIndex((h) => h === '성별');

  if (nameIdx === -1) {
    console.error('CSV 헤더에 "이름" 컬럼이 필요합니다.');
    process.exit(1);
  }

  const passwordHash = await bcrypt.hash(DEFAULT_PASSWORD, 10);
  const now = new Date().toISOString();
  let count = 0;

  for (let i = 1; i < lines.length; i++) {
    const cols = lines[i].split(',').map((c) => c.trim());
    const name = cols[nameIdx];
    if (!name) continue;

    const memberId = ulid();
    const birthDate = birthIdx >= 0 ? cols[birthIdx] ?? '' : '';
    const gender = genderIdx >= 0 ? cols[genderIdx] ?? '' : '';

    await docClient.send(
      new PutCommand({
        TableName: TABLE_NAME,
        Item: {
          PK: `MEMBER#${memberId}`,
          SK: '#META',
          GSI1PK: `NAME#${name}`,
          GSI1SK: '#META',
          memberId,
          name,
          passwordHash,
          isFirstLogin: true,
          birthDate,
          gender,
          createdAt: now,
          updatedAt: now,
        },
      }),
    );

    count++;
    console.log(`[${count}] ${name} 등록 완료 (${memberId})`);
  }

  console.log(`\n총 ${count}명 마이그레이션 완료!`);
}

migrate().catch(console.error);
