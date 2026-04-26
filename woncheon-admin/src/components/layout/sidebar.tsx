"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import {
  LayoutDashboard,
  Users,
  CalendarCheck,
  Heart,
  FolderKanban,
  UserPlus,
  LogOut,
  Church,
  Flag,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";

const navItems = [
  { href: "/dashboard", label: "대시보드", icon: LayoutDashboard },
  { href: "/members", label: "회원 관리", icon: Users },
  { href: "/attendance", label: "출결 현황", icon: CalendarCheck },
  { href: "/prayers", label: "중보기도", icon: Heart },
  { href: "/reports", label: "신고 검토", icon: Flag, watchKey: "reports" as const },
  { href: "/groups", label: "목장 관리", icon: FolderKanban },
  { href: "/register-requests", label: "가입 요청", icon: UserPlus },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const [pendingReports, setPendingReports] = useState<number | null>(null);

  // 미처리 신고 수: 페이지 이동 시 재조회 (단일 운영자 가정 → 폴링 불필요)
  useEffect(() => {
    let cancelled = false;
    fetch("/api/admin/reports?status=pending")
      .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
      .then((data: { reports?: unknown[] }) => {
        if (!cancelled) setPendingReports(data.reports?.length ?? 0);
      })
      .catch(() => {
        if (!cancelled) setPendingReports(null);
      });
    return () => {
      cancelled = true;
    };
  }, [pathname]);

  async function handleLogout() {
    await fetch("/api/auth/logout", { method: "POST" });
    router.push("/login");
    router.refresh();
  }

  return (
    <aside className="hidden md:flex w-64 flex-col border-r border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-950 h-screen sticky top-0">
      {/* Logo */}
      <div className="flex items-center gap-3 px-6 py-5 border-b border-slate-100 dark:border-slate-800">
        <img src="/logo.png" alt="원천청년부" className="w-9 h-9 rounded-xl" />
        <div>
          <p className="font-bold text-sm leading-tight">원천청년부</p>
          <p className="text-[11px] text-slate-400">관리자 패널</p>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-4 space-y-1">
        {navItems.map((item) => {
          const isActive = pathname.startsWith(item.href);
          const showBadge =
            item.watchKey === "reports" &&
            pendingReports !== null &&
            pendingReports > 0;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors",
                isActive
                  ? "bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-white"
                  : "text-slate-500 hover:text-slate-900 hover:bg-slate-50 dark:text-slate-400 dark:hover:text-white dark:hover:bg-slate-800/50"
              )}
            >
              <item.icon className="w-[18px] h-[18px]" />
              <span className="flex-1">{item.label}</span>
              {showBadge && (
                <span className="inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 text-[11px] font-semibold rounded-full bg-rose-500 text-white">
                  {pendingReports}
                </span>
              )}
            </Link>
          );
        })}
      </nav>

      {/* Logout */}
      <div className="px-3 py-4 border-t border-slate-100 dark:border-slate-800">
        <Button
          variant="ghost"
          className="w-full justify-start gap-3 text-slate-500 hover:text-red-600 dark:text-slate-400 dark:hover:text-red-400"
          onClick={handleLogout}
        >
          <LogOut className="w-[18px] h-[18px]" />
          로그아웃
        </Button>
      </div>
    </aside>
  );
}
