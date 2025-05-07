#!/bin/bash
# Description: This script creates autolinks for all directories in the current directory.
# Usage: Run this script in a directory containing subdirectories for each repository.
# Dependencies: gh CLI must be installed and authenticated.
# This particular example creates autolinks for CVEs to link to NVD (National Vulnerability Database).
for dir in */; do
  if [[ -d "$dir" ]]; then
    (cd "$dir" && gh repo autolink create CVE- "https://nvd.nist.gov/vuln/detail/CVE-<num>")
  fi
done
