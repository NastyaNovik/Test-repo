#!/bin/bash
set -euo pipefail

SLACK_API_URL="https://slack.com/api"

pr_number=$(jq -r .pull_request.number "$GITHUB_EVENT_PATH")
pr_url=$(jq -r .pull_request.html_url "$GITHUB_EVENT_PATH")
repo=$(jq -r .repository.full_name "$GITHUB_EVENT_PATH")

echo "Creating Slack thread for PR #$pr_number"

response=$(curl -s -X POST "$SLACK_API_URL/chat.postMessage" \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{
    \"channel\": \"$SLACK_CHANNEL_ID\",
    \"text\": \"New PR <$pr_url> needs review\"
  }")

thread_ts=$(echo "$response" | jq -r '.ts')

if [[ -z "$thread_ts" || "$thread_ts" == "null" ]]; then
  echo "Failed to create Slack message"
  echo "$response"
  exit 1
fi

created_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

comment_body=$(cat <<EOF
SLACK_THREAD_TS: [$thread_ts]
created_at=$created_at
Slack conversation link: https://slack.com/archives/$SLACK_CHANNEL_ID/p${thread_ts//./}
EOF
)

curl -s -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/$repo/issues/$pr_number/comments \
  -d "$(jq -nc --arg body "$comment_body" '{body:$body}')"

echo "Slack thread created: ts=$thread_ts"
