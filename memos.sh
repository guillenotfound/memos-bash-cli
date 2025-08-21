#!/bin/bash

# TODO: filter by current user
# TODO: move config to ~/.config/memos-cli-bash/config.toml
# TODO: add support to search by tag?

set -euo pipefail

help() {
  cat <<EOF
Usage: $0 {login|edit|new|help}

Commands:
  login          Log in to memos.
  edit [string]  Edit a memo (auto-select if one match).
  new            Create a new memo.
  help           Show this help message.
EOF
}

if [ $# -lt 1 ]; then
  help
  exit 1
fi

api_call() {
  local METHOD="${1:-GET}"
  local ENDPOINT="$2"
  local DATA="${3-}"

  if [[ "$METHOD" == "POST" || "$METHOD" == "PATCH" || "$METHOD" == "PUT" ]]; then
    STATUS_CODE=$(curl -s -X "$METHOD" -o /tmp/memo_update_response.json -w "%{http_code}" "${SERVER_URL}/api/v1/${ENDPOINT}" \
      -H "Accept: application/json" \
      -H "Authorization: Bearer ${API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$DATA")

    echo "$STATUS_CODE"
  else
    curl -s -X "$METHOD" "${SERVER_URL}/api/v1/${ENDPOINT}" \
      -H "Accept: application/json" \
      -H "Authorization: Bearer ${API_KEY}"
  fi
}

login() {
  read -rp "Please enter the server URL: " server_url
  read -rp "Please enter the API KEY: " api_key

  echo "SERVER_URL=\"${server_url}\"" >.env
  echo "API_KEY=\"${api_key}\"" >>.env

  source .env

  res=$(api_call GET "memos")
  jq -c '.memos[]' <<<"$res" >/dev/null
  if [ $? -eq 0 ]; then
    echo "Login successful"
  else
    echo "Login error, check the provided values and try again."
  fi
}

edit() {
  filter="$1"

  source .env

  list_res=$(api_call GET "memos?pageSize=100")
  selected_memo=$(jq -c '.memos[] | {title: ((.content | match("^# ([^\n]+)"; "g").captures[0].string) // .content), name: .name}' <<<"$list_res" | fzf --select-1 -q "$filter")

  memo_id=$(jq -r '.name' <<<"$selected_memo")
  memo_res=$(api_call GET "${memo_id}")

  tmpfile=$(mktemp -u).md
  touch "$tmpfile"

  jq -r '.content' <<<"$memo_res" >"$tmpfile"

  ${EDITOR:-vi} "$tmpfile"

  payload=$(jq -Rs '{"content":.}' "$tmpfile")

  http_code=$(api_call PATCH "${memo_id}" "${payload}")

  if [[ "$http_code" =~ ^2 ]]; then
    rm -rf "$tmpfile"
    echo "Note successfully updated!"
  else
    echo "Update failed — keeping $tmpfile"
    echo "Server response:"
    jq '.' /tmp/memo_update_response.json
  fi
}

new() {
  source .env

  tmpfile=$(mktemp -u).md
  touch "$tmpfile"

  ${EDITOR:-vi} "$tmpfile"

  payload=$(jq -Rs '{"content":.}' "$tmpfile")

  http_code=$(api_call POST "memos" "${payload}")

  if [[ "$http_code" =~ ^2 ]]; then
    rm -rf "$tmpfile"
    echo "Note successfully created!"
  else
    echo "Update failed — keeping $tmpfile"
    echo "Server response:"
    jq '.' /tmp/memo_update_response.json
  fi

}

case "$1" in
login)
  login
  ;;
edit)
  edit "${2-}"
  ;;
new)
  new
  ;;
*)
  echo "Unknown command: $1"
  echo "Usage: $0 {login|edit|new}"
  exit 1
  ;;
esac
