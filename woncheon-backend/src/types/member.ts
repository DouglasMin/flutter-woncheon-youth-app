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
}
