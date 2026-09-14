#!/usr/bin/env bash
# Run all AWS CLI test groups for the lab infrastructure.
set -uo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ENV_FILE="$SCRIPT_DIR/.env"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

REGION="${LAB_AWS_REGION:-}"
PROJECT_NAME="${LAB_PROJECT_NAME:-}"
ENVIRONMENT="${LAB_ENVIRONMENT:-}"
ALLOWED_SSH_CIDR="${LAB_ALLOWED_SSH_CIDR:-}"
PASS_COUNT=0
FAIL_COUNT=0

usage() {
  cat <<'USAGE'
Usage:
  cp testcases/.env.example testcases/.env
  # Edit testcases/.env, then run:
  bash testcases/validate_aws_cli.sh

Optional CLI overrides:
  bash testcases/validate_aws_cli.sh \
    --region <aws-region> \
    --project-name <project-name> \
    --environment <environment> \
    --allowed-ssh-cidr <trusted-ip-cidr>
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region) REGION="$2"; shift 2 ;;
    --project-name) PROJECT_NAME="$2"; shift 2 ;;
    --environment) ENVIRONMENT="$2"; shift 2 ;;
    --allowed-ssh-cidr) ALLOWED_SSH_CIDR="$2"; shift 2 ;;
    -h | --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$REGION" || -z "$PROJECT_NAME" || -z "$ENVIRONMENT" || -z "$ALLOWED_SSH_CIDR" ]]; then
  echo "--region, --project-name, --environment and --allowed-ssh-cidr are required." >&2
  usage >&2
  exit 2
fi

for command in aws jq; do
  command -v "$command" >/dev/null 2>&1 || { echo "Required command not found: $command" >&2; exit 2; }
done

# Source helpers and test groups into one process so pass/fail totals accumulate.
source "$SCRIPT_DIR/lib/common.sh"
echo "Validating AWS infrastructure in $REGION for Project=$PROJECT_NAME, Environment=$ENVIRONMENT"
source "$SCRIPT_DIR/tests/test_01_vpc_igw.sh"
source "$SCRIPT_DIR/tests/test_02_vpc_dns.sh"
source "$SCRIPT_DIR/tests/test_03_subnets.sh"
source "$SCRIPT_DIR/tests/test_04_nat_gateway.sh"
source "$SCRIPT_DIR/tests/test_05_route_tables.sh"
source "$SCRIPT_DIR/tests/test_06_security_groups.sh"
source "$SCRIPT_DIR/tests/test_07_ec2.sh"

echo
echo "Result: $PASS_COUNT passed, $FAIL_COUNT failed"
[[ $FAIL_COUNT -eq 0 ]]
