"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Download, RefreshCw } from "lucide-react";
import { toast } from "sonner";

interface GroupData {
  id: number;
  name: string;
  members: Array<{
    memberId: string;
    name: string;
    dates: Record<string, boolean>;
  }>;
}

interface AttendanceData {
  groups: GroupData[];
  dates: string[];
  allGroups: Array<{ id: number; name: string }>;
}

export default function AttendancePage() {
  const [data, setData] = useState<AttendanceData | null>(null);
  const [loading, setLoading] = useState(true);

  async function loadData() {
    setLoading(true);
    try {
      const res = await fetch("/api/admin/attendance");
      const json = await res.json();
      setData(json);
    } catch {
      toast.error("출결 데이터를 불러올 수 없습니다.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadData();
  }, []);

  function handleExport() {
    window.open("/api/admin/attendance/export", "_blank");
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64 text-slate-400">
        불러오는 중...
      </div>
    );
  }

  if (!data) return null;

  // Filter to dates up to today, then take last 8 Sundays
  const today = new Date().toISOString().split("T")[0];
  const pastDates = data.dates.filter((d) => d <= today);
  const recentDates = pastDates.slice(-8);

  // 목장별 랭킹: 최근 N주(recentDates) 기준 평균 출석률 계산 후 정렬
  const ranking = [...data.groups]
    .map((g) => {
      let presentCells = 0;
      let totalCells = 0;
      for (const m of g.members) {
        for (const d of recentDates) {
          totalCells += 1;
          if (m.dates[d] === true) presentCells += 1;
        }
      }
      const rate = totalCells > 0 ? (presentCells / totalCells) * 100 : 0;
      return {
        id: g.id,
        name: g.name,
        memberCount: g.members.length,
        rate,
      };
    })
    .sort((a, b) => b.rate - a.rate);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">출결 현황</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            {data.groups.length}개 목장 · {recentDates.length}주차
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={loadData} className="gap-2">
            <RefreshCw className="w-4 h-4" />
            새로고침
          </Button>
          <Button onClick={handleExport} className="gap-2">
            <Download className="w-4 h-4" />
            CSV 내보내기
          </Button>
        </div>
      </div>

      {/* 목장별 출석률 랭킹 — 운영진 전용 (앱 사용자에게는 비공개) */}
      <Card className="border-0 shadow-sm">
        <CardHeader className="pb-3">
          <CardTitle className="text-base">
            목장별 출석률
            <span className="ml-2 text-xs font-normal text-slate-500">
              최근 {recentDates.length}주차 평균
            </span>
          </CardTitle>
        </CardHeader>
        <CardContent className="pt-0 space-y-2">
          {ranking.map((g, i) => {
            const rateText = `${g.rate.toFixed(0)}%`;
            const barColor =
              g.rate >= 80
                ? "bg-emerald-500"
                : g.rate >= 50
                  ? "bg-amber-500"
                  : "bg-red-500";
            const isTop = i < 3;
            return (
              <div
                key={g.id}
                className="flex items-center gap-3 py-1.5"
              >
                <div
                  className={
                    "w-6 h-6 rounded-md flex items-center justify-center text-xs font-bold " +
                    (isTop
                      ? "bg-slate-900 text-white dark:bg-slate-100 dark:text-slate-900"
                      : "bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400")
                  }
                >
                  {i + 1}
                </div>
                <div className="w-24 text-sm font-medium truncate">
                  {g.name}
                </div>
                <div className="text-xs text-slate-400 w-12">
                  {g.memberCount}명
                </div>
                <div className="flex-1 h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                  <div
                    className={barColor + " h-full rounded-full transition-all"}
                    style={{ width: `${Math.max(2, g.rate)}%` }}
                  />
                </div>
                <div className="w-12 text-right text-sm font-semibold tabular-nums">
                  {rateText}
                </div>
              </div>
            );
          })}
        </CardContent>
      </Card>

      <Tabs defaultValue={data.groups[0]?.name ?? "all"}>
        <TabsList className="flex-wrap h-auto gap-1 bg-transparent p-0">
          {data.groups.map((g) => (
            <TabsTrigger
              key={g.id}
              value={g.name}
              className="data-[state=active]:bg-slate-900 data-[state=active]:text-white dark:data-[state=active]:bg-slate-100 dark:data-[state=active]:text-slate-900 rounded-full px-4 py-1.5 text-sm"
            >
              {g.name}
            </TabsTrigger>
          ))}
        </TabsList>

        {data.groups.map((group) => (
          <TabsContent key={group.id} value={group.name}>
            <Card className="border-0 shadow-sm">
              <CardHeader className="pb-2">
                <CardTitle className="text-lg">
                  {group.name} 목장
                  <Badge variant="secondary" className="ml-2 font-normal">
                    {group.members.length}명
                  </Badge>
                </CardTitle>
              </CardHeader>
              <CardContent className="p-0 overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b dark:border-slate-800">
                      <th className="text-left px-4 py-3 font-medium sticky left-0 bg-white dark:bg-slate-950 z-10 min-w-[100px]">
                        이름
                      </th>
                      {recentDates.map((d) => {
                        const dt = new Date(d);
                        const label = `${dt.getMonth() + 1}/${dt.getDate()}`;
                        return (
                          <th
                            key={d}
                            className="text-center px-2 py-3 font-medium min-w-[50px]"
                          >
                            {label}
                          </th>
                        );
                      })}
                      <th className="text-center px-3 py-3 font-medium">출석률</th>
                    </tr>
                  </thead>
                  <tbody>
                    {group.members.map((m) => {
                      const total = recentDates.length;
                      const present = recentDates.filter(
                        (d) => m.dates[d]
                      ).length;
                      const rate =
                        total > 0
                          ? Math.round((present / total) * 100)
                          : 0;

                      return (
                        <tr
                          key={m.memberId}
                          className="border-b dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-900/50"
                        >
                          <td className="px-4 py-2.5 font-medium sticky left-0 bg-white dark:bg-slate-950 z-10">
                            {m.name}
                          </td>
                          {recentDates.map((d) => (
                            <td key={d} className="text-center px-2 py-2.5">
                              {m.dates[d] === true ? (
                                <span className="text-emerald-500 font-bold">O</span>
                              ) : m.dates[d] === false ? (
                                <span className="text-slate-300 dark:text-slate-600">X</span>
                              ) : (
                                <span className="text-slate-200">-</span>
                              )}
                            </td>
                          ))}
                          <td className="text-center px-3 py-2.5">
                            <span
                              className={
                                rate >= 80
                                  ? "text-emerald-600 font-bold"
                                  : rate >= 50
                                  ? "text-amber-600 font-semibold"
                                  : "text-red-500 font-semibold"
                              }
                            >
                              {rate}%
                            </span>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </CardContent>
            </Card>
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
}
