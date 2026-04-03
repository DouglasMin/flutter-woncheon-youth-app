import { NextResponse } from "next/server";
import { verifyCredentials, createSession } from "@/lib/auth";

export async function POST(request: Request) {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "잘못된 요청 형식입니다." }, { status: 400 });
  }

  if (
    typeof body !== "object" ||
    body === null ||
    typeof (body as Record<string, unknown>).id !== "string" ||
    typeof (body as Record<string, unknown>).password !== "string"
  ) {
    return NextResponse.json({ error: "ID와 비밀번호를 입력해주세요." }, { status: 400 });
  }

  const { id, password } = body as { id: string; password: string };

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
    maxAge: 60 * 60 * 24,
    path: "/",
  });

  return response;
}
