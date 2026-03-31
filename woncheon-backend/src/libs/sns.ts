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
    GCM: JSON.stringify({
      notification: { title, body },
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
