#!/usr/bin/env bash
set -euo pipefail

# determine the scripts dir, so that the script can be executed from anywhere in the repo.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# creates a temporary directory
tmp="$(mktemp -d)"
# when the local test is finished (either from an error or an exit) the following command is executed.
# this line ensures that after the local test is done the tmp directory and all created files are deleted  
trap 'rm -rf "$tmp"' EXIT

# setup the test repository for the local test
cd "$tmp"
git init -q
git config user.name "Local"
git config user.email "local@test"

PASS=0
FAIL=0

# helper function to run local tests. Should only be used for tests expecting positive results
# this function should be used in case you expect a 0 exit from the bash script.
run_test() {
    local desc="$1"
    shift
    echo "=== Running test: $desc ==="
    if "$@"; then
        echo "✅ PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "❌ FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
    echo
}

run_test_expect_fail() {
  local desc="$1"; shift
  echo "=== Running test (expect fail): $desc ==="
  if "$@"; then
    echo "❌ FAIL: $desc (command succeeded but should have failed)"; FAIL=$((FAIL+1))
  else
    echo "✅ PASS: $desc (failed as expected)"; PASS=$((PASS+1))
  fi
  echo
}

# Create base commit
echo base > f && git add f && git commit -m "base"
BASE="$(git rev-parse HEAD)"

# --- TEST 1: Keyword exists in at least one commit ---
git switch -c feature -q
echo "JIRA-1" >> f && git commit -am "JIRA-1: feature work"
echo "more"  >> f && git commit -am "misc: tweak"
HEAD="$(git rev-parse HEAD)"
run_test "at least one commit contains keyword" \
    bash "$SCRIPT_DIR/check-commits.sh" "JIRA-" "false" "$BASE" "$HEAD"

# --- TEST 2: require-all=true should fail ---
run_test_expect_fail "require-all=true should fail" \
    bash "$SCRIPT_DIR/check-commits.sh" "JIRA-" "true" "$BASE" "$HEAD"

# --- TEST 3: all commits have keyword (should pass) ---
git switch -c all-pass -q "$BASE"
echo "JIRA-2" >> f && git commit -am "JIRA-2: change"
echo "JIRA-3" >> f && git commit -am "JIRA-3: change"
HEAD="$(git rev-parse HEAD)"
run_test "require-all=true should pass when all match" \
    bash "$SCRIPT_DIR/check-commits.sh" "JIRA-" "true" "$BASE" "$HEAD"

# Prints out the final summary of the local test.
echo "=== TEST SUMMARY ==="
echo "✅ Passed: $PASS"
echo "❌ Failed: $FAIL"

if [[ $FAIL -eq 0 ]]; then
    echo "🎉 ALL TESTS PASSED"
    exit 0
else
    echo "⚠️ SOME TESTS FAILED"
    exit 1
fi
