#!/bin/bash

echo "Instance ID,EC2 Status,System Status,Instance Status"

# すべてのインスタンスを取得
INSTANCE_IDS=$(aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text)

for ID in $INSTANCE_IDS; do
  # Nameタグ取得
  NAME=$(aws ec2 describe-instances \
    --instance-ids "$ID" \
    --query 'Reservations[*].Instances[*].Tags[?Key==`Name`].Value | [0][0]' \
    --output text 2>/dev/null)

  # システムステータス、インスタンスステータス取得
  STATUS=$(aws ec2 describe-instance-status \
    --instance-ids "$ID" \
    --include-all-instances \
    --query 'InstanceStatuses[0].{SystemStatus:SystemStatus.Status, InstanceStatus:InstanceStatus.Status}' \
    --output text 2>/dev/null)

  # インスタンスの起動状態（Running など）取得
  STATE=$(aws ec2 describe-instances \
    --instance-ids "$ID" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text 2>/dev/null)

  # 出力
  echo "$ID,$STATE,$(echo $STATUS | awk '{print $1","$2}')"
done
