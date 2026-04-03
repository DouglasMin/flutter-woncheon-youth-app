-- 출결 관리 스키마 (PostgreSQL)
-- RDS Free Tier: db.t3.micro, 20GB gp2, Single-AZ

-- 목장 (Group)
CREATE TABLE IF NOT EXISTS groups (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL,            -- 목장 이름 (목자 이름)
  leader_member_id VARCHAR(30) NOT NULL, -- DynamoDB Member의 memberId
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 목장 멤버 (Group Member)
CREATE TABLE IF NOT EXISTS group_members (
  id SERIAL PRIMARY KEY,
  group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  member_id VARCHAR(30) NOT NULL,       -- DynamoDB Member의 memberId
  member_name VARCHAR(50) NOT NULL,
  note VARCHAR(200),                    -- 비고 (예: "남편과 같이 출석 중")
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, member_id)
);

-- 출결 기록 (Attendance)
CREATE TABLE IF NOT EXISTS attendance (
  id SERIAL PRIMARY KEY,
  group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  member_id VARCHAR(30) NOT NULL,
  attendance_date DATE NOT NULL,         -- 예배 날짜 (매주 일요일)
  is_present BOOLEAN NOT NULL DEFAULT FALSE,
  checked_by VARCHAR(30) NOT NULL,       -- 체크한 목자의 memberId
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(member_id, attendance_date)
);

-- 인덱스
CREATE INDEX idx_attendance_group_date ON attendance(group_id, attendance_date);
CREATE INDEX idx_attendance_member_date ON attendance(member_id, attendance_date);
CREATE INDEX idx_attendance_date ON attendance(attendance_date);
CREATE INDEX idx_group_members_group ON group_members(group_id);
CREATE INDEX idx_group_members_member ON group_members(member_id);
CREATE INDEX idx_groups_leader ON groups(leader_member_id);

-- 유용한 뷰: 목장별 주간 출석률
CREATE OR REPLACE VIEW v_group_weekly_rate AS
SELECT
  g.id AS group_id,
  g.name AS group_name,
  a.attendance_date,
  COUNT(CASE WHEN a.is_present THEN 1 END) AS present_count,
  COUNT(*) AS total_count,
  ROUND(
    COUNT(CASE WHEN a.is_present THEN 1 END)::NUMERIC / NULLIF(COUNT(*), 0) * 100, 1
  ) AS rate_percent
FROM groups g
JOIN group_members gm ON g.id = gm.group_id
LEFT JOIN attendance a ON gm.member_id = a.member_id
GROUP BY g.id, g.name, a.attendance_date;

-- 유용한 뷰: 개인별 월간 출석률
CREATE OR REPLACE VIEW v_member_monthly_rate AS
SELECT
  gm.member_id,
  gm.member_name,
  g.name AS group_name,
  DATE_TRUNC('month', a.attendance_date) AS month,
  COUNT(CASE WHEN a.is_present THEN 1 END) AS present_count,
  COUNT(*) AS total_count,
  ROUND(
    COUNT(CASE WHEN a.is_present THEN 1 END)::NUMERIC / NULLIF(COUNT(*), 0) * 100, 1
  ) AS rate_percent
FROM group_members gm
JOIN groups g ON gm.group_id = g.id
LEFT JOIN attendance a ON gm.member_id = a.member_id
GROUP BY gm.member_id, gm.member_name, g.name, DATE_TRUNC('month', a.attendance_date);
