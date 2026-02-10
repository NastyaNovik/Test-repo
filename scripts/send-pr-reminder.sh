#!/bin/bash
set -euo pipefail

PRS_JSON="$1"
REPO="$2"
SLACK_BOT_TOKEN="$3"
SLACK_CHANNEL_ID="$4"
GITHUB_TOKEN="$5"

SLACK_API_URL="https://slack.com/api"

echo "$PRS_JSON" | jq -c '.[]' | while read -r pr; do
  pr_number=$(echo "$pr" | jq -r '.number')
  pr_url=$(echo "$pr" | jq -r '.url')

  approved_count=$(echo "$pr" | jq '[.reviews[] | select(.state=="APPROVED")] | length')
  if [[ $approved_count -ge 2 ]]; then
    continue
  fi

  comments=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO/issues/$pr_number/comments" \
    | jq -r '.[] | select((.body | split("\n")[0]) | startswith("SLACK_THREAD_TS:")) | .body' || true)

  thread_ts=$(echo "$comments" | tail -n 1 | grep -oP '\[\K[^\]]+' || true)  
  thread_ts=$(echo "$thread_ts" | tr -d '[:space:]')

  echo "Comments found for PR #$pr_number:"
  echo "$comments"
  echo "$thread_ts"

  if [[ -z "$thread_ts" ]]; then
    echo "No Slack thread for PR #$pr_number"
    continue
  fi

  echo "Validating Slack thread $thread_ts"

  check=$(curl -s -G "$SLACK_API_URL/conversations.replies" \
    -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    --data-urlencode "channel=$SLACK_CHANNEL_ID" \
    --data-urlencode "ts=$thread_ts" \
    --data-urlencode "limit=1")

  if [[ "$(echo "$check" | jq -r '.ok')" != "true" ]]; then
    echo "Thread $thread_ts does not exist, skipping"
    continue
  fi

  curl -s -X POST "$SLACK_API_URL/chat.postMessage" \
    -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{
      \"channel\": \"$SLACK_CHANNEL_ID\",
      \"thread_ts\": \"$thread_ts\",
      \"text\": \"Reminder: <$pr_url> still needs review 👀\"
    }" > /dev/null

  echo "Reminder sent for PR #$pr_number"
done
