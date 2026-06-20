import type { Handler } from 'aws-lambda';
import { getPool } from '../../libs/pg.js';

/**
 * Supabase 무료 티어 자동 pause 방지용 heartbeat.
 * 매일 1회 실행되어 단순 SELECT 쿼리로 DB connection 유지.
 */
export const handler: Handler = async () => {
  const pool = getPool();
  try {
    const result = await pool.query('SELECT 1 AS heartbeat');
    console.log('✅ DB heartbeat success:', result.rows[0]);
    return {
      statusCode: 200,
      body: JSON.stringify({ success: true, timestamp: new Date().toISOString() }),
    };
  } catch (error) {
    console.error('❌ DB heartbeat failed:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ success: false, error: String(error) }),
    };
  }
};
