#!/bin/bash

# 모든 endpoint에 테스트 푸시 발송

PLATFORM_ARN="arn:aws:sns:ap-northeast-2:863518440691:app/APNS/woncheon-ios"
PROFILE="dongik2"
REGION="ap-northeast-2"

# 모든 endpoint ARN 가져오기
ENDPOINTS=$(aws sns list-endpoints-by-platform-application \
  --platform-application-arn "$PLATFORM_ARN" \
  --region "$REGION" \
  --profile "$PROFILE" \
  --query 'Endpoints[*].EndpointArn' \
  --output text)

if [ -z "$ENDPOINTS" ]; then
  echo "❌ 등록된 endpoint가 없습니다."
  exit 1
fi

COUNT=0
for ENDPOINT in $ENDPOINTS; do
  echo "📤 발송 중: $ENDPOINT"
  
  aws sns publish \
    --target-arn "$ENDPOINT" \
    --message '{"default":"테스트","APNS":"{\"aps\":{\"alert\":{\"title\":\"원천청년부\",\"body\":\"테스트 푸시입니다 🙏\"},\"sound\":\"default\"},\"data\":{\"screen\":\"prayer_list\"}}"}' \
    --message-structure json \
    --region "$REGION" \
    --profile "$PROFILE" > /dev/null
  
  COUNT=$((COUNT + 1))
done

echo "✅ 총 ${COUNT}개 endpoint에 발송 완료"
