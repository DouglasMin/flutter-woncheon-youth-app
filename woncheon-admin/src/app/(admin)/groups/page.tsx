"use client";

import { useEffect, useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Users, TrendingUp, RefreshCw } from "lucide-react";
import { toast } from "sonner";

interface Group {
  id: number;
  name: string;
  leaderMemberId: string;
  memberCount: number;
  attendanceRate: number;
}

export default function GroupsPage() {
  const [groups, setGroups] = useState<Group[]>([]);
  const [loading, setLoading] = useState(true);

  async function loadGroups() {
    setLoading(true);
    try {
      const res = await fetch("/api/admin/groups");
      const data = await res.json();
      setGroups(data.groups ?? []);
    } catch {
      toast.error("목장 목록을 불러올 수 없습니다.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadGroups();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64 text-slate-400">
        불러오는 중...
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">목장 관리</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            전체 {groups.length}개 목장
          </p>
        </div>
        <Button variant="outline" onClick={loadGroups} className="gap-2">
          <RefreshCw className="w-4 h-4" />
          새로고침
        </Button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {groups.map((g) => (
          <Card
            key={g.id}
            className="border-0 shadow-sm hover:shadow-md transition-shadow"
          >
            <CardContent className="p-5">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h3 className="font-bold text-lg">{g.name} 목장</h3>
                  <p className="text-sm text-slate-500 dark:text-slate-400">
                    목자: {g.name}
                  </p>
                </div>
                <Badge
                  variant={
                    g.attendanceRate >= 80
                      ? "default"
                      : g.attendanceRate >= 50
                      ? "secondary"
                      : "destructive"
                  }
                  className="text-xs"
                >
                  {g.attendanceRate}%
                </Badge>
              </div>

              <div className="flex items-center gap-6 text-sm">
                <div className="flex items-center gap-2 text-slate-500 dark:text-slate-400">
                  <Users className="w-4 h-4" />
                  <span>{g.memberCount}명</span>
                </div>
                <div className="flex items-center gap-2 text-slate-500 dark:text-slate-400">
                  <TrendingUp className="w-4 h-4" />
                  <span>이번 달 {g.attendanceRate}%</span>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
