import { Pool } from 'pg';
import { requireEnv } from './env.js';

let pool: Pool | null = null;

export function getPool(): Pool {
  if (!pool) {
    pool = new Pool({
      host: requireEnv('PG_HOST'),
      port: Number(process.env.PG_PORT ?? '5432'),
      database: requireEnv('PG_DATABASE'),
      user: requireEnv('PG_USER'),
      password: requireEnv('PG_PASSWORD'),
      ssl: { rejectUnauthorized: false },
      max: 3, // Lambda 환경에서 커넥션 최소화
      idleTimeoutMillis: 10000,
    });
  }
  return pool;
}
