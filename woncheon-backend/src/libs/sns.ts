import {
  SNSClient,
  PublishCommand,
  CreatePlatformEndpointCommand,
} from '@aws-sdk/client-sns';

const snsClient = new SNSClient({ region: 'ap-northeast-2' });

export async function createEndpoint(
  platformArn: string,
  deviceToken: string,
): Promise<string> {
  const result = await snsClient.send(
    new CreatePlatformEndpointCommand({
      PlatformApplicationArn: platformArn,
      Token: deviceToken,
    }),
  );
  if (!result.EndpointArn) {
    throw new Error('SNS createPlatformEndpoint returned no EndpointArn');
  }
  return result.EndpointArn;
}

export async function publishToEndpoint(
  endpointArn: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<void> {
  const message = {
    default: body,
    // FCM (Android): priority=high + android_channel_id로 popup(heads-up) 트리거.
    // SNS legacy GCM 페이로드는 자동으로 FCM v1의 `android.priority` /
    // `android.notification.channel_id`로 매핑됨.
    // (AWS docs: https://docs.aws.amazon.com/sns/latest/dg/sns-fcm-v1-payloads.html)
    GCM: JSON.stringify({
      priority: 'high',
      notification: {
        title,
        body,
        android_channel_id: 'prayer_high',
      },
      data: data ?? {},
    }),
    APNS: JSON.stringify({
      aps: { alert: { title, body }, sound: 'default' },
      ...data,
    }),
    APNS_SANDBOX: JSON.stringify({
      aps: { alert: { title, body }, sound: 'default' },
      ...data,
    }),
  };

  await snsClient.send(
    new PublishCommand({
      TargetArn: endpointArn,
      Message: JSON.stringify(message),
      MessageStructure: 'json',
    }),
  );
}
