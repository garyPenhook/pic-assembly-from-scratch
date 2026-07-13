#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
pdf="$root/output/pdf/pic-assembly-from-scratch.pdf"

[[ -f "$pdf" ]] || { echo "ERROR: PDF does not exist: $pdf" >&2; exit 2; }
qpdf --check "$pdf"

pages=$(pdfinfo "$pdf" | awk '/^Pages:/ {print $2}')
tagged=$(pdfinfo "$pdf" | awk -F': *' '/^Tagged:/ {print $2}')
title=$(pdfinfo "$pdf" | awk -F': *' '/^Title:/ {print $2}')

[[ "$pages" =~ ^[0-9]+$ && "$pages" -gt 0 ]] || { echo "ERROR: invalid page count" >&2; exit 1; }
[[ -n "$title" ]] || { echo "ERROR: PDF title metadata is empty" >&2; exit 1; }

echo "PDF check passed: pages=$pages title=$title tagged=$tagged"
if [[ "$tagged" != "yes" ]]; then
    echo "ACCESSIBILITY: OPEN — PDF is not tagged; do not claim PDF/UA or WCAG conformance."
fi
