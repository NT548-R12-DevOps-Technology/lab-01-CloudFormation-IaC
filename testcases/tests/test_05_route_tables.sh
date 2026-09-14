#!/usr/bin/env bash
# Test 05: Public/private route tables and subnet associations.
get_vpc
get_subnets
IGW_JSON=$(aws_cli ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --output json) || exit 1
IGW_ID=$(require_one_id "$IGW_JSON" '.InternetGateways | map(.InternetGatewayId)' 'Internet Gateway')
NAT_JSON=$(aws_cli ec2 describe-nat-gateways --filter "Name=tag:Name,Values=$PREFIX-nat-gateway" --output json) || exit 1
NAT_ID=$(require_one_id "$NAT_JSON" '.NatGateways | map(.NatGatewayId)' 'NAT Gateway')
ROUTE_TABLES_JSON=$(aws_cli ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$PREFIX-public-rt,$PREFIX-private-rt" --output json) || exit 1
PUBLIC_RT_ID=$(jq -r --arg name "$PREFIX-public-rt" '.RouteTables[] | select(.Tags | any(.Key == "Name" and .Value == $name)) | .RouteTableId' <<<"$ROUTE_TABLES_JSON")
PRIVATE_RT_ID=$(jq -r --arg name "$PREFIX-private-rt" '.RouteTables[] | select(.Tags | any(.Key == "Name" and .Value == $name)) | .RouteTableId' <<<"$ROUTE_TABLES_JSON")

if jq -e --arg rt_id "$PUBLIC_RT_ID" --arg subnet_id "$PUBLIC_SUBNET_ID" --arg igw_id "$IGW_ID" '.RouteTables[] | select(.RouteTableId == $rt_id) | ([.Routes[] | select(.DestinationCidrBlock == "0.0.0.0/0" and .GatewayId == $igw_id and .State == "active")] | length == 1) and ([.Associations[] | select(.SubnetId == $subnet_id)] | length == 1)' <<<"$ROUTE_TABLES_JSON" >/dev/null \
  && jq -e --arg rt_id "$PRIVATE_RT_ID" --arg subnet_id "$PRIVATE_SUBNET_ID" --arg nat_id "$NAT_ID" '.RouteTables[] | select(.RouteTableId == $rt_id) | ([.Routes[] | select(.DestinationCidrBlock == "0.0.0.0/0" and .NatGatewayId == $nat_id and .State == "active")] | length == 1) and ([.Associations[] | select(.SubnetId == $subnet_id)] | length == 1)' <<<"$ROUTE_TABLES_JSON" >/dev/null; then
  pass 'Test 05 Public and private route tables use the expected default routes'
else
  fail 'Test 05 route table, default route or subnet association is incorrect'
fi
