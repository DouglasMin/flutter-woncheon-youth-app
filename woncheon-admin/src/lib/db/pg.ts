import { Pool } from "pg";

let pool: Pool | null = null;

export function getPool(): Pool {
  if (!pool) {
    pool = new Pool({
      host: process.env.PG_HOST,
      port: Number(process.env.PG_PORT ?? "5432"),
      database: process.env.PG_DATABASE,
      user: process.env.PG_USER,
      password: process.env.PG_PASSWORD,
      ssl: process.env.NODE_ENV === "production"
        ? { rejectUnauthorized: true }
        : { rejectUnauthorized: false },
      max: 5,
      idleTimeoutMillis: 10000,
    });

    pool.on("connect", (client) => {
      client.query("SET timezone = 'Asia/Seoul'").catch((err: unknown) => {
        console.error("[pg] Failed to set timezone:", err);
      });
    });
  }
  return pool;
}
