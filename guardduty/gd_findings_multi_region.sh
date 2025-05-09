#!/usr/bin/env bash
set -euo pipefail

# === 期間（JST → UTC）===
START_EPOCH=$(date -d '2025-05-01 00:00 UTC' +%s)   # 09:00 JST
END_EPOCH=$(date   -d '2025-05-01 12:00 UTC' +%s)   # 21:00 JST
START_MS=$((START_EPOCH * 1000))   # GuardDuty はミリ秒
END_MS=$((END_EPOCH   * 1000))

# === 各リージョンを横断 ===
for REGION in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
  DETECTOR_ID=$(aws guardduty list-detectors --region "$REGION" \
                 --query 'DetectorIds[0]' --output text)
  [[ "$DETECTOR_ID" == "None" ]] && continue   # GuardDuty 無効リージョン

  echo "$REGION (Detector: $DETECTOR_ID)"

  # --- ① 期間で Finding ID を抽出 ---
  CRITERIA=$(jq -n \
      --argjson gte "$START_MS" \
      --argjson lt  "$END_MS"  \
      '{Criterion: {updatedAt: {Gte: $gte, Lt: $lt}}}')

  FINDING_IDS_JSON=$(aws guardduty list-findings \
  --region "$REGION" --detector-id "$DETECTOR_ID" \
  --finding-criteria "$CRITERIA" --output json)

  COUNT=$(jq 'length' <<< "$FINDING_IDS_JSON")
  echo "  ▶ $COUNT findings"

  [ "$COUNT" -eq 0 ] && continue   # 0 件なら次のリージョンへ

  FINDING_IDS=$(jq -r '.[]' <<< "$FINDING_IDS_JSON" | xargs)

  aws guardduty get-findings \
  --region "$REGION" --detector-id "$DETECTOR_ID" \
  --finding-ids $FINDING_IDS \
  | jq . > "gd_results/findings_${REGION}.json"
  echo "Saved: gd_results/findings_${REGION}.json"

  echo "Saved: gd_results/findings_${REGION}.json"
done