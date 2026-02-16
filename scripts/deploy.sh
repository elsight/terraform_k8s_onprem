#!/usr/bin/env bash
set -euo pipefail

# Use dev AWS profile (override with: AWS_PROFILE=other ./scripts/deploy.sh)
export AWS_PROFILE="${AWS_PROFILE:-dev}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
S3_BUCKET="930579047961-tfstate"
S3_REGION="us-east-1"
STATE_FILE="/tmp/ec2-terraform-state-$$.json"
STATE_KEY="services/dev/ec2.tfstate"

if aws s3 cp "s3://${S3_BUCKET}/${STATE_KEY}" "${STATE_FILE}" --region "${S3_REGION}" 2>/dev/null && command -v jq &>/dev/null; then
  EXISTING=$(jq -r '.outputs.instance_ids.value | keys[]?' "${STATE_FILE}" 2>/dev/null || true)
  rm -f "${STATE_FILE}"
  if [ -n "${EXISTING}" ]; then
    echo "Existing instances:"
    echo "${EXISTING}" | nl
    echo ""
  fi
fi

read -rp "Enter instance name(s), comma-separated: " INPUT
INSTANCE_NAMES=$(echo "${INPUT}" | tr ',' '\n' | tr -d ' ' | grep -v '^$')

if [ -z "${INSTANCE_NAMES}" ]; then
  echo "No instance names provided."
  exit 1
fi

JSON_NAMES=$(echo "${INSTANCE_NAMES}" | sed 's/^/"/;s/$/"/' | paste -sd ',' | sed 's/^/[/;s/$/]/')
echo ""
echo "Instance names: ${JSON_NAMES}"
echo ""

cd "${PROJECT_ROOT}"
terraform apply -auto-approve -var="instance_names=${JSON_NAMES}" "${@}"

if command -v jq &>/dev/null; then
  OUTPUTS=$(terraform output -json 2>/dev/null || true)
  if [ -n "${OUTPUTS}" ]; then
    {
      echo "| Instance | Instance ID | Private IP | Public IP |"
      echo "|----------|-------------|------------|-----------|"
      jq -r '
        . as $root |
        .instance_ids.value | keys[] |
        . as $n |
        "| \($n) | \($root.instance_ids.value[$n]) | \($root.instance_private_ips.value[$n] // "-") | \($root.instance_public_ips.value[$n] // "-") |"
      ' <<< "${OUTPUTS}"
    } > "${PROJECT_ROOT}/ip.md"
    echo "Updated ip.md"
  fi
fi
