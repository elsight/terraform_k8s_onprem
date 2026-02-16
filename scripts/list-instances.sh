#!/usr/bin/env bash
set -euo pipefail

# Use dev AWS profile (override with: AWS_PROFILE=other ./scripts/list-instances.sh)
export AWS_PROFILE="${AWS_PROFILE:-dev}"

S3_BUCKET="930579047961-tfstate"
S3_REGION="us-east-1"
STATE_FILE="/tmp/ec2-terraform-state-$$.json"
STATE_KEY="services/dev/ec2.tfstate"

echo "Pulling state from s3://${S3_BUCKET}/${STATE_KEY}..."
if ! aws s3 cp "s3://${S3_BUCKET}/${STATE_KEY}" "${STATE_FILE}" --region "${S3_REGION}"; then
  echo "Failed to fetch state. Common causes:"
  echo "  - State file does not exist yet (run terraform apply first)"
  echo "  - AWS credentials not configured (aws configure)"
  echo "  - Bucket or key path does not exist"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "jq is required. Install with: apt install jq"
  rm -f "${STATE_FILE}"
  exit 1
fi

NAMES=$(jq -r '.outputs.instance_ids.value | keys[]?' "${STATE_FILE}" 2>/dev/null || true)

if [ -z "${NAMES}" ]; then
  echo "No running EC2 instances found in state."
  rm -f "${STATE_FILE}"
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
KEY_PATH="${PROJECT_ROOT}/ec2-key.pem"

echo ""
echo "All EC2 instances (from remote state s3://${S3_BUCKET}/${STATE_KEY}):"
echo ""
echo "| Instance | Instance ID | Private IP | Public IP |"
echo "|----------|-------------|------------|-----------|"
jq -r '
  . as $root |
  .outputs.instance_ids.value | keys[] |
  . as $n |
  "| \($n) | \($root.outputs.instance_ids.value[$n]) | \($root.outputs.instance_private_ips.value[$n] // "-") | \($root.outputs.instance_public_ips.value[$n] // "-") |"
' "${STATE_FILE}"
echo ""
if [ -f "${KEY_PATH}" ]; then
  echo "SSH key: ${KEY_PATH}"
  echo "Example: ssh -i ${KEY_PATH} ubuntu@<public_ip>"
  echo ""
fi

rm -f "${STATE_FILE}"
