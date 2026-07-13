# Validation status

Audit baseline: 2026-07-13. These labels describe what has actually been checked; they do not imply hardware behavior when only source or build checks were performed.

## Status labels

- **source-verified:** compared with the exact source document/DFP; no build or runtime claim.
- **build-verified:** assembled/linked with the stated XC8 and DFP combination; artifacts inspected where listed.
- **simulator-verified:** executed in a configured simulator session and observed.
- **hardware-verified:** programmed onto the stated board/device and observed with the listed setup.
- **not-run:** procedure is documented but the required runtime environment was unavailable.

## Canonical examples

| Example | Target | Current status | Evidence |
|---|---|---|---|
| `spin.S`, `ch5.S`, `move.S`, `blink.S`, `blink8.S` | PIC16F17146 | build-verified | `make verify`, DFP17146 |
| `buffer.S`, `paging.S`, `psects.S`, `count16.S`, `linear_big.S` | PIC16F17146 | build-verified | `make verify`, DFP17146 |
| `table.S`, `tmr0blink.S` | PIC16F17146 | build-verified | `make verify`, DFP17146 |
| `vicQ.S` | PIC18F57Q43 | build-verified | `make verify`, DFP18Q |
| `incPort.S` | PIC16F570 | build-verified | `make verify`, DFP PIC16Fxxx 1.7.162 |
| `cmain.S` + `delay.S`, `cstackQ.S` | PIC18/C interworking | source/build evidence retained in audit | See `AUDIT_REPORT.md`; add to automated target when multi-file harness is formalized |

## Runtime boundary

No current status in this table claims physical-board or live-simulator execution. Hardware and simulator procedures are source-checked against `[CNANO]`, `[MPLABX]`, and the applicable data sheets. Add a dated test log before changing a row to `simulator-verified` or `hardware-verified`.
