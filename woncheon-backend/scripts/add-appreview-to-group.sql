-- appreview를 조성주 목장에 추가
-- MemberId: 01KQ7DJPQQ9R2TSSQWPPK0CF8K

-- 1. 조성주 목장 ID 찾기
SELECT g.id, g.name, g.leader_member_id, m.member_name
FROM groups g
JOIN group_members m ON g.id = m.group_id AND g.leader_member_id = m.member_id
WHERE m.member_name = '조성주';

-- 2. appreview를 조성주 목장에 추가 (위에서 나온 group_id 사용)
-- 예: group_id가 5라면
INSERT INTO group_members (group_id, member_id, member_name, note)
VALUES (5, '01KQ7DJPQQ9R2TSSQWPPK0CF8K', 'appreview', 'App Store 심사용 테스트 계정')
ON CONFLICT (group_id, member_id) DO NOTHING;

-- 3. 확인
SELECT * FROM group_members WHERE member_id = '01KQ7DJPQQ9R2TSSQWPPK0CF8K';
