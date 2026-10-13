#!/usr/bin/env bash
# Validates the ai-skills pack:
#   1. Every relative .md link in skills/, agents/, references/ resolves to a file.
#   2. Every SKILL.md has name: and description: frontmatter.
#   3. Checklist copies inside skills/<skill>/references/ match the canonical
#      copy in the top-level references/ (drift detection).
#
# Usage:
#   scripts/validate.sh          # report problems, exit 1 if any
#   scripts/validate.sh --sync   # overwrite drifted copies with the canonical version
set -u
cd "$(dirname "$0")/.."

SYNC=0
[ "${1:-}" = "--sync" ] && SYNC=1
ERRORS=0

fail() { echo "FAIL: $1"; ERRORS=$((ERRORS + 1)); }

# --- 1. Relative markdown links resolve -------------------------------------
BROKEN_TMP=$(mktemp)
while IFS= read -r file; do
  dir=$(dirname "$file")
  grep -oE '\]\([^)#]+\.md[^)]*\)|`[^` ]+\.md`' "$file" 2>/dev/null \
    | sed -E 's/^\]\(//; s/\)$//; s/^`//; s/`$//; s/#.*$//' \
    | while IFS= read -r target; do
      # Only validate pack-internal links. Names like CLAUDE.md, tasks/plan.md,
      # CONSTRAINTS.md describe files in the *target* project, not this pack.
      case "$target" in
        http*|''|*'*'*|*'['*) continue ;;
        ../*|references/*|skills/*|agents/*|scripts/*) ;;
        *) continue ;;
      esac
        if [ ! -f "$dir/$target" ] && [ ! -f "$target" ]; then
          echo "BROKEN: $file -> $target"
        fi
      done
done < <(find skills agents references -name '*.md' 2>/dev/null) > "$BROKEN_TMP"

if [ -s "$BROKEN_TMP" ]; then
  cat "$BROKEN_TMP"
  ERRORS=$((ERRORS + $(wc -l < "$BROKEN_TMP")))
fi
rm -f "$BROKEN_TMP"

# --- 2. SKILL.md frontmatter -------------------------------------------------
while IFS= read -r skill; do
  head -n 10 "$skill" | grep -q '^name:' || fail "$skill missing 'name:' frontmatter"
  head -n 10 "$skill" | grep -q '^description:' || fail "$skill missing 'description:' frontmatter"
done < <(find skills -mindepth 2 -maxdepth 2 -name SKILL.md)

# --- 3. Checklist copy sync ---------------------------------------------------
for canonical in references/*.md; do
  base=$(basename "$canonical")
  while IFS= read -r copy; do
    if ! cmp -s "$canonical" "$copy"; then
      if [ "$SYNC" -eq 1 ]; then
        cp "$canonical" "$copy"
        echo "SYNCED: $copy <- $canonical"
      else
        fail "DRIFT: $copy differs from canonical $canonical (run scripts/validate.sh --sync)"
      fi
    fi
  done < <(find skills -path "*/references/$base" 2>/dev/null)
done

if [ "$ERRORS" -gt 0 ]; then
  echo "---"
  echo "$ERRORS problem(s) found."
  exit 1
fi
echo "OK: all links resolve, frontmatter present, copies in sync."
