"use client";

import { useEffect, useMemo, useState } from "react";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import {
  Tabs,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
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
import { Search, RefreshCw, Flag, Trash2, Check, X } from "lucide-react";
import { toast } from "sonner";
import { format, formatDistanceToNow } from "date-fns";
import { ko } from "date-fns/locale";

type ReportStatus = "pending" | "resolved" | "dismissed";
type ReportTab = ReportStatus | "all";
type ReportAction = "dismiss" | "resolve" | "delete-and-resolve";

interface Report {
  reportId: string;
  reporterMemberId: string;
  reporterName: string | null;
  targetType: "prayer" | "comment";
  targetId: string;
  reason: string;
  status: ReportStatus;
  createdAt: string;
  resolvedAt?: string;
  resolutionNote?: string;
  resolutionAction?: ReportAction;
  target: {
    exists: boolean;
    authorMemberId: string | null;
    authorName: string | null;
    isAnonymous: boolean | null;
    content: string | null;
    createdAt: string | null;
  };
}

const STATUS_LABEL: Record<ReportStatus, string> = {
  pending: "미처리",
  resolved: "처리 완료",
  dismissed: "무효 처리",
};

const STATUS_VARIANT: Record<ReportStatus, "default" | "secondary" | "outline"> = {
  pending: "default",
  resolved: "secondary",
  dismissed: "outline",
};

export default function ReportsPage() {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState<ReportTab>("pending");
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<Report | null>(null);
  const [pendingAction, setPendingAction] = useState<ReportAction | null>(null);
  const [actionNote, setActionNote] = useState("");
  const [submitting, setSubmitting] = useState(false);

  async function loadReports(nextTab: ReportTab = tab) {
    setLoading(true);
    try {
      const res = await fetch(`/api/admin/reports?status=${nextTab}`);
      if (!res.ok) throw new Error("failed");
      const data = (await res.json()) as { reports: Report[] };
      setReports(data.reports ?? []);
    } catch {
      toast.error("신고 목록을 불러올 수 없습니다.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadReports(tab);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab]);

  const filtered = useMemo(() => {
    if (!search.trim()) return reports;
    const q = search.trim().toLowerCase();
    return reports.filter((r) => {
      const haystack = [
        r.reporterName ?? "",
        r.reason,
        r.target.authorName ?? "",
        r.target.content ?? "",
      ]
        .join(" ")
        .toLowerCase();
      return haystack.includes(q);
    });
  }, [reports, search]);

  const pendingCount = useMemo(
    () => reports.filter((r) => r.status === "pending").length,
    [reports]
  );

  function openAction(report: Report, action: ReportAction) {
    setSelected(report);
    setPendingAction(action);
    setActionNote("");
  }

  function closeDialog() {
    if (submitting) return;
    setSelected(null);
    setPendingAction(null);
    setActionNote("");
  }

  async function submitAction() {
    if (!selected || !pendingAction) return;
    setSubmitting(true);
    try {
      const res = await fetch(`/api/admin/reports/${selected.reportId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          action: pendingAction,
          note: actionNote.trim() || undefined,
        }),
      });
      const data = await res.json();
      if (!res.ok) {
        toast.error(data.error ?? "처리에 실패했습니다.");
        return;
      }
      const successMsg =
        pendingAction === "delete-and-resolve"
          ? `컨텐츠 ${data.deletedItemCount}개 삭제됨`
          : pendingAction === "dismiss"
            ? "무효 처리됨"
            : "처리 완료";
      toast.success(successMsg);
      closeDialog();
      await loadReports(tab);
    } catch {
      toast.error("처리에 실패했습니다.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight flex items-center gap-2">
            <Flag className="w-6 h-6 text-rose-500" />
            신고 검토
          </h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            미처리 {pendingCount}건 / 표시 {reports.length}건
          </p>
        </div>
        <Button
          variant="outline"
          onClick={() => loadReports(tab)}
          className="gap-2"
        >
          <RefreshCw className="w-4 h-4" />
          새로고침
        </Button>
      </div>

      <Tabs value={tab} onValueChange={(v) => setTab(v as ReportTab)}>
        <TabsList>
          <TabsTrigger value="pending">미처리</TabsTrigger>
          <TabsTrigger value="resolved">처리 완료</TabsTrigger>
          <TabsTrigger value="dismissed">무효 처리</TabsTrigger>
          <TabsTrigger value="all">전체</TabsTrigger>
        </TabsList>
      </Tabs>

      <Card className="border-0 shadow-sm">
        <CardHeader className="pb-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <Input
              placeholder="신고자, 사유, 본문, 대상 작성자로 검색..."
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
                <TableHead className="w-[80px]">종류</TableHead>
                <TableHead>대상 본문</TableHead>
                <TableHead className="w-[120px]">대상 작성자</TableHead>
                <TableHead className="w-[100px]">신고자</TableHead>
                <TableHead className="w-[120px]">사유</TableHead>
                <TableHead className="w-[120px]">접수</TableHead>
                <TableHead className="w-[100px]">상태</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell
                    colSpan={7}
                    className="text-center py-10 text-slate-400"
                  >
                    불러오는 중...
                  </TableCell>
                </TableRow>
              ) : filtered.length === 0 ? (
                <TableRow>
                  <TableCell
                    colSpan={7}
                    className="text-center py-10 text-slate-400"
                  >
                    {tab === "pending"
                      ? "미처리 신고가 없습니다 🎉"
                      : "표시할 신고가 없습니다"}
                  </TableCell>
                </TableRow>
              ) : (
                filtered.map((r) => (
                  <TableRow
                    key={r.reportId}
                    className="cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-900"
                    onClick={() => setSelected(r)}
                  >
                    <TableCell>
                      <Badge variant="outline" className="text-[11px]">
                        {r.targetType === "prayer" ? "기도" : "댓글"}
                      </Badge>
                    </TableCell>
                    <TableCell className="max-w-md truncate text-slate-600 dark:text-slate-300">
                      {r.target.exists
                        ? r.target.content
                        : r.targetType === "comment"
                          ? "(댓글 본문 — admin 미연결)"
                          : "(삭제됨)"}
                    </TableCell>
                    <TableCell className="text-slate-500">
                      {r.target.exists
                        ? r.target.isAnonymous
                          ? `${r.target.authorName} (익명)`
                          : r.target.authorName
                        : "—"}
                    </TableCell>
                    <TableCell className="text-slate-500">
                      {r.reporterName ?? "—"}
                    </TableCell>
                    <TableCell className="text-slate-500 text-xs">
                      {r.reason}
                    </TableCell>
                    <TableCell className="text-slate-500 text-xs">
                      {formatDistanceToNow(new Date(r.createdAt), {
                        addSuffix: true,
                        locale: ko,
                      })}
                    </TableCell>
                    <TableCell>
                      <Badge variant={STATUS_VARIANT[r.status]}>
                        {STATUS_LABEL[r.status]}
                      </Badge>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* 상세 + 액션 Dialog */}
      <Dialog open={!!selected} onOpenChange={(open) => !open && closeDialog()}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Flag className="w-5 h-5 text-rose-500" />
              신고 상세
              {selected && (
                <Badge variant={STATUS_VARIANT[selected.status]} className="ml-2">
                  {STATUS_LABEL[selected.status]}
                </Badge>
              )}
            </DialogTitle>
            {pendingAction && (
              <DialogDescription>
                {pendingAction === "delete-and-resolve"
                  ? "신고된 컨텐츠가 영구 삭제됩니다 (관련 댓글·반응 포함)."
                  : pendingAction === "dismiss"
                    ? "신고만 무효 처리하고 컨텐츠는 유지됩니다."
                    : "신고를 검토 완료 상태로 닫습니다."}
              </DialogDescription>
            )}
          </DialogHeader>

          {selected && (
            <div className="space-y-4 text-sm">
              <DetailRow label="신고 종류">
                <Badge variant="outline">
                  {selected.targetType === "prayer" ? "중보기도" : "댓글"}
                </Badge>
              </DetailRow>
              <DetailRow label="신고자">
                {selected.reporterName ?? "—"}{" "}
                <span className="text-xs text-slate-400">
                  ({selected.reporterMemberId})
                </span>
              </DetailRow>
              <DetailRow label="사유">{selected.reason || "(미입력)"}</DetailRow>
              <DetailRow label="접수 시각">
                {format(new Date(selected.createdAt), "yyyy-MM-dd HH:mm", {
                  locale: ko,
                })}
              </DetailRow>
              <DetailRow label="대상 작성자">
                {selected.target.exists ? (
                  <span>
                    {selected.target.authorName}{" "}
                    {selected.target.isAnonymous && (
                      <Badge variant="outline" className="text-[10px] ml-1">
                        앱에는 익명으로 표시
                      </Badge>
                    )}
                    <span className="text-xs text-slate-400 ml-1">
                      ({selected.target.authorMemberId})
                    </span>
                  </span>
                ) : (
                  <span className="text-slate-400">
                    {selected.targetType === "comment"
                      ? "댓글 신고는 현재 관리자 미리보기 미지원"
                      : "(원본 삭제됨)"}
                  </span>
                )}
              </DetailRow>

              <div>
                <p className="text-xs font-medium text-slate-500 mb-1.5">
                  대상 본문
                </p>
                <div className="bg-slate-50 dark:bg-slate-900 rounded-lg p-3 text-sm whitespace-pre-wrap min-h-[60px]">
                  {selected.target.exists ? (
                    selected.target.content
                  ) : (
                    <span className="text-slate-400 italic">
                      {selected.targetType === "comment"
                        ? "댓글 본문 미연결 — 댓글 관리 화면에서 확인 필요"
                        : "원본 컨텐츠가 이미 삭제됨"}
                    </span>
                  )}
                </div>
              </div>

              {selected.status !== "pending" && (
                <DetailRow label="처리 결과">
                  <span className="text-slate-500">
                    {selected.resolutionAction ?? "—"}
                    {selected.resolvedAt &&
                      ` · ${format(new Date(selected.resolvedAt), "M/d HH:mm")}`}
                    {selected.resolutionNote && ` · ${selected.resolutionNote}`}
                  </span>
                </DetailRow>
              )}

              {selected.status === "pending" && pendingAction && (
                <div>
                  <p className="text-xs font-medium text-slate-500 mb-1.5">
                    처리 메모 (선택)
                  </p>
                  <Input
                    value={actionNote}
                    onChange={(e) => setActionNote(e.target.value)}
                    placeholder="예: 작성자에게 안내 완료"
                  />
                </div>
              )}
            </div>
          )}

          <DialogFooter className="gap-2 flex-wrap">
            {selected?.status === "pending" && !pendingAction && (
              <>
                <Button
                  variant="outline"
                  onClick={() => openAction(selected, "dismiss")}
                  className="gap-2"
                >
                  <X className="w-4 h-4" />
                  무효 처리
                </Button>
                <Button
                  variant="outline"
                  onClick={() => openAction(selected, "resolve")}
                  className="gap-2"
                >
                  <Check className="w-4 h-4" />
                  검토 완료
                </Button>
                {selected.targetType === "prayer" && selected.target.exists && (
                  <Button
                    variant="destructive"
                    onClick={() => openAction(selected, "delete-and-resolve")}
                    className="gap-2"
                  >
                    <Trash2 className="w-4 h-4" />
                    컨텐츠 삭제 + 처리
                  </Button>
                )}
              </>
            )}
            {pendingAction && (
              <>
                <Button
                  variant="outline"
                  onClick={() => setPendingAction(null)}
                  disabled={submitting}
                >
                  취소
                </Button>
                <Button
                  variant={
                    pendingAction === "delete-and-resolve"
                      ? "destructive"
                      : "default"
                  }
                  onClick={submitAction}
                  disabled={submitting}
                >
                  {submitting ? "처리 중..." : "확인"}
                </Button>
              </>
            )}
            {selected?.status !== "pending" && !pendingAction && (
              <Button variant="outline" onClick={closeDialog}>
                닫기
              </Button>
            )}
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function DetailRow({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div className="flex items-baseline gap-3">
      <span className="text-xs font-medium text-slate-500 w-24 shrink-0">
        {label}
      </span>
      <span className="text-sm text-slate-700 dark:text-slate-200">{children}</span>
    </div>
  );
}
