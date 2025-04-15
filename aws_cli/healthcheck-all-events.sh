#!/bin/bash

event_arns=$(aws health describe-events \
  --region us-east-1 \
  --filter '{"services": ["EC2"], "eventTypeCategories": ["issue"], "eventStatusCodes": ["open", "closed"]}' \
  --query "events[*].arn" \
  --output text)

for arn in $event_arns; do
  echo "=== Event ARN: $arn ==="
  aws health describe-affected-entities \
    --region us-east-1 \
    --filter "{\"eventArns\": [\"$arn\"]}" \
    --query "entities[*].[entityValue, statusCode]" \
    --output table
  echo
done
