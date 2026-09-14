#!/usr/bin/env bash
# Shared helpers for AWS CLI test groups. This file is sourced by the runner.
PREFIX="${PROJECT_NAME}-${ENVIRONMENT}"

aws_cli() { aws --region "$REGION" --no-cli-pager "$@"; }
pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS  %s\n' "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf 'FAIL  %s\n' "$1"; }

require_one_id() {
  local json="$1" jq_path="$2" resource_name="$3" ids
  ids=$(jq -r "$jq_path[]" <<<"$json")
  if [[ $(wc -w <<<"$ids") -ne 1 ]]; then
    echo "Expected exactly one $resource_name for Project=$PROJECT_NAME and Environment=$ENVIRONMENT; found: ${ids:-none}" >&2
    exit 1
  fi
  printf '%s\n' "$ids"
}

get_vpc() {
  VPC_JSON=$(aws_cli ec2 describe-vpcs --filters "Name=tag:Project,Values=$PROJECT_NAME" "Name=tag:Environment,Values=$ENVIRONMENT" --output json) || exit 1
  VPC_ID=$(require_one_id "$VPC_JSON" '.Vpcs | map(.VpcId)' 'VPC')
}

get_subnets() {
  SUBNETS_JSON=$(aws_cli ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$PREFIX-public-subnet,$PREFIX-private-subnet" --output json) || exit 1
  PUBLIC_SUBNET_ID=$(jq -r --arg name "$PREFIX-public-subnet" '.Subnets[] | select(.Tags | any(.Key == "Name" and .Value == $name)) | .SubnetId' <<<"$SUBNETS_JSON")
  PRIVATE_SUBNET_ID=$(jq -r --arg name "$PREFIX-private-subnet" '.Subnets[] | select(.Tags | any(.Key == "Name" and .Value == $name)) | .SubnetId' <<<"$SUBNETS_JSON")
}

get_security_groups() {
  SECURITY_GROUPS_JSON=$(aws_cli ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$PREFIX-public-sg,$PREFIX-private-sg" --output json) || exit 1
  PUBLIC_SG_ID=$(jq -r --arg name "$PREFIX-public-sg" '.SecurityGroups[] | select(.Tags | any(.Key == "Name" and .Value == $name)) | .GroupId' <<<"$SECURITY_GROUPS_JSON")
  PRIVATE_SG_ID=$(jq -r --arg name "$PREFIX-private-sg" '.SecurityGroups[] | select(.Tags | any(.Key == "Name" and .Value == $name)) | .GroupId' <<<"$SECURITY_GROUPS_JSON")
}
