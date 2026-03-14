#!/usr/bin/env bash
# agent-status: Show active workspaces, bookmarks, and potential conflicts.
# Helps parallel agents understand what other agents are working on.
#
# Usage:
#   agent-status.sh              # list workspaces and bookmarks
#   agent-status.sh --check      # also check for file overlap between bookmarks
#   agent-status.sh --json       # output as JSON (for programmatic use)
set -euo pipefail

if ! command -v jj &>/dev/null; then
  echo "jj-skipper: jj is required" >&2
  exit 1
fi

CHECK_CONFLICTS=false
JSON_OUTPUT=false
for arg in "$@"; do
  case "$arg" in
    --check) CHECK_CONFLICTS=true ;;
    --json)  JSON_OUTPUT=true ;;
  esac
done

# --- Active workspaces ---
if [[ "$JSON_OUTPUT" == true ]]; then
  workspaces_json=$(jj workspace list 2>/dev/null | while IFS= read -r line; do
    name=$(echo "$line" | awk '{print $1}')
    printf '"%s",' "$name"
  done | sed 's/,$//')
  echo "{"
  echo "  \"workspaces\": [${workspaces_json}],"
else
  echo "=== Active Workspaces ==="
  jj workspace list 2>/dev/null || echo "  (none or error reading workspaces)"
  echo ""
fi

# --- Bookmarks ---
if [[ "$JSON_OUTPUT" == true ]]; then
  bookmarks_json=$(jj bookmark list 2>/dev/null | while IFS= read -r line; do
    name=$(echo "$line" | awk '{print $1}')
    printf '"%s",' "$name"
  done | sed 's/,$//')
  echo "  \"bookmarks\": [${bookmarks_json}],"
else
  echo "=== Bookmarks ==="
  jj bookmark list 2>/dev/null || echo "  (none or error reading bookmarks)"
  echo ""
fi

# --- Recent changes by all agents ---
if [[ "$JSON_OUTPUT" != true ]]; then
  echo "=== Recent Changes (all bookmarks) ==="
  jj log -r 'bookmarks() | @' --limit 20 2>/dev/null || echo "  (none)"
  echo ""
fi

# --- Conflict pre-check ---
if [[ "$CHECK_CONFLICTS" == true ]]; then
  if [[ "$JSON_OUTPUT" != true ]]; then
    echo "=== Conflict Check ==="
  fi

  # Get all non-main bookmarks
  bookmarks=($(jj bookmark list 2>/dev/null | awk '{print $1}' | grep -v '^main$' || true))

  if [[ ${#bookmarks[@]} -lt 2 ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
      echo "  \"conflicts\": []"
    else
      echo "  No conflict risk: fewer than 2 active bookmarks."
    fi
  else
    conflicts_found=false
    if [[ "$JSON_OUTPUT" == true ]]; then
      echo "  \"conflicts\": ["
    fi

    # Compare each pair of bookmarks for file overlap
    for ((i=0; i<${#bookmarks[@]}; i++)); do
      for ((j=i+1; j<${#bookmarks[@]}; j++)); do
        b1="${bookmarks[$i]}"
        b2="${bookmarks[$j]}"

        # Get files changed by each bookmark relative to main
        files1=$(jj log -r "main..${b1}" --no-graph -T '' --stat 2>/dev/null | awk '{print $1}' | sort -u || true)
        files2=$(jj log -r "main..${b2}" --no-graph -T '' --stat 2>/dev/null | awk '{print $1}' | sort -u || true)

        if [[ -n "$files1" ]] && [[ -n "$files2" ]]; then
          overlap=$(comm -12 <(echo "$files1") <(echo "$files2") 2>/dev/null || true)
          if [[ -n "$overlap" ]]; then
            conflicts_found=true
            if [[ "$JSON_OUTPUT" == true ]]; then
              overlap_json=$(echo "$overlap" | while IFS= read -r f; do printf '"%s",' "$f"; done | sed 's/,$//')
              echo "    {\"bookmark1\": \"$b1\", \"bookmark2\": \"$b2\", \"files\": [$overlap_json]},"
            else
              echo "  WARNING: $b1 and $b2 both modify:"
              echo "$overlap" | sed 's/^/    /'
              echo "  Consider rebasing one onto the other before pushing."
              echo ""
            fi
          fi
        fi
      done
    done

    if [[ "$JSON_OUTPUT" == true ]]; then
      echo "  ]"
    elif [[ "$conflicts_found" == false ]]; then
      echo "  No file overlaps detected between active bookmarks."
    fi
  fi
fi

if [[ "$JSON_OUTPUT" == true ]]; then
  echo "}"
fi
