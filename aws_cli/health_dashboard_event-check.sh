#!/bin/bash

# EC2 の障害（issue）でステータス open のイベントを取得
event_arns=$(aws health describe-events \
  --region us-east-1 \
  --filter '{"services": ["EC2"], "eventTypeCategories": ["issue"], "eventStatusCodes": ["closed"]}' \
  --query "events[*].arn" \
  --output text)

# 各イベントの影響を受けているインスタンス（IMPAIRED のみ）を表示
for arn in $event_arns; do
  echo "=== Event ARN: $arn ==="
  aws health describe-affected-entities \
    --region us-east-1 \
    --filter "{\"eventArns\": [\"$arn\"]}" \
    --query "entities[?statusCode=='IMPAIRED'].[entityValue, statusCode]" \
    --output table
  echo
done

