export interface PrayerRequest {
  PK: string;
  SK: string;
  GSI2PK: string;
  GSI2SK: string;
  prayerId: string;
  memberId: string;
  authorName: string;
  isAnonymous: boolean;
  content: string;
  createdAt: string;
}
