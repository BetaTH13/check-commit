#!/usr/bin/env bash

KEYWORD="${1:?keyword}"
REQ_ALL_RAW="${2:-false}"
BASE="${3:?base_sha}"
HEAD="${4:?head_sha}"

REQ_ALL="$(echo "$REQ_ALL_RAW" | tr '[:upper:]' '[:lower:]')"
[[ "$REQ_ALL" == "true" || "$REQ_ALL" == "false" ]] || REQ_ALL="false"

COMMITS="$(git log --pretty=format:%s "$BASE..$HEAD" || true)"

# show for debugging
if [[ -n "$COMMITS" ]]; then
  echo "$COMMITS" | while read -r msg; do
    echo "- $msg"
  done
else
  echo "⚠️ No commits found in range."
fi

TOTAL="$(echo "$COMMITS" | sed '/^\s*$/d' | wc -l | tr -d ' ')"
MATCHING="$(echo "$COMMITS" | grep -F -c "$KEYWORD" || true)"

echo "✅ Total commits: $TOTAL"
echo "✅ Matching commits: $MATCHING"

if [[ "$REQ_ALL" == "true" ]]; then
  if [[ "$TOTAL" -eq 0 || "$MATCHING" -ne "$TOTAL" ]]; then
    echo "❌ require-all=true: $MATCHING/$TOTAL commits contain '$KEYWORD'"
    exit 1
  fi
else
  if [[ "$MATCHING" -eq 0 ]]; then
    echo "❌ require-all=false: $MATCHING/$TOTAL commits contain '$KEYWORD'"
    exit 1
  fi
fi

echo "✅ OK: $MATCHING/$TOTAL commits contain '$KEYWORD' (require-all=$REQ_ALL)"