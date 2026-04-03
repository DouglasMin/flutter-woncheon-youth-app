import { SignJWT, jwtVerify } from "jose";
import { cookies } from "next/headers";

const COOKIE_NAME = "admin-session";

function getSecret(): Uint8Array {
  const adminSecret = process.env.ADMIN_SECRET;
  if (!adminSecret) {
    throw new Error("ADMIN_SECRET environment variable is required");
  }
  return new TextEncoder().encode(adminSecret);
}

export async function verifyCredentials(id: string, password: string): Promise<boolean> {
  const adminId = process.env.ADMIN_ID;
  const adminPassword = process.env.ADMIN_PASSWORD;

  if (!adminId || !adminPassword) {
    throw new Error("ADMIN_ID and ADMIN_PASSWORD environment variables are required");
  }

  // Timing-safe comparison (constant time via length check + char-by-char)
  if (id.length !== adminId.length || password.length !== adminPassword.length) {
    return false;
  }

  let idMatch = true;
  let pwMatch = true;
  for (let i = 0; i < adminId.length; i++) {
    if (id[i] !== adminId[i]) idMatch = false;
  }
  for (let i = 0; i < adminPassword.length; i++) {
    if (password[i] !== adminPassword[i]) pwMatch = false;
  }

  return idMatch && pwMatch;
}

export async function createSession(): Promise<string> {
  const token = await new SignJWT({ role: "admin" })
    .setProtectedHeader({ alg: "HS256" })
    .setExpirationTime("24h")
    .setIssuedAt()
    .sign(getSecret());
  return token;
}

export async function verifySession(token: string): Promise<boolean> {
  try {
    await jwtVerify(token, getSecret());
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
