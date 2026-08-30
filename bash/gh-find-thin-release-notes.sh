#!/usr/bin/env bash
# Find GitHub releases whose notes are shorter than a line threshold.
#
# Scope: all non-fork ("source") repos owned by $OWNER, plus any repos named
# in $EXTRA_REPOS (besapi is a fork of CLCMacTeam/besapi, so it is not a
# "source" repo and must be listed explicitly).
#
# Read-only: only GET requests via `gh api`. Safe to re-run.
#
# Requires: gh (authenticated), jq
#
# Usage:
#   ./gh-find-thin-release-notes.sh [MIN_LINES]
# Env:
#   OWNER        GitHub owner to scan          (default: jgstew)
#   EXTRA_REPOS  space-separated owner/repo    (default: jgstew/besapi)
#   MIN_LINES    flag releases with fewer than this many lines (default: 8)
#   COUNT_BLANK  1 = count blank lines too     (default: 0, non-blank only)
#   INCLUDE_ARCHIVED 1 = include archived repos (default: 0)
#   FORMAT       table | tsv | json            (default: table)

set -euo pipefail

MIN_LINES="${1:-${MIN_LINES:-8}}"
OWNER="${OWNER:-jgstew}"
EXTRA_REPOS="${EXTRA_REPOS:-jgstew/besapi}"
COUNT_BLANK="${COUNT_BLANK:-0}"
INCLUDE_ARCHIVED="${INCLUDE_ARCHIVED:-0}"
FORMAT="${FORMAT:-table}"

command -v gh >/dev/null || { echo "error: gh CLI not found" >&2; exit 1; }
command -v jq >/dev/null || { echo "error: jq not found" >&2; exit 1; }
# Host-scoped: unrelated stale enterprise-host tokens must not block the scan.
GH_HOST_CHECK="${GH_HOST:-github.com}"
gh auth status -h "$GH_HOST_CHECK" >/dev/null 2>&1 || {
  echo "error: not authenticated to ${GH_HOST_CHECK}; run 'gh auth login -h ${GH_HOST_CHECK}'" >&2
  exit 1
}

# --- collect repo list -------------------------------------------------------
repo_filter='.[] | select(.isArchived == false) | .nameWithOwner'
[ "$INCLUDE_ARCHIVED" = "1" ] && repo_filter='.[] | .nameWithOwner'

repos="$(gh repo list "$OWNER" --source --limit 1000 \
           --json nameWithOwner,isArchived --jq "$repo_filter")"
for extra in $EXTRA_REPOS; do
  repos="$repos"$'\n'"$extra"
done
repos="$(printf '%s\n' "$repos" | sed '/^$/d' | sort -u)"

echo "Scanning $(printf '%s\n' "$repos" | wc -l | tr -d ' ') repos for releases with < ${MIN_LINES} lines of notes..." >&2

# --- gather releases ---------------------------------------------------------
# Line count is computed in jq so the body never has to survive shell quoting.
# gh --paginate walks all pages of the releases API (100 per page).
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

for repo in $repos; do
  # --paginate emits one JSON array per page; jq handles each in turn.
  gh api "repos/${repo}/releases" --paginate 2>/dev/null \
    | jq -c --arg repo "$repo" --argjson min "$MIN_LINES" \
           --argjson blank "$COUNT_BLANK" '
        .[]
        | ((.body // "")
           | gsub("\r"; "")
           | split("\n")
           | map(sub("^\\s+";"") | sub("\\s+$";""))
           | (if $blank == 1 then . else map(select(length > 0)) end)
           | length) as $lines
        | select($lines < $min)
        | {repo: $repo, tag: .tag_name, name: (.name // ""),
           lines: $lines, chars: ((.body // "") | length),
           draft: .draft, prerelease: .prerelease,
           published: ((.published_at // .created_at) | tostring | .[0:10]),
           url: .html_url}
      ' \
    || echo "warn: could not read releases for ${repo}" >&2
done | jq -s 'sort_by(.lines, .repo, .published)' > "$tmp"

# --- report ------------------------------------------------------------------
case "$FORMAT" in
  json) cat "$tmp" ;;
  tsv)  jq -r '.[] | [.repo,.tag,.lines,.chars,.published,.url] | @tsv' "$tmp" ;;
  *)
    jq -r '
      (["REPO","TAG","LINES","CHARS","DATE","FLAGS","URL"] | @tsv),
      (.[] | [.repo, .tag, (.lines|tostring), (.chars|tostring), .published,
              (([if .draft then "draft" else empty end,
                 if .prerelease then "pre" else empty end] | join(",")) | if . == "" then "-" else . end),
              .url] | @tsv)
    ' "$tmp" | column -t -s $'\t'
    ;;
esac

echo "" >&2
echo "$(jq 'length' "$tmp") release(s) below ${MIN_LINES} lines." >&2
