"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Search, Trash2, RefreshCw } from "lucide-react";
import { toast } from "sonner";
import { format } from "date-fns";
import { ko } from "date-fns/locale";

interface Prayer {
  prayerId: string;
  authorName: string;
  isAnonymous: boolean;
  memberId: string;
  content: string;
  createdAt: string;
}

export default function PrayersPage() {
  const [prayers, setPrayers] = useState<Prayer[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [deleteTarget, setDeleteTarget] = useState<Prayer | null>(null);
  const [deleting, setDeleting] = useState(false);

  async function loadPrayers() {
    setLoading(true);
    try {
      const res = await fetch("/api/admin/prayers");
      const data = await res.json();
      setPrayers(data.prayers ?? []);
    } catch {
      toast.error("기도 목록을 불러올 수 없습니다.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadPrayers();
  }, []);

  async function handleDelete() {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      const res = await fetch(
        `/api/admin/prayers?prayerId=${deleteTarget.prayerId}`,
        { method: "DELETE" }
      );
      if (res.ok) {
        toast.success("삭제되었습니다.");
        setPrayers((prev) =>
          prev.filter((p) => p.prayerId !== deleteTarget.prayerId)
        );
      } else {
        toast.error("삭제에 실패했습니다.");
      }
    } catch {
      toast.error("삭제에 실패했습니다.");
    } finally {
      setDeleting(false);
      setDeleteTarget(null);
    }
  }

  const filtered = prayers.filter(
    (p) =>
      p.content.includes(search) ||
      p.authorName.includes(search)
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">중보기도 관리</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            전체 {prayers.length}개
          </p>
        </div>
        <Button variant="outline" onClick={loadPrayers} className="gap-2">
          <RefreshCw className="w-4 h-4" />
          새로고침
        </Button>
      </div>

      <Card className="border-0 shadow-sm">
        <CardHeader className="pb-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <Input
              placeholder="내용 또는 작성자로 검색..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-9"
            />
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[100px]">작성자</TableHead>
                <TableHead>내용</TableHead>
                <TableHead className="w-[120px]">날짜</TableHead>
                <TableHead className="w-[60px]">삭제</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={4} className="text-center py-10 text-slate-400">
                    불러오는 중...
                  </TableCell>
                </TableRow>
              ) : filtered.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={4} className="text-center py-10 text-slate-400">
                    검색 결과가 없습니다
                  </TableCell>
                </TableRow>
              ) : (
                filtered.map((p) => (
                  <TableRow key={p.prayerId}>
                    <TableCell>
                      <div className="flex items-center gap-1.5">
                        <span className="font-medium">{p.authorName}</span>
                        {p.isAnonymous && (
                          <Badge variant="outline" className="text-[10px] px-1.5 py-0">
                            익명
                          </Badge>
                        )}
                      </div>
                    </TableCell>
                    <TableCell className="max-w-md truncate text-slate-600 dark:text-slate-300">
                      {p.content}
                    </TableCell>
                    <TableCell className="text-slate-500 text-xs">
                      {format(new Date(p.createdAt), "M/d (E) HH:mm", {
                        locale: ko,
                      })}
                    </TableCell>
                    <TableCell>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="text-slate-400 hover:text-red-500"
                        onClick={() => setDeleteTarget(p)}
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Delete dialog */}
      <Dialog
        open={!!deleteTarget}
        onOpenChange={() => setDeleteTarget(null)}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>기도 삭제</DialogTitle>
            <DialogDescription>
              이 기도와 관련된 댓글/반응도 모두 삭제됩니다.
            </DialogDescription>
          </DialogHeader>
          <div className="bg-slate-50 dark:bg-slate-900 rounded-lg p-3 text-sm">
            <p className="font-medium mb-1">{deleteTarget?.authorName}</p>
            <p className="text-slate-500 line-clamp-3">{deleteTarget?.content}</p>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteTarget(null)}>
              취소
            </Button>
            <Button
              variant="destructive"
              onClick={handleDelete}
              disabled={deleting}
            >
              {deleting ? "삭제 중..." : "삭제"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
