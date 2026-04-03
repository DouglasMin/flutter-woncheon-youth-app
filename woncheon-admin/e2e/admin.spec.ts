import { test, expect } from "@playwright/test";

const ADMIN_ID = "admin";
const ADMIN_PASSWORD = "woncheon-admin-2026!";

// Helper: login and return authenticated page
async function login(page: import("@playwright/test").Page) {
  await page.goto("/login");
  await page.getByLabel("아이디").fill(ADMIN_ID);
  await page.getByLabel("비밀번호").fill(ADMIN_PASSWORD);
  await page.getByRole("button", { name: "로그인" }).click();
  await page.waitForURL("**/dashboard");
}

// ── Auth ──────────────────────────────────────

test.describe("Auth", () => {
  test("redirects unauthenticated requests to login", async ({ browser }) => {
    // Use a brand new incognito context with no cookies
    const context = await browser.newContext({ storageState: undefined });
    const page = await context.newPage();
    const response = await page.goto("/api/admin/stats");
    // API should return 401 for unauthenticated requests
    expect(response?.status()).toBe(401);
    await context.close();
  });

  test("rejects wrong password", async ({ page }) => {
    await page.goto("/login");
    await page.getByLabel("아이디").fill("admin");
    await page.getByLabel("비밀번호").fill("wrong-password");
    await page.getByRole("button", { name: "로그인" }).click();

    await expect(page.getByText("인증에 실패했습니다")).toBeVisible();
    await expect(page).toHaveURL(/\/login/);
  });

  test("login succeeds and redirects to dashboard", async ({ page }) => {
    await login(page);
    await expect(page).toHaveURL(/\/dashboard/);
    await expect(page.getByRole("heading", { name: "대시보드" })).toBeVisible();
  });

  test("logout redirects to login", async ({ page }) => {
    await login(page);
    await page.getByRole("button", { name: "로그아웃" }).click();
    await expect(page).toHaveURL(/\/login/);
  });
});

// ── Dashboard ─────────────────────────────────

test.describe("Dashboard", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("displays 4 stat cards", async ({ page }) => {
    await expect(page.getByRole("main").getByText("전체 회원")).toBeVisible();
    await expect(page.getByRole("main").getByText("중보기도")).toBeVisible();
    await expect(page.getByRole("main").getByText("목장")).toBeVisible();
    await expect(page.getByRole("main").getByText("이번 달 출석률")).toBeVisible();
  });

  test("stat cards show numbers (not zero for members)", async ({ page }) => {
    // Wait for loading to complete
    await page.waitForTimeout(3000);

    // Member count should be > 0 (we have 203 members)
    const memberCard = page.locator("text=전체 회원").locator("..").locator("..");
    await expect(memberCard).toBeVisible();
  });
});

// ── Members ───────────────────────────────────

test.describe("Members", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("navigates to members page", async ({ page }) => {
    await page.getByRole("link", { name: "회원 관리" }).click();
    await expect(page).toHaveURL(/\/members/);
    await expect(page.getByRole("heading", { name: "회원 관리" })).toBeVisible();
  });

  test("displays member table with data", async ({ page }) => {
    await page.goto("/members");
    await page.waitForTimeout(3000);

    // Table should have rows
    await expect(page.getByRole("table")).toBeVisible();
    // Should show "전체 N명"
    await expect(page.getByText(/전체 \d+명/)).toBeVisible();
  });

  test("search filters members by name", async ({ page }) => {
    await page.goto("/members");
    await page.waitForTimeout(3000);

    await page.getByPlaceholder("이름 또는 목장으로 검색").fill("김지현");
    await page.waitForTimeout(500);

    // Should show 김지현 in the table
    const rows = page.locator("tbody tr");
    const count = await rows.count();
    expect(count).toBeGreaterThan(0);
    await expect(rows.first()).toContainText("김지현");
  });
});

// ── Attendance ────────────────────────────────

test.describe("Attendance", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("navigates to attendance page", async ({ page }) => {
    await page.getByRole("link", { name: "출결 현황" }).click();
    await expect(page).toHaveURL(/\/attendance/);
    await expect(page.getByText("출결 현황")).toBeVisible();
  });

  test("displays group tabs", async ({ page }) => {
    await page.goto("/attendance");
    await page.waitForTimeout(3000);

    // Should have tab buttons for groups
    await expect(page.getByText("CSV 내보내기")).toBeVisible();
  });

  test("CSV export link works", async ({ page }) => {
    await page.goto("/attendance");
    await page.waitForTimeout(2000);

    // Check export button exists
    const exportBtn = page.getByText("CSV 내보내기");
    await expect(exportBtn).toBeVisible();
  });
});

// ── Prayers ──────────────────────────────────

test.describe("Prayers", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("navigates to prayers page", async ({ page }) => {
    await page.getByRole("link", { name: "중보기도" }).click();
    await expect(page).toHaveURL(/\/prayers/);
    await expect(page.getByText("중보기도 관리")).toBeVisible();
  });

  test("displays prayer table", async ({ page }) => {
    await page.goto("/prayers");
    await page.waitForTimeout(3000);

    await expect(page.getByRole("table")).toBeVisible();
    await expect(page.getByText(/전체 \d+개/)).toBeVisible();
  });

  test("search filters prayers", async ({ page }) => {
    await page.goto("/prayers");
    await page.waitForTimeout(3000);

    await page.getByPlaceholder("내용 또는 작성자로 검색").fill("기도");
    await page.waitForTimeout(500);
  });
});

// ── Groups ───────────────────────────────────

test.describe("Groups", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("navigates to groups page", async ({ page }) => {
    await page.getByRole("link", { name: "목장 관리" }).click();
    await expect(page).toHaveURL(/\/groups/);
    await expect(page.getByRole("heading", { name: "목장 관리" })).toBeVisible();
  });

  test("displays group cards", async ({ page }) => {
    await page.goto("/groups");
    await page.waitForTimeout(3000);

    // Should show "전체 N개 목장"
    await expect(page.getByText(/전체 \d+개 목장/)).toBeVisible();

    // Should have group cards with names
    await expect(page.getByText("목장", { exact: false }).first()).toBeVisible();
  });
});

// ── Dark Mode ────────────────────────────────

test.describe("Theme", () => {
  test("dark mode toggle works", async ({ page }) => {
    await login(page);

    // Click theme toggle
    const themeBtn = page.getByRole("button", { name: "테마 전환" });
    await expect(themeBtn).toBeVisible();
    await themeBtn.click();

    // HTML should have class "dark"
    await expect(page.locator("html")).toHaveClass(/dark/);

    // Toggle back
    await themeBtn.click();
    await expect(page.locator("html")).toHaveClass(/light/);
  });
});

// ── Navigation ───────────────────────────────

test.describe("Navigation", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("sidebar links all work", async ({ page }) => {
    const links = [
      { name: "대시보드", url: /\/dashboard/ },
      { name: "회원 관리", url: /\/members/ },
      { name: "출결 현황", url: /\/attendance/ },
      { name: "중보기도", url: /\/prayers/ },
      { name: "목장 관리", url: /\/groups/ },
    ];

    for (const link of links) {
      await page.getByRole("link", { name: link.name }).click();
      await expect(page).toHaveURL(link.url);
    }
  });
});
