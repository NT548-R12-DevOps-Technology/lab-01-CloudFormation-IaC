#!/usr/bin/env bash
# Test 03: Public/private subnet existence and public IPv4 assignment settings.
get_vpc
get_subnets

if [[ -n "$PUBLIC_SUBNET_ID" && -n "$PRIVATE_SUBNET_ID" ]] \
  && jq -e --arg id "$PUBLIC_SUBNET_ID" '.Subnets[] | select(.SubnetId == $id) | .MapPublicIpOnLaunch == true' <<<"$SUBNETS_JSON" >/dev/null \
  && jq -e --arg id "$PRIVATE_SUBNET_ID" '.Subnets[] | select(.SubnetId == $id) | .MapPublicIpOnLaunch == false' <<<"$SUBNETS_JSON" >/dev/null; then
  pass 'Test 03 Public and private subnets have the expected public-IP settings'
else
  fail 'Test 03 subnet names or public-IP settings are incorrect'
fi
