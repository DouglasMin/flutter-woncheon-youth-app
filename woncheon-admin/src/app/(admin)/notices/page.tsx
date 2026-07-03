"use client";

import { useEffect, useMemo, useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { format } from "date-fns";
import { ko } from "date-fns/locale";
import {
  Megaphone,
  Pencil,
  Plus,
  RefreshCw,
  Search,
  Send,
  Trash2,
} from "lucide-react";
import { toast } from "sonner";

type NoticeStatus = "draft" | "published";
type NotificationStatus = "pending" | "sending" | "sent" | "partial_fail" | "failed";

interface Notice {
  noticeId: string;
  title: string;
  content: string;
  status: NoticeStatus;
  pinned: boolean;
  createdAt: string;
  updatedAt: string;
  publishedAt: string | null;
  notifiedAt: string | null;
  notificationStatus: NotificationStatus | null;
  notificationRecipientCount: number;
  notificationSuccessCount: number;
  notificationFailureCount: number;
}

interface NoticeForm {
  noticeId?: string;
  title: string;
  content: string;
  status: NoticeStatus;
  pinned: boolean;
}

const emptyForm: NoticeForm = {
  title: "",
  content: "",
  status: "draft",
  pinned: false,
};

function statusBadge(status: NoticeStatus) {
  if (status === "published") {
    return (
      <Badge variant="outline" className="border-emerald-300 text-emerald-600">
        게시 중
      </Badge>
    );
  }
  return <Badge variant="outline">임시 저장</Badge>;
}

function notificationBadge(notice: Notice) {
  if (!notice.notificationStatus) {
    return <span className="text-xs text-slate-400">-</span>;
  }

  const labels: Record<NotificationStatus, string> = {
    pending: "발송 대기",
    sending: "발송 중",
    sent: "발송 완료",
    partial_fail: "일부 실패",
    failed: "실패",
  };
  const className =
    notice.notificationStatus === "sent"
      ? "border-emerald-300 text-emerald-600"
      : notice.notificationStatus === "failed" || notice.notificationStatus === "partial_fail"
        ? "border-rose-300 text-rose-600"
        : "border-amber-300 text-amber-600";

  return (
    <div className="flex flex-col gap-1">
      <Badge variant="outline" className={className}>
        {labels[notice.notificationStatus]}
      </Badge>
      {notice.notifiedAt && (
        <span className="text-[11px] text-slate-400">
          {notice.notificationSuccessCount}/{notice.notificationRecipientCount}명
        </span>
      )}
    </div>
  );
}

function formatDate(value: string | null | undefined) {
  if (!value) return "-";
  return format(new Date(value), "M/d (E) HH:mm", { locale: ko });
}

export default function NoticesPage() {
  const [notices, setNotices] = useState<Notice[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [form, setForm] = useState<NoticeForm>(emptyForm);
  const [editorOpen, setEditorOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<Notice | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [processingId, setProcessingId] = useState<string | null>(null);

  async function loadNotices() {
    setLoading(true);
    try {
      const res = await fetch("/api/admin/notices", { credentials: "include" });
      const data = await res.json();
      setNotices(data.notices ?? []);
    } catch {
      toast.error("공지 목록을 불러올 수 없습니다.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadNotices();
  }, []);

  const filtered = useMemo(() => {
    const query = search.trim();
    if (!query) return notices;
    return notices.filter(
      (notice) => notice.title.includes(query) || notice.content.includes(query),
    );
  }, [notices, search]);

  function openCreate() {
    setForm(emptyForm);
    setEditorOpen(true);
  }

  function openEdit(notice: Notice) {
    setForm({
      noticeId: notice.noticeId,
      title: notice.title,
      content: notice.content,
      status: notice.status,
      pinned: notice.pinned,
    });
    setEditorOpen(true);
  }

  async function saveNotice() {
    if (!form.title.trim() || !form.content.trim()) {
      toast.error("제목과 내용을 입력해주세요.");
      return;
    }

    setSaving(true);
    try {
      const res = await fetch("/api/admin/notices", {
        method: form.noticeId ? "PUT" : "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          noticeId: form.noticeId,
          title: form.title,
          content: form.content,
          status: form.status,
          pinned: form.pinned,
        }),
      });
      const data = await res.json();

      if (!res.ok) {
        toast.error(data.error ?? "공지 저장에 실패했습니다.");
        return;
      }

      toast.success(form.noticeId ? "공지사항을 수정했습니다." : "공지사항을 만들었습니다.");
      setEditorOpen(false);
      await loadNotices();
    } catch {
      toast.error("공지 저장에 실패했습니다.");
    } finally {
      setSaving(false);
    }
  }

  async function toggleStatus(notice: Notice) {
    const nextStatus: NoticeStatus =
      notice.status === "published" ? "draft" : "published";
    setProcessingId(notice.noticeId);
    try {
      const res = await fetch("/api/admin/notices", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          noticeId: notice.noticeId,
          title: notice.title,
          content: notice.content,
          status: nextStatus,
          pinned: notice.pinned,
        }),
      });
      const data = await res.json();
      if (!res.ok) {
        toast.error(data.error ?? "상태 변경에 실패했습니다.");
        return;
      }

      toast.success(nextStatus === "published" ? "공지사항을 게시했습니다." : "공지사항을 내렸습니다.");
      await loadNotices();
    } catch {
      toast.error("상태 변경에 실패했습니다.");
    } finally {
      setProcessingId(null);
    }
  }

  async function deleteNotice() {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      const res = await fetch(
        `/api/admin/notices?noticeId=${deleteTarget.noticeId}`,
        {
          method: "DELETE",
          credentials: "include",
        },
      );
      const data = await res.json();
      if (!res.ok) {
        toast.error(data.error ?? "삭제에 실패했습니다.");
        return;
      }

      toast.success("공지사항을 삭제했습니다.");
      setNotices((prev) =>
        prev.filter((notice) => notice.noticeId !== deleteTarget.noticeId),
      );
    } catch {
      toast.error("삭제에 실패했습니다.");
    } finally {
      setDeleting(false);
      setDeleteTarget(null);
    }
  }

  const publishedCount = notices.filter((notice) => notice.status === "published").length;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">공지사항</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            게시 중 {publishedCount}건 · 전체 {notices.length}건
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" onClick={loadNotices} className="gap-2">
            <RefreshCw className="h-4 w-4" />
            새로고침
          </Button>
          <Button onClick={openCreate} className="gap-2">
            <Plus className="h-4 w-4" />
            새 공지
          </Button>
        </div>
      </div>

      <Card className="border-0 shadow-sm">
        <CardHeader className="pb-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <Input
              placeholder="제목 또는 내용으로 검색..."
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              className="pl-9"
            />
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>공지</TableHead>
                <TableHead className="w-[95px]">상태</TableHead>
                <TableHead className="w-[115px]">푸시</TableHead>
                <TableHead className="w-[125px]">게시일</TableHead>
                <TableHead className="w-[190px] text-right">작업</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={5} className="py-10 text-center text-slate-400">
                    불러오는 중...
                  </TableCell>
                </TableRow>
              ) : filtered.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} className="py-10 text-center text-slate-400">
                    등록된 공지사항이 없습니다
                  </TableCell>
                </TableRow>
              ) : (
                filtered.map((notice) => (
                  <TableRow key={notice.noticeId}>
                    <TableCell>
                      <div className="flex items-start gap-2">
                        {notice.pinned && (
                          <Megaphone className="mt-0.5 h-4 w-4 text-sky-500" />
                        )}
                        <div className="min-w-0">
                          <p className="truncate font-medium">{notice.title}</p>
                          <p className="line-clamp-2 max-w-xl text-sm text-slate-500 dark:text-slate-400">
                            {notice.content}
                          </p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>{statusBadge(notice.status)}</TableCell>
                    <TableCell>{notificationBadge(notice)}</TableCell>
                    <TableCell className="text-xs text-slate-500">
                      {formatDate(notice.publishedAt)}
                    </TableCell>
                    <TableCell>
                      <div className="flex justify-end gap-1">
                        <Button
                          variant="ghost"
                          size="sm"
                          className="gap-1"
                          disabled={processingId === notice.noticeId}
                          onClick={() => toggleStatus(notice)}
                        >
                          <Send className="h-3.5 w-3.5" />
                          {notice.status === "published" ? "내리기" : "게시"}
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => openEdit(notice)}
                        >
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="text-slate-400 hover:text-red-500"
                          onClick={() => setDeleteTarget(notice)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <Dialog open={editorOpen} onOpenChange={setEditorOpen}>
        <DialogContent className="sm:max-w-2xl">
          <DialogHeader>
            <DialogTitle>{form.noticeId ? "공지사항 수정" : "새 공지사항"}</DialogTitle>
            <DialogDescription>
              게시로 저장하면 최초 1회만 전체 기기에 푸시 알림이 발송됩니다.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <Input
              placeholder="제목"
              value={form.title}
              maxLength={80}
              onChange={(event) =>
                setForm((prev) => ({ ...prev, title: event.target.value }))
              }
            />
            <textarea
              placeholder="내용"
              value={form.content}
              maxLength={3000}
              rows={10}
              onChange={(event) =>
                setForm((prev) => ({ ...prev, content: event.target.value }))
              }
              className="min-h-56 w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm outline-none ring-offset-white placeholder:text-slate-400 focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2 dark:border-slate-800 dark:bg-slate-950 dark:ring-offset-slate-950 dark:focus-visible:ring-slate-300"
            />
            <div className="flex flex-wrap items-center gap-4 text-sm">
              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={form.pinned}
                  onChange={(event) =>
                    setForm((prev) => ({ ...prev, pinned: event.target.checked }))
                  }
                />
                상단 고정 표시
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={form.status === "published"}
                  onChange={(event) =>
                    setForm((prev) => ({
                      ...prev,
                      status: event.target.checked ? "published" : "draft",
                    }))
                  }
                />
                게시 상태로 저장
              </label>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setEditorOpen(false)}>
              취소
            </Button>
            <Button onClick={saveNotice} disabled={saving}>
              {saving ? "저장 중..." : "저장"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={!!deleteTarget} onOpenChange={() => setDeleteTarget(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>공지사항 삭제</DialogTitle>
            <DialogDescription>
              삭제한 공지사항은 앱에서 더 이상 볼 수 없습니다.
            </DialogDescription>
          </DialogHeader>
          <div className="rounded-lg bg-slate-50 p-3 text-sm dark:bg-slate-900">
            <p className="mb-1 font-medium">{deleteTarget?.title}</p>
            <p className="line-clamp-3 text-slate-500">{deleteTarget?.content}</p>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteTarget(null)}>
              취소
            </Button>
            <Button variant="destructive" onClick={deleteNotice} disabled={deleting}>
              {deleting ? "삭제 중..." : "삭제"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
