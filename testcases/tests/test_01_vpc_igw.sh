#!/usr/bin/env bash
# Test 01: VPC availability and Internet Gateway attachment.
get_vpc
IGW_JSON=$(aws_cli ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --output json) || exit 1
IGW_ID=$(require_one_id "$IGW_JSON" '.InternetGateways | map(.InternetGatewayId)' 'Internet Gateway')

if jq -e '.Vpcs[0].State == "available"' <<<"$VPC_JSON" >/dev/null \
  && jq -e --arg vpc_id "$VPC_ID" '.InternetGateways[0].Attachments | any(.VpcId == $vpc_id and .State == "available")' <<<"$IGW_JSON" >/dev/null; then
  pass 'Test 01 VPC is available and Internet Gateway is attached'
else
  fail 'Test 01 VPC availability or Internet Gateway attachment is incorrect'
fi
