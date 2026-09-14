#!/usr/bin/env bash
# Test 06: SSH ingress rules for public and private security groups.
get_vpc
get_security_groups

if jq -e --arg group_id "$PUBLIC_SG_ID" --arg cidr "$ALLOWED_SSH_CIDR" '.SecurityGroups[] | select(.GroupId == $group_id) | ([.IpPermissions[] | select(.IpProtocol == "tcp" and .FromPort == 22 and .ToPort == 22) | .IpRanges[].CidrIp] | sort) == [$cidr]' <<<"$SECURITY_GROUPS_JSON" >/dev/null \
  && jq -e --arg group_id "$PRIVATE_SG_ID" --arg public_sg_id "$PUBLIC_SG_ID" '.SecurityGroups[] | select(.GroupId == $group_id) | ([.IpPermissions[] | select(.IpProtocol == "tcp" and .FromPort == 22 and .ToPort == 22) | .UserIdGroupPairs[].GroupId] | unique) == [$public_sg_id] and ([.IpPermissions[] | select(.IpProtocol == "tcp" and .FromPort == 22 and .ToPort == 22) | .IpRanges[].CidrIp] | length) == 0' <<<"$SECURITY_GROUPS_JSON" >/dev/null; then
  pass 'Test 06 Public and private Security Group SSH rules are correct'
else
  fail 'Test 06 public or private Security Group SSH rule is incorrect'
fi
