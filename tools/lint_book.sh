#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
status=0

for file in manuscript/CH*.md manuscript/APPENDIX_*.md; do
    fences=$(grep -c '^```' "$file" || true)
    if (( fences % 2 != 0 )); then
        echo "ERROR: unbalanced code fences: $file" >&2
        status=1
    fi
done

for file in manuscript/CH*.md manuscript/APPENDIX_*.md; do
    if grep -nE '\b(TODO|TBD|FIXME)\b' "$file"; then
        echo "ERROR: unresolved work marker: $file" >&2
        status=1
    fi
done

for file in manuscript/CH*.md manuscript/APPENDIX_*.md manuscript/part*.md; do
    if ! grep -Fq "$file" Makefile; then
        echo "ERROR: source is not included by Makefile: $file" >&2
        status=1
    fi
done

if [[ ! -f DOCUMENTATION_STANDARD.md || ! -f SOURCE_INVENTORY.md ]]; then
    echo "ERROR: required publication records are missing" >&2
    status=1
fi

# Check relative Markdown links in the publication sources. Anchor-only links
# are intentionally left to the PDF/Markdown renderer because heading IDs vary.
for source in README.md DOCUMENTATION_STANDARD.md SOURCE_INVENTORY.md VALIDATION_STATUS.md \
    manuscript/*.md verify/*.md; do
    source_dir=$(dirname "$source")
    while IFS= read -r link; do
        target=${link%%#*}
        [[ -z "$target" || "$target" =~ ^https?:// || "$target" =~ ^mailto: ]] && continue
        if [[ ! -e "$source_dir/$target" ]]; then
            echo "ERROR: broken local Markdown link target: $source -> $target" >&2
            status=1
        fi
    done < <(grep -oE '\]\([^)]+' "$source" 2>/dev/null | sed 's/^.*](//' | sed 's/[[:space:]]*$//' | sort -u)
done

if (( status == 0 )); then
    echo "Book lint passed."
else
    exit "$status"
fi
