"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Users, Heart, CalendarCheck, FolderKanban, Flag } from "lucide-react";

interface DashboardStats {
  memberCount: number;
  prayerCount: number;
  groupCount: number;
  monthlyAttendanceRate: number;
}

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [pendingReports, setPendingReports] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    Promise.all([
      fetch("/api/admin/stats", { credentials: "include" }).then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json() as Promise<DashboardStats>;
      }),
      fetch("/api/admin/reports?status=pending", { credentials: "include" })
        .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
        .then((data: { reports?: unknown[] }) => data.reports?.length ?? 0)
        .catch(() => null),
    ])
      .then(([statsData, pendingCount]) => {
        setStats(statsData);
        setPendingReports(pendingCount);
        setError(false);
      })
      .catch((err) => {
        console.error("[Dashboard] Fetch error:", err);
        setError(true);
      })
      .finally(() => setLoading(false));
  }, []);

  const cards = [
    {
      title: "전체 교적 인원",
      value: stats?.memberCount ?? 0,
      suffix: "명",
      icon: Users,
      color: "text-blue-600 dark:text-blue-400",
      bg: "bg-blue-50 dark:bg-blue-950/40",
    },
    {
      title: "중보기도",
      value: stats?.prayerCount ?? 0,
      suffix: "개",
      icon: Heart,
      color: "text-rose-600 dark:text-rose-400",
      bg: "bg-rose-50 dark:bg-rose-950/40",
    },
    {
      title: "목장",
      value: stats?.groupCount ?? 0,
      suffix: "개",
      icon: FolderKanban,
      color: "text-amber-600 dark:text-amber-400",
      bg: "bg-amber-50 dark:bg-amber-950/40",
    },
    {
      title: "이번 달 출석률",
      value: stats?.monthlyAttendanceRate ?? 0,
      suffix: "%",
      icon: CalendarCheck,
      color: "text-emerald-600 dark:text-emerald-400",
      bg: "bg-emerald-50 dark:bg-emerald-950/40",
    },
  ];

  const hasPendingReports = (pendingReports ?? 0) > 0;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">대시보드</h1>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          원천청년부 현황을 한눈에 확인하세요
        </p>
      </div>

      {hasPendingReports && (
        <Link
          href="/reports"
          className="block rounded-xl border border-rose-200 bg-rose-50 dark:border-rose-900/60 dark:bg-rose-950/30 px-5 py-4 hover:bg-rose-100 dark:hover:bg-rose-950/50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <Flag className="w-5 h-5 text-rose-600 dark:text-rose-400" />
            <div className="flex-1">
              <p className="text-sm font-semibold text-rose-900 dark:text-rose-200">
                미처리 신고 {pendingReports}건
              </p>
              <p className="text-xs text-rose-700/80 dark:text-rose-300/80">
                개인정보처리방침 약속에 따라 24시간 이내 검토가 필요합니다.
              </p>
            </div>
            <span className="text-xs font-medium text-rose-700 dark:text-rose-300">
              검토하러 가기 →
            </span>
          </div>
        </Link>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {cards.map((card) => (
          <Card key={card.title} className="border-0 shadow-sm">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-slate-500 dark:text-slate-400">
                {card.title}
              </CardTitle>
              <div className={`p-2 rounded-lg ${card.bg}`}>
                <card.icon className={`w-4 h-4 ${card.color}`} />
              </div>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="h-8 w-20 bg-slate-100 dark:bg-slate-800 rounded animate-pulse" />
              ) : error ? (
                <p className="text-sm text-red-400">불러오기 실패</p>
              ) : (
                <p className="text-3xl font-bold tracking-tight">
                  {card.value}
                  <span className="text-lg font-normal text-slate-400 ml-1">
                    {card.suffix}
                  </span>
                </p>
              )}
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
