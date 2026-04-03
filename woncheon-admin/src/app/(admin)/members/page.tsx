"use client";

import { useEffect, useMemo, useState } from "react";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Search, UserPlus, RefreshCw, X } from "lucide-react";
import { toast } from "sonner";

interface Member {
  memberId: string;
  name: string;
  isFirstLogin: boolean;
  createdAt: string;
  birthDate: string;
  gender: string;
  groupName: string;
}

interface GroupOption {
  id: number;
  name: string;
}

const ALL = "all";

export default function MembersPage() {
  const [members, setMembers] = useState<Member[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [filterGroup, setFilterGroup] = useState<string>(ALL);
  const [filterGender, setFilterGender] = useState<string>(ALL);
  const [filterStatus, setFilterStatus] = useState<string>(ALL);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [newName, setNewName] = useState("");
  const [newBirthDate, setNewBirthDate] = useState("");
  const [newGender, setNewGender] = useState("M");
  const [newGroupId, setNewGroupId] = useState("none");
  const [adding, setAdding] = useState(false);
  const [groups, setGroups] = useState<GroupOption[]>([]);

  async function loadMembers() {
    setLoading(true);
    try {
      const res = await fetch("/api/admin/members");
      const data = await res.json();
      setMembers(data.members ?? []);
    } catch {
      toast.error("회원 목록을 불러올 수 없습니다.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadMembers();
    fetch("/api/admin/groups")
      .then((res) => res.json())
      .then((data) => setGroups(data.groups ?? []))
      .catch(() => {});
  }, []);

  // Unique values for filter dropdowns
  const groupNames = useMemo(
    () => [...new Set(members.map((m) => m.groupName))].sort((a, b) => a.localeCompare(b, "ko")),
    [members]
  );
  const genderOptions = [
    { value: "M", label: "남" },
    { value: "W", label: "여" },
  ];
  const statusOptions = [
    { value: "active", label: "활성" },
    { value: "first", label: "미변경" },
  ];

  const filtered = useMemo(() => {
    return members.filter((m) => {
      if (search && !m.name.includes(search) && !m.groupName.includes(search)) return false;
      if (filterGroup !== ALL && m.groupName !== filterGroup) return false;
      if (filterGender !== ALL && m.gender !== filterGender) return false;
      if (filterStatus !== ALL) {
        if (filterStatus === "first" && !m.isFirstLogin) return false;
        if (filterStatus === "active" && m.isFirstLogin) return false;
      }
      return true;
    });
  }, [members, search, filterGroup, filterGender, filterStatus]);

  async function handleAddMember() {
    if (!newName.trim()) {
      toast.error("이름을 입력해주세요.");
      return;
    }
    setAdding(true);
    try {
      const res = await fetch("/api/admin/members/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: newName.trim(),
          birthDate: newBirthDate,
          gender: newGender,
          groupId: newGroupId !== "none" ? Number(newGroupId) : undefined,
        }),
      });
      const data = await res.json();
      if (!res.ok) {
        toast.error(data.error ?? "등록에 실패했습니다.");
        return;
      }
      toast.success(`${newName.trim()} 회원이 등록되었습니다.`);
      setShowAddDialog(false);
      setNewName("");
      setNewBirthDate("");
      setNewGender("M");
      setNewGroupId("none");
      loadMembers();
    } catch {
      toast.error("등록에 실패했습니다.");
    } finally {
      setAdding(false);
    }
  }

  const hasFilters = filterGroup !== ALL || filterGender !== ALL || filterStatus !== ALL;

  function clearFilters() {
    setFilterGroup(ALL);
    setFilterGender(ALL);
    setFilterStatus(ALL);
    setSearch("");
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">회원 관리</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            전체 {members.length}명
            {filtered.length !== members.length && ` · 필터 결과 ${filtered.length}명`}
          </p>
        </div>
        <Button onClick={() => setShowAddDialog(true)} className="gap-2">
          <UserPlus className="w-4 h-4" />
          신규 등록
        </Button>
      </div>

      <Card className="border-0 shadow-sm">
        <CardHeader className="pb-3 space-y-3">
          {/* Search */}
          <div className="flex items-center gap-3">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
              <Input
                placeholder="이름 또는 목장으로 검색..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-9"
              />
            </div>
            <Button variant="outline" size="icon" onClick={loadMembers}>
              <RefreshCw className="w-4 h-4" />
            </Button>
          </div>

          {/* Filters */}
          <div className="flex items-center gap-2 flex-wrap">
            <Select value={filterGroup} onValueChange={(v) => setFilterGroup(v ?? ALL)}>
              <SelectTrigger className="w-[140px] h-9 text-sm">
                <SelectValue>{filterGroup === ALL ? "전체 목장" : filterGroup}</SelectValue>
              </SelectTrigger>
              <SelectContent>
                <SelectItem value={ALL}>전체 목장</SelectItem>
                {groupNames.filter((g) => g !== "미배정").map((g) => (
                  <SelectItem key={g} value={g}>
                    {g}
                  </SelectItem>
                ))}
                {groupNames.includes("미배정") && (
                  <>
                    <div className="my-1 border-t border-slate-200 dark:border-slate-700" />
                    <SelectItem value="미배정">미배정</SelectItem>
                  </>
                )}
              </SelectContent>
            </Select>

            <Select value={filterGender} onValueChange={(v) => setFilterGender(v ?? ALL)}>
              <SelectTrigger className="w-[100px] h-9 text-sm">
                <SelectValue>{filterGender === ALL ? "성별" : filterGender === "M" ? "남" : "여"}</SelectValue>
              </SelectTrigger>
              <SelectContent>
                <SelectItem value={ALL}>전체</SelectItem>
                {genderOptions.map((o) => (
                  <SelectItem key={o.value} value={o.value}>
                    {o.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select value={filterStatus} onValueChange={(v) => setFilterStatus(v ?? ALL)}>
              <SelectTrigger className="w-[110px] h-9 text-sm">
                <SelectValue>{filterStatus === ALL ? "상태" : filterStatus === "active" ? "활성" : "미변경"}</SelectValue>
              </SelectTrigger>
              <SelectContent>
                <SelectItem value={ALL}>전체</SelectItem>
                {statusOptions.map((o) => (
                  <SelectItem key={o.value} value={o.value}>
                    {o.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            {hasFilters && (
              <Button
                variant="ghost"
                size="sm"
                onClick={clearFilters}
                className="gap-1 text-slate-500 hover:text-slate-700"
              >
                <X className="w-3 h-3" />
                초기화
              </Button>
            )}
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>이름</TableHead>
                <TableHead>목장</TableHead>
                <TableHead>성별</TableHead>
                <TableHead>생년월일</TableHead>
                <TableHead>상태</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={5} className="text-center py-10 text-slate-400">
                    불러오는 중...
                  </TableCell>
                </TableRow>
              ) : filtered.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} className="text-center py-10 text-slate-400">
                    검색 결과가 없습니다
                  </TableCell>
                </TableRow>
              ) : (
                filtered.map((m) => (
                  <TableRow key={m.memberId}>
                    <TableCell className="font-medium">{m.name}</TableCell>
                    <TableCell>
                      <Badge variant="secondary" className="font-normal">
                        {m.groupName}
                      </Badge>
                    </TableCell>
                    <TableCell>{m.gender === "M" ? "남" : m.gender === "W" ? "여" : "-"}</TableCell>
                    <TableCell className="text-slate-500">{m.birthDate || "-"}</TableCell>
                    <TableCell>
                      {m.isFirstLogin ? (
                        <Badge variant="outline" className="text-amber-600 border-amber-300">
                          미변경
                        </Badge>
                      ) : (
                        <Badge variant="outline" className="text-emerald-600 border-emerald-300">
                          활성
                        </Badge>
                      )}
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Add Member Dialog */}
      <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>신규 회원 등록</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="newName">이름 *</Label>
              <Input
                id="newName"
                placeholder="이름을 입력하세요"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="newBirth">생년월일</Label>
              <Input
                id="newBirth"
                type="date"
                value={newBirthDate}
                onChange={(e) => setNewBirthDate(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label>성별</Label>
              <Select value={newGender} onValueChange={(v) => setNewGender(v ?? "M")}>
                <SelectTrigger>
                  <SelectValue>{newGender === "M" ? "남" : "여"}</SelectValue>
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="M">남</SelectItem>
                  <SelectItem value="W">여</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>목장 배정</Label>
              <Select value={newGroupId} onValueChange={(v) => setNewGroupId(v ?? "none")}>
                <SelectTrigger>
                  <SelectValue>{newGroupId !== "none" ? groups.find((g) => g.id === Number(newGroupId))?.name ?? "선택" : "미배정"}</SelectValue>
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="none">미배정</SelectItem>
                  {groups.filter((g) => g.name !== "임원").map((g) => (
                    <SelectItem key={g.id} value={String(g.id)}>
                      {g.name} 목장
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <p className="text-xs text-slate-400">
              기본 비밀번호 woncheon2025 로 생성됩니다. 첫 로그인 시 변경 필요.
            </p>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowAddDialog(false)}>
              취소
            </Button>
            <Button onClick={handleAddMember} disabled={adding}>
              {adding ? "등록 중..." : "등록"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
