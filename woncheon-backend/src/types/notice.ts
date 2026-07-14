export type NoticeStatus = 'draft' | 'published';

export type NoticeNotificationStatus =
  | 'pending'
  | 'sending'
  | 'sent'
  | 'partial_fail'
  | 'failed'
  | 'disabled';

export interface NoticeRecord {
  PK?: string;
  SK?: string;
  GSI2PK?: string;
  GSI2SK?: string;
  noticeId: string;
  title: string;
  content: string;
  status: NoticeStatus;
  pinned: boolean;
  createdAt: string;
  updatedAt: string;
  publishedAt?: string;
  notifiedAt?: string;
  notificationStatus?: NoticeNotificationStatus;
  notificationRecipientCount?: number;
  notificationSuccessCount?: number;
  notificationFailureCount?: number;
}

export interface NoticeListItem {
  noticeId: string;
  title: string;
  contentPreview: string;
  pinned: boolean;
  publishedAt: string;
}

export interface NoticeDetail {
  noticeId: string;
  title: string;
  content: string;
  pinned: boolean;
  publishedAt: string;
}

export function makeNoticePreview(content: string): string {
  const trimmed = content.trim();
  return trimmed.length > 120 ? `${trimmed.substring(0, 120)}...` : trimmed;
}

export function toNoticeListItem(item: NoticeRecord): NoticeListItem {
  return {
    noticeId: item.noticeId,
    title: item.title,
    contentPreview: makeNoticePreview(item.content),
    pinned: item.pinned,
    publishedAt: item.publishedAt ?? item.createdAt,
  };
}

export function toNoticeDetail(item: NoticeRecord): NoticeDetail {
  return {
    noticeId: item.noticeId,
    title: item.title,
    content: item.content,
    pinned: item.pinned,
    publishedAt: item.publishedAt ?? item.createdAt,
  };
}

export function shouldSendNoticeNotification(
  previous: Pick<NoticeRecord, 'status' | 'notifiedAt'> | undefined,
  next: Pick<NoticeRecord, 'status' | 'notifiedAt'>,
): boolean {
  if (next.status !== 'published') return false;
  if (next.notifiedAt) return false;
  return previous?.status !== 'published';
}
