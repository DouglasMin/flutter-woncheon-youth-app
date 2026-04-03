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
      max: 3,
      idleTimeoutMillis: 10000,
    });

    // 모든 커넥션에서 KST timezone 사용
    pool.on('connect', (client) => {
      client.query("SET timezone = 'Asia/Seoul'");
    });
  }
  return pool;
}
