#!/usr/bin/env bash
set -euo pipefail

# extract all the parameters for the action
KEYWORD="${1:?keyword}"
REQ_ALL_RAW="${2:-false}"
BASE="${3:?base_sha}"
HEAD="${4:?head_sha}"

# convert the REQ_ALL_RAW argument into bool value 
REQ_ALL="$(echo "$REQ_ALL_RAW" | tr '[:upper:]' '[:lower:]')"
if [[ "$REQ_ALL" != "true" ]]; then
 REQ_ALL="false"
fi

if (( ${#KEYWORD} > 256 )); then
  echo "Keyword too long (max 256 chars)."
  exit 1
fi

# Retrieve all commits which happened from the BASE up until the HEAD (simply said everything in the PR).
COMMITS="$(git log --pretty=format:%s "$BASE..$HEAD" -- || true)"

# prints all commits in case any are present.
if [[ -n "$COMMITS" ]]; then
  echo "$COMMITS" | while read -r msg; do
    echo "- $msg"
  done
else
  echo "⚠️ No commits found in range."
fi

# counts the amount of commits
TOTAL="$(echo "$COMMITS" | sed '/^\s*$/d' | wc -l | tr -d ' ')"
# counts how many matches where found in the commits
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