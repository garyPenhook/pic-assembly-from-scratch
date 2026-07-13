#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root/verify"

summary="$root/verify/verify-summary.tsv"
printf 'source\ttarget\tstatus\tmap\tlisting\thex\telf\n' > "$summary"

PIC_AS=${PIC_AS:-pic-as}
DFP_PIC16F17146=${DFP_PIC16F17146:-}
DFP_PIC18F57Q43=${DFP_PIC18F57Q43:-}
DFP_PIC16F570=${DFP_PIC16F570:-}

if ! command -v "$PIC_AS" >/dev/null 2>&1; then
    echo "ERROR: pic-as not found; set PIC_AS to the XC8 pic-as executable." >&2
    exit 2
fi

missing=0
for pair in \
    "DFP_PIC16F17146:$DFP_PIC16F17146" \
    "DFP_PIC18F57Q43:$DFP_PIC18F57Q43" \
    "DFP_PIC16F570:$DFP_PIC16F570"; do
    name=${pair%%:*}
    value=${pair#*:}
    if [[ -z "$value" ]]; then
        echo "ERROR: set $name to the DFP xc8 directory." >&2
        missing=1
    fi
done
(( missing == 0 )) || exit 2

run_one() {
    local cpu=$1 dfp=$2 source=$3
    local stem=${source%.S}
    echo "VERIFY $cpu $source"
    "$PIC_AS" -mcpu="$cpu" -mdfp="$dfp" \
        -Wa,-a -Wl,-Map="${stem}.map" "$source"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$source" "$cpu" "build-verified" \
        "${stem}.map" "${stem}.lst" "${stem}.hex" "${stem}.elf" >> "$summary"
}

for source in spin.S ch5.S move.S blink.S blink8.S buffer.S paging.S psects.S count16.S linear_big.S table.S tmr0blink.S; do
    run_one 16f17146 "$DFP_PIC16F17146" "$source"
done
run_one 18F57Q43 "$DFP_PIC18F57Q43" vicQ.S
run_one 16F570 "$DFP_PIC16F570" incPort.S

echo "Canonical single-file verification passed."
