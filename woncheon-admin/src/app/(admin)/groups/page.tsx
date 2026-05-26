"use client";

import { useEffect, useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Users, TrendingUp, RefreshCw, Pencil } from "lucide-react";
import { toast } from "sonner";

interface GroupMemberOption {
  memberId: string;
  name: string;
}

interface Group {
  id: number;
  name: string;
  leaderMemberId: string;
  leaderName: string | null;
  memberCount: number;
  attendanceRate: number;
  members: GroupMemberOption[];
}

export default function GroupsPage() {
  const [groups, setGroups] = useState<Group[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Group | null>(null);
  const [newLeaderId, setNewLeaderId] = useState("");
  const [newName, setNewName] = useState("");
  const [saving, setSaving] = useState(false);

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

  function openEdit(g: Group) {
    setEditing(g);
    setNewLeaderId(g.leaderMemberId);
    setNewName(g.name);
  }

  function closeEdit() {
    if (saving) return;
    setEditing(null);
  }

  async function handleSave() {
    if (!editing) return;
    const leaderChanged = newLeaderId !== editing.leaderMemberId;
    const nameChanged =
      newName.trim() !== editing.name && newName.trim() !== "";
    if (!leaderChanged && !nameChanged) {
      closeEdit();
      return;
    }
    setSaving(true);
    try {
      const body: { leaderMemberId?: string; name?: string } = {};
      if (leaderChanged) body.leaderMemberId = newLeaderId;
      if (nameChanged) body.name = newName.trim();

      const res = await fetch(`/api/admin/groups/${editing.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      const data = await res.json();
      if (!res.ok) {
        toast.error(data.error ?? "변경에 실패했습니다.");
        return;
      }
      toast.success("변경되었습니다.");
      setEditing(null);
      await loadGroups();
    } catch {
      toast.error("변경에 실패했습니다.");
    } finally {
      setSaving(false);
    }
  }

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
                <div className="min-w-0">
                  <h3 className="font-bold text-lg truncate">{g.name} 목장</h3>
                  <p className="text-sm text-slate-500 dark:text-slate-400">
                    목자: {g.leaderName ?? "미지정"}
                  </p>
                </div>
                <div className="flex items-center gap-1.5 shrink-0">
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
                  {/* 임원 그룹은 목자 개념 없음 → 편집 숨김 */}
                  {g.name !== "임원" && (
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-7 w-7 text-slate-400 hover:text-slate-900 dark:hover:text-white"
                      onClick={() => openEdit(g)}
                    >
                      <Pencil className="w-3.5 h-3.5" />
                    </Button>
                  )}
                </div>
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

      {/* 목자 변경 + 목장명 편집 다이얼로그 */}
      <Dialog open={!!editing} onOpenChange={(open) => !open && closeEdit()}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editing?.name} 목장 편집</DialogTitle>
            <DialogDescription>
              목자는 해당 목장 멤버 중에서만 지정할 수 있습니다.
            </DialogDescription>
          </DialogHeader>
          {editing && (
            <div className="space-y-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">목장 이름</label>
                <Input
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  placeholder="목장 이름"
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">목자</label>
                <Select
                  value={newLeaderId}
                  onValueChange={(v) => setNewLeaderId(v ?? "")}
                >
                  <SelectTrigger>
                    <SelectValue>
                      {editing.members.find((m) => m.memberId === newLeaderId)
                        ?.name ?? "선택"}
                    </SelectValue>
                  </SelectTrigger>
                  <SelectContent>
                    {editing.members.map((m) => (
                      <SelectItem key={m.memberId} value={m.memberId}>
                        {m.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={closeEdit} disabled={saving}>
              취소
            </Button>
            <Button onClick={handleSave} disabled={saving}>
              {saving ? "저장 중..." : "저장"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
