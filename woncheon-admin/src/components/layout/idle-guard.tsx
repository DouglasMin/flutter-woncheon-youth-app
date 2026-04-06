"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";

const IDLE_TIMEOUT = 5 * 60 * 1000; // 5 minutes
const WARNING_BEFORE = 60 * 1000; // Show warning 1 minute before logout

export function IdleGuard() {
  const router = useRouter();
  const [showWarning, setShowWarning] = useState(false);
  const [secondsLeft, setSecondsLeft] = useState(60);
  const idleTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const warningTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const countdownRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const isHidden = useRef(false);
  const hiddenSince = useRef<number | null>(null);

  const logout = useCallback(async () => {
    await fetch("/api/auth/logout", { method: "POST" });
    router.push("/login");
    router.refresh();
  }, [router]);

  const resetTimers = useCallback(() => {
    // Clear all existing timers
    if (idleTimer.current) clearTimeout(idleTimer.current);
    if (warningTimer.current) clearTimeout(warningTimer.current);
    if (countdownRef.current) clearInterval(countdownRef.current);

    setShowWarning(false);
    setSecondsLeft(60);

    // Show warning at 4 minutes
    warningTimer.current = setTimeout(() => {
      setShowWarning(true);
      setSecondsLeft(60);

      countdownRef.current = setInterval(() => {
        setSecondsLeft((prev) => {
          if (prev <= 1) {
            if (countdownRef.current) clearInterval(countdownRef.current);
            return 0;
          }
          return prev - 1;
        });
      }, 1000);
    }, IDLE_TIMEOUT - WARNING_BEFORE);

    // Auto logout at 5 minutes
    idleTimer.current = setTimeout(() => {
      logout();
    }, IDLE_TIMEOUT);
  }, [logout]);

  const handleStayLoggedIn = useCallback(() => {
    resetTimers();
  }, [resetTimers]);

  // Activity listeners
  useEffect(() => {
    const events = ["mousedown", "keydown", "scroll", "touchstart"];

    function onActivity() {
      if (!showWarning) {
        resetTimers();
      }
    }

    events.forEach((e) => window.addEventListener(e, onActivity));
    resetTimers();

    return () => {
      events.forEach((e) => window.removeEventListener(e, onActivity));
      if (idleTimer.current) clearTimeout(idleTimer.current);
      if (warningTimer.current) clearTimeout(warningTimer.current);
      if (countdownRef.current) clearInterval(countdownRef.current);
    };
  }, [resetTimers, showWarning]);

  // Visibility change — browser tab hidden for 5 minutes
  useEffect(() => {
    function onVisibilityChange() {
      if (document.hidden) {
        isHidden.current = true;
        hiddenSince.current = Date.now();
      } else {
        isHidden.current = false;
        if (hiddenSince.current) {
          const elapsed = Date.now() - hiddenSince.current;
          if (elapsed >= IDLE_TIMEOUT) {
            logout();
          }
          hiddenSince.current = null;
        }
      }
    }

    document.addEventListener("visibilitychange", onVisibilityChange);
    return () =>
      document.removeEventListener("visibilitychange", onVisibilityChange);
  }, [logout]);

  return (
    <Dialog open={showWarning} onOpenChange={() => {}}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>세션 만료 경고</DialogTitle>
          <DialogDescription>
            {secondsLeft}초 후 자동으로 로그아웃됩니다.
            <br />
            계속 사용하시려면 아래 버튼을 눌러주세요.
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button onClick={handleStayLoggedIn} className="w-full">
            계속 사용하기
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
