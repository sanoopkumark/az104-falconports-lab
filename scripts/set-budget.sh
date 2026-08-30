#!/usr/bin/env bash
# Sets a subscription-level monthly budget with 50/80/100% email alerts.
# Run this BEFORE deploying anything else in the lab.
#
# Usage: EMAIL=you@example.com AMOUNT=25 bash scripts/set-budget.sh

set -euo pipefail

EMAIL="${EMAIL:?Set EMAIL=you@example.com before running this script}"
AMOUNT="${AMOUNT:-25}"
START_DATE="$(date -u +%Y-%m-01)"

az consumption budget create \
  --budget-name "falconports-monthly-cap" \
  --amount "${AMOUNT}" \
  --category cost \
  --time-grain monthly \
  --start-date "${START_DATE}" \
  --end-date "2027-12-31" \
  --notifications "{
    \"Actual_50\": {\"enabled\": true, \"operator\": \"GreaterThan\", \"threshold\": 50, \"contactEmails\": [\"${EMAIL}\"]},
    \"Actual_80\": {\"enabled\": true, \"operator\": \"GreaterThan\", \"threshold\": 80, \"contactEmails\": [\"${EMAIL}\"]},
    \"Actual_100\": {\"enabled\": true, \"operator\": \"GreaterThan\", \"threshold\": 100, \"contactEmails\": [\"${EMAIL}\"]}
  }"

echo "Budget 'falconports-monthly-cap' set to \$${AMOUNT}/month with alerts at 50/80/100% to ${EMAIL}."
