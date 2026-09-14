#!/usr/bin/env bash
# Test 04: NAT Gateway state, public-subnet placement and Elastic IP.
get_vpc
get_subnets
NAT_JSON=$(aws_cli ec2 describe-nat-gateways --filter "Name=tag:Name,Values=$PREFIX-nat-gateway" --output json) || exit 1

if jq -e --arg subnet_id "$PUBLIC_SUBNET_ID" '.NatGateways[0] | .State == "available" and .SubnetId == $subnet_id and (.NatGatewayAddresses | any(.AllocationId != null and .PublicIp != null))' <<<"$NAT_JSON" >/dev/null; then
  pass 'Test 04 NAT Gateway is available in the public subnet with an Elastic IP'
else
  fail 'Test 04 NAT Gateway placement, state or Elastic IP is incorrect'
fi
