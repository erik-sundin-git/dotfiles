#!/usr/bin/env bash
# PostToolUse hook (Write/Edit/MultiEdit) for .nix files under nix/:
# - git-adds a new file, since flakes only see tracked files;
# - runs nixfmt when the committed version is nixfmt-clean (or the file is
#   new), so the hand-aligned keybinding tables are left alone.
# A nixfmt failure (usually a syntax error) exits 2, which shows it to Claude.
set -euo pipefail
command -v jq >/dev/null || exit 0

f=$(jq -r '.tool_input.file_path // empty')
[[ $f == *.nix && -f $f ]] || exit 0
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}"
rel=$(realpath --relative-to=. "$f")
[[ $rel == nix/* && $rel != nix/secrets/* ]] || exit 0

if ! git ls-files --error-unmatch -- "$rel" >/dev/null 2>&1 \
  && ! git check-ignore -q -- "$rel"; then
  git add -- "$rel"
  echo "git add $rel (new file)"
fi

command -v nixfmt >/dev/null || exit 0
if ! git cat-file -e "HEAD:$rel" 2>/dev/null \
  || git show "HEAD:$rel" | nixfmt --check - >/dev/null 2>&1; then
  if ! out=$(nixfmt -- "$rel" 2>&1); then
    echo "nixfmt failed on $rel:" >&2
    echo "$out" >&2
    exit 2
  fi
fi
