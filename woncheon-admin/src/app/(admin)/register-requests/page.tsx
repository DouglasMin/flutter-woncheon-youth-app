"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Check, X, RefreshCw } from "lucide-react";
import { toast } from "sonner";
import { format } from "date-fns";
import { ko } from "date-fns/locale";

interface RegisterRequest {
  requestId: string;
  name: string;
  phone: string;
  note: string;
  status: string;
  createdAt: string;
}

export default function RegisterRequestsPage() {
  const [requests, setRequests] = useState<RegisterRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState<string | null>(null);

  async function loadRequests() {
    setLoading(true);
    try {
      const res = await fetch("/api/admin/register-requests", {
        credentials: "include",
      });
      const data = await res.json();
      setRequests(data.requests ?? []);
    } catch {
      toast.error("요청 목록을 불러올 수 없습니다.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadRequests();
  }, []);

  async function handleAction(requestId: string, action: "approve" | "reject") {
    setProcessing(requestId);
    try {
      const res = await fetch("/api/admin/register-requests", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ requestId, action }),
      });
      const data = await res.json();

      if (!res.ok) {
        toast.error(data.error ?? "처리에 실패했습니다.");
        return;
      }

      toast.success(
        action === "approve"
          ? `${data.name} 회원이 등록되었습니다.`
          : "요청이 거부되었습니다."
      );
      loadRequests();
    } catch {
      toast.error("처리에 실패했습니다.");
    } finally {
      setProcessing(null);
    }
  }

  const pending = requests.filter((r) => r.status === "pending");
  const processed = requests.filter((r) => r.status !== "pending");

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">가입 요청</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            대기 {pending.length}건 · 처리됨 {processed.length}건
          </p>
        </div>
        <Button
          variant="outline"
          onClick={loadRequests}
          className="gap-2"
        >
          <RefreshCw className="w-4 h-4" />
          새로고침
        </Button>
      </div>

      {/* Pending */}
      {pending.length > 0 && (
        <Card className="border-0 shadow-sm">
          <CardHeader className="pb-2">
            <h2 className="text-lg font-semibold">대기 중</h2>
          </CardHeader>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>이름</TableHead>
                  <TableHead>연락처</TableHead>
                  <TableHead>메모</TableHead>
                  <TableHead>요청일</TableHead>
                  <TableHead className="text-right">승인/거부</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {pending.map((r) => (
                  <TableRow key={r.requestId}>
                    <TableCell className="font-medium">{r.name}</TableCell>
                    <TableCell>{r.phone}</TableCell>
                    <TableCell className="text-slate-500 max-w-[200px] truncate">
                      {r.note || "-"}
                    </TableCell>
                    <TableCell className="text-slate-500 text-sm">
                      {format(new Date(r.createdAt), "M/d (E) HH:mm", {
                        locale: ko,
                      })}
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Button
                          size="sm"
                          className="gap-1"
                          disabled={processing === r.requestId}
                          onClick={() => handleAction(r.requestId, "approve")}
                        >
                          <Check className="w-3.5 h-3.5" />
                          승인
                        </Button>
                        <Button
                          size="sm"
                          variant="outline"
                          className="gap-1"
                          disabled={processing === r.requestId}
                          onClick={() => handleAction(r.requestId, "reject")}
                        >
                          <X className="w-3.5 h-3.5" />
                          거부
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}

      {pending.length === 0 && !loading && (
        <Card className="border-0 shadow-sm">
          <CardContent className="py-12 text-center text-slate-400">
            대기 중인 요청이 없습니다.
          </CardContent>
        </Card>
      )}

      {/* Processed */}
      {processed.length > 0 && (
        <Card className="border-0 shadow-sm">
          <CardHeader className="pb-2">
            <h2 className="text-lg font-semibold">처리됨</h2>
          </CardHeader>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>이름</TableHead>
                  <TableHead>연락처</TableHead>
                  <TableHead>상태</TableHead>
                  <TableHead>요청일</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {processed.map((r) => (
                  <TableRow key={r.requestId}>
                    <TableCell className="font-medium">{r.name}</TableCell>
                    <TableCell>{r.phone}</TableCell>
                    <TableCell>
                      {r.status === "approved" ? (
                        <Badge variant="outline" className="text-emerald-600 border-emerald-300">
                          승인됨
                        </Badge>
                      ) : (
                        <Badge variant="outline" className="text-red-600 border-red-300">
                          거부됨
                        </Badge>
                      )}
                    </TableCell>
                    <TableCell className="text-slate-500 text-sm">
                      {format(new Date(r.createdAt), "M/d (E)", {
                        locale: ko,
                      })}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
