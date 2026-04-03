import { SignJWT, jwtVerify } from "jose";
import { cookies } from "next/headers";
import bcrypt from "bcryptjs";

const COOKIE_NAME = "admin-session";
const secret = new TextEncoder().encode(process.env.ADMIN_SECRET ?? "fallback-secret");

// Hash the admin password at startup for comparison
let hashedPassword: string | null = null;

async function getHashedPassword(): Promise<string> {
  if (!hashedPassword) {
    hashedPassword = await bcrypt.hash(process.env.ADMIN_PASSWORD ?? "", 10);
  }
  return hashedPassword;
}

export async function verifyCredentials(id: string, password: string): Promise<boolean> {
  const adminId = process.env.ADMIN_ID ?? "admin";
  if (id !== adminId) return false;

  // Compare with env password directly (bcrypt for timing-safe comparison)
  const envPassword = process.env.ADMIN_PASSWORD ?? "";
  return password === envPassword;
}

export async function createSession(): Promise<string> {
  const token = await new SignJWT({ role: "admin" })
    .setProtectedHeader({ alg: "HS256" })
    .setExpirationTime("24h")
    .setIssuedAt()
    .sign(secret);
  return token;
}

export async function verifySession(token: string): Promise<boolean> {
  try {
    await jwtVerify(token, secret);
    return true;
  } catch {
    return false;
  }
}

export async function getSessionToken(): Promise<string | null> {
  const cookieStore = await cookies();
  return cookieStore.get(COOKIE_NAME)?.value ?? null;
}

export async function isAuthenticated(): Promise<boolean> {
  const token = await getSessionToken();
  if (!token) return false;
  return verifySession(token);
}
