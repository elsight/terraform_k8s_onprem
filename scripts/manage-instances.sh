#!/usr/bin/env bash
set -euo pipefail

# Use dev AWS profile (override with: AWS_PROFILE=other ./scripts/manage-instances.sh)
export AWS_PROFILE="${AWS_PROFILE:-dev}"

S3_BUCKET="930579047961-tfstate"
S3_REGION="us-east-1"
STATE_FILE="/tmp/ec2-terraform-state-$$.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

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
rm -f "${STATE_FILE}"

echo ""
if [ -z "${NAMES}" ]; then
  echo "No running EC2 instances in state."
  echo ""
  read -rp "Enter new instance name to add (or Enter to quit): " NEW_NAME
  if [ -n "${NEW_NAME}" ]; then
    cd "${PROJECT_ROOT}"
    JSON_NAMES="[\"${NEW_NAME}\"]"
    terraform apply -auto-approve -var="instance_names=${JSON_NAMES}"
    if command -v jq &>/dev/null; then
      outputs=$(terraform output -json 2>/dev/null || true)
      if [ -n "${outputs}" ]; then
        {
          echo "| Instance | Instance ID | Private IP | Public IP |"
          echo "|----------|-------------|------------|-----------|"
          jq -r '
            . as $root |
            .instance_ids.value | keys[] |
            . as $n |
            "| \($n) | \($root.instance_ids.value[$n]) | \($root.instance_private_ips.value[$n] // "-") | \($root.instance_public_ips.value[$n] // "-") |"
          ' <<< "${outputs}"
        } > "${PROJECT_ROOT}/ip.md"
        echo "Updated ip.md"
      fi
    fi
  fi
  exit 0
fi

update_ip_md() {
  local outputs
  outputs=$(terraform output -json 2>/dev/null || true)
  if [ -n "${outputs}" ]; then
    {
      echo "| Instance | Instance ID | Private IP | Public IP |"
      echo "|----------|-------------|------------|-----------|"
      jq -r '
        . as $root |
        .instance_ids.value | keys[] |
        . as $n |
        "| \($n) | \($root.instance_ids.value[$n]) | \($root.instance_private_ips.value[$n] // "-") | \($root.instance_public_ips.value[$n] // "-") |"
      ' <<< "${outputs}"
    } > "${PROJECT_ROOT}/ip.md"
    echo "Updated ip.md"
  fi
}

echo "Running EC2 instances:"
echo "${NAMES}" | nl -w2 -s'. '
echo ""
echo "Actions: enter instance number to REMOVE, or new name to ADD"
echo ""
read -rp "Enter instance number to remove, or new name to add (or Enter to quit): " INPUT

if [ -z "${INPUT}" ]; then
  exit 0
fi

cd "${PROJECT_ROOT}"

if [[ "${INPUT}" =~ ^[0-9]+$ ]]; then
  REMOVE_NAME=$(echo "${NAMES}" | sed -n "${INPUT}p")
  if [ -z "${REMOVE_NAME}" ]; then
    echo "Invalid number."
    exit 1
  fi
  REMAINING=$(echo "${NAMES}" | grep -v "^${REMOVE_NAME}$" | grep -v '^$' || true)
  if [ -z "${REMAINING}" ]; then
    JSON_NAMES="[]"
  else
    JSON_NAMES=$(echo "${REMAINING}" | sed 's/^/"/;s/$/"/' | paste -sd ',' | sed 's/^/[/;s/$/]/')
  fi
  echo "Destroying ${REMOVE_NAME}..."
  terraform apply -auto-approve -var="instance_names=${JSON_NAMES}"
  update_ip_md
else
  NEW_NAMES=$(echo -e "${NAMES}\n${INPUT}" | grep -v '^$')
  JSON_NAMES=$(echo "${NEW_NAMES}" | sed 's/^/"/;s/$/"/' | paste -sd ',' | sed 's/^/[/;s/$/]/')
  echo "Adding ${INPUT}..."
  terraform apply -auto-approve -var="instance_names=${JSON_NAMES}"
  update_ip_md
fi
