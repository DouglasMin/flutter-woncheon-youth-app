"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Users, Heart, CalendarCheck, FolderKanban } from "lucide-react";

interface DashboardStats {
  memberCount: number;
  prayerCount: number;
  groupCount: number;
  monthlyAttendanceRate: number;
}

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/admin/stats")
      .then((res) => res.json())
      .then((data) => setStats(data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const cards = [
    {
      title: "전체 회원",
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

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">대시보드</h1>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          원천청년부 현황을 한눈에 확인하세요
        </p>
      </div>

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
