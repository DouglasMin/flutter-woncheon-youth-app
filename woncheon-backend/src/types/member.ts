export interface BlockedMember {
  memberId: string;
  memberName: string;
}

export interface Member {
  PK: string;
  SK: string;
  GSI1PK: string;
  GSI1SK: string;
  memberId: string;
  name: string;
  passwordHash: string;
  isFirstLogin: boolean;
  birthDate: string;
  gender: string;
  createdAt: string;
  updatedAt: string;
  /** UGC 차단 목록 (App Store Guideline 1.2). 없으면 빈 배열로 취급. */
  blockedMembers?: BlockedMember[];
}
