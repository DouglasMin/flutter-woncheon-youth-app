"use client";

import { useEffect, useState } from "react";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Search, UserPlus, RefreshCw } from "lucide-react";
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

export default function MembersPage() {
  const [members, setMembers] = useState<Member[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

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
  }, []);

  const filtered = members.filter(
    (m) =>
      m.name.includes(search) ||
      m.groupName.includes(search)
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">회원 관리</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            전체 {members.length}명
          </p>
        </div>
        <Button
          onClick={() => toast.info("신규 회원 등록은 준비 중입니다.")}
          className="gap-2"
        >
          <UserPlus className="w-4 h-4" />
          신규 등록
        </Button>
      </div>

      <Card className="border-0 shadow-sm">
        <CardHeader className="pb-3">
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
    </div>
  );
}
