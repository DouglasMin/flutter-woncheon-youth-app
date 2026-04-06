import { Sidebar } from "@/components/layout/sidebar";
import { Header } from "@/components/layout/header";
import { IdleGuard } from "@/components/layout/idle-guard";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex h-screen">
      <Sidebar />
      <div className="flex-1 flex flex-col overflow-hidden">
        <Header />
        <main className="flex-1 overflow-y-auto bg-slate-50 dark:bg-slate-950 p-6">
          {children}
        </main>
      </div>
      <IdleGuard />
    </div>
  );
}
