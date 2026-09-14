#!/usr/bin/env bash
# Test 02: VPC DNS support and DNS hostnames.
get_vpc
DNS_SUPPORT=$(aws_cli ec2 describe-vpc-attribute --vpc-id "$VPC_ID" --attribute enableDnsSupport --output json) || exit 1
DNS_HOSTNAMES=$(aws_cli ec2 describe-vpc-attribute --vpc-id "$VPC_ID" --attribute enableDnsHostnames --output json) || exit 1

if jq -e '.EnableDnsSupport.Value == true' <<<"$DNS_SUPPORT" >/dev/null \
  && jq -e '.EnableDnsHostnames.Value == true' <<<"$DNS_HOSTNAMES" >/dev/null; then
  pass 'Test 02 VPC DNS support and DNS hostnames are enabled'
else
  fail 'Test 02 VPC DNS support or DNS hostnames are disabled'
fi
