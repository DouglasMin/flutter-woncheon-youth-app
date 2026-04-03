"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  Users,
  CalendarCheck,
  Heart,
  FolderKanban,
  LogOut,
  Church,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";

const navItems = [
  { href: "/dashboard", label: "대시보드", icon: LayoutDashboard },
  { href: "/members", label: "회원 관리", icon: Users },
  { href: "/attendance", label: "출결 현황", icon: CalendarCheck },
  { href: "/prayers", label: "중보기도", icon: Heart },
  { href: "/groups", label: "목장 관리", icon: FolderKanban },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  async function handleLogout() {
    await fetch("/api/auth/logout", { method: "POST" });
    router.push("/login");
    router.refresh();
  }

  return (
    <aside className="hidden md:flex w-64 flex-col border-r border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-950 h-screen sticky top-0">
      {/* Logo */}
      <div className="flex items-center gap-3 px-6 py-5 border-b border-slate-100 dark:border-slate-800">
        <div className="w-9 h-9 rounded-xl bg-slate-900 dark:bg-slate-100 flex items-center justify-center">
          <Church className="w-5 h-5 text-white dark:text-slate-900" />
        </div>
        <div>
          <p className="font-bold text-sm leading-tight">원천청년부</p>
          <p className="text-[11px] text-slate-400">관리자 패널</p>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-4 space-y-1">
        {navItems.map((item) => {
          const isActive = pathname.startsWith(item.href);
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
              {item.label}
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
