import { NextResponse } from "next/server";
import { verifyCredentials, createSession } from "@/lib/auth";

export async function POST(request: Request) {
  const body = await request.json();
  const { id, password } = body as { id?: string; password?: string };

  if (!id || !password) {
    return NextResponse.json({ error: "ID와 비밀번호를 입력해주세요." }, { status: 400 });
  }

  const valid = await verifyCredentials(id, password);
  if (!valid) {
    return NextResponse.json({ error: "인증에 실패했습니다." }, { status: 401 });
  }

  const token = await createSession();

  const response = NextResponse.json({ success: true });
  response.cookies.set("admin-session", token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: 60 * 60 * 24, // 24h
    path: "/",
  });

  return response;
}
