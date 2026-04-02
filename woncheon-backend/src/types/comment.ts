export interface Comment {
  PK: string;
  SK: string;
  commentId: string;
  prayerId: string;
  memberId: string;
  authorName: string;
  content: string;
  createdAt: string;
}

export interface Reaction {
  PK: string;
  SK: string;
  prayerId: string;
  memberId: string;
  createdAt: string;
}
