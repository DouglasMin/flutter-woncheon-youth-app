-- 출결 관리 스키마 (PostgreSQL)
-- RDS Free Tier: db.t4g.micro, 20GB gp2, Single-AZ

-- updated_at 자동 갱신 트리거 함수
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

-- 목장 (Group)
CREATE TABLE IF NOT EXISTS groups (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  leader_member_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER trg_groups_updated_at
  BEFORE UPDATE ON groups
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 목장 멤버 (Group Member)
CREATE TABLE IF NOT EXISTS group_members (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  group_id BIGINT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  member_id TEXT NOT NULL,
  member_name TEXT NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, member_id)
);

-- 출결 기록 (Attendance)
CREATE TABLE IF NOT EXISTS attendance (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  group_id BIGINT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  member_id TEXT NOT NULL,
  attendance_date DATE NOT NULL,
  is_present BOOLEAN NOT NULL DEFAULT FALSE,
  checked_by TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, member_id, attendance_date),
  CONSTRAINT attendance_date_must_be_sunday
    CHECK (EXTRACT(DOW FROM attendance_date) = 0),
  CONSTRAINT fk_attendance_group_member
    FOREIGN KEY (group_id, member_id)
    REFERENCES group_members(group_id, member_id)
    ON DELETE CASCADE
);

CREATE TRIGGER trg_attendance_updated_at
  BEFORE UPDATE ON attendance
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 인덱스
CREATE INDEX idx_attendance_group_date ON attendance(group_id, attendance_date);
CREATE INDEX idx_attendance_member_date ON attendance(member_id, attendance_date);
CREATE INDEX idx_attendance_date ON attendance(attendance_date);
CREATE INDEX idx_group_members_group ON group_members(group_id);
CREATE INDEX idx_group_members_member ON group_members(member_id);
CREATE INDEX idx_groups_leader ON groups(leader_member_id);
