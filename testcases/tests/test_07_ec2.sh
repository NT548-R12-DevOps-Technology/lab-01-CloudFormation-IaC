#!/usr/bin/env bash
# Test 07: Public/private EC2 subnet, address and security-group setup.
get_vpc
get_subnets
get_security_groups
INSTANCES_JSON=$(aws_cli ec2 describe-instances --filters "Name=tag:Name,Values=$PREFIX-public-ec2-*,$PREFIX-private-ec2-*" "Name=instance-state-name,Values=running" --output json) || exit 1

if jq -e --arg public_subnet_id "$PUBLIC_SUBNET_ID" --arg public_sg_id "$PUBLIC_SG_ID" --arg prefix "$PREFIX-public-ec2-" '[.Reservations[].Instances[] | select(.Tags | any(.Key == "Name" and (.Value | startswith($prefix))))] | length > 0 and all(.[]; .SubnetId == $public_subnet_id and .PublicIpAddress != null and (.SecurityGroups | any(.GroupId == $public_sg_id)))' <<<"$INSTANCES_JSON" >/dev/null \
  && jq -e --arg private_subnet_id "$PRIVATE_SUBNET_ID" --arg private_sg_id "$PRIVATE_SG_ID" --arg prefix "$PREFIX-private-ec2-" '[.Reservations[].Instances[] | select(.Tags | any(.Key == "Name" and (.Value | startswith($prefix))))] | length > 0 and all(.[]; .SubnetId == $private_subnet_id and .PublicIpAddress == null and (.SecurityGroups | any(.GroupId == $private_sg_id)))' <<<"$INSTANCES_JSON" >/dev/null; then
  pass 'Test 07 Public and private EC2 instances have the expected configuration'
else
  fail 'Test 07 public or private EC2 configuration is incorrect'
fi
