# Technical audit report

Audit date: 2026-07-13

## Result

**Pass within the validation boundary below.** The book now contains all 19 planned chapters and
all seven appendices, and the root PDF build includes them all. The text was reviewed against the
exact-device Microchip data sheets, silicon errata, DFP metadata, XC8 assembler documentation,
XC8 4.00 release notes, programming specification, board guide, and Hexmate documentation listed
in `docs/microchip/SOURCE_INVENTORY.md`.

No unresolved technical error found by this audit remains in the book. “Pass” means source-backed
editorial review, strict assembly/link verification of the canonical programs, artifact inspection,
and PDF validation. It does not mean that every example was executed on physical hardware or in a
live simulator session.

## Coverage and corrections

Four parallel review tracks covered the whole manuscript:

- Chapters 1–7: corrected RAM reset assumptions, W/file destinations, PIC18 interrupt
  generalizations, program addressing, psect deltas, configuration words, BOR/LVP meanings,
  WREG/STATUS behavior, ANSEL behavior, and glitch-free GPIO initialization.
- Chapters 8–14: corrected exact PIC16F17146 banking/linear-memory limits, `fcall`/`MOVLP`
  behavior, relocatable psects, multi-byte arithmetic wording, directive compatibility, macro
  linkage, interrupt context/flag/shared-state rules, and Timer0 setup/timing.
- Chapters 15–19: replaced K42-derived assumptions with exact PIC18F57Q43 sources, corrected Q43
  Access Bank and high-SFR operands, completed configuration words, corrected compiled-stack
  addressing, clarified LVP/programming behavior, and distinguished plain-baseline PIC10F200 from
  the interrupt-capable enhanced-baseline PIC16F570.
- Appendices A–G: completed the PIC16F17146 50-instruction quick reference plus cross-core deltas,
  corrected directive/pseudo-instruction classification, documented XC8 4.00 `DQW`/`DDW`
  behavior, tightened diagnostic/fixup and MPASM-migration advice, scoped glossary claims by core,
  and corrected XC8 inline-assembly/ABI guidance.

Two particularly consequential executable defects were found and fixed:

1. The Flash lookup-table example used `high(squares)` without the PIC16F17146 program-Flash FSR
   window bit. It now uses `high(squares) | 0x80`; disassembly contains `movlw 0xBF` for the linked
   table at `0x3FF8`.
2. The PIC18 example treated Q43 registers outside the Access Bank as access operands. It now uses
   the exact banked addresses/operands for IVT and Timer0 registers and links the vector table at
   `0x000008` with length `0x40`.

The Makefile previously omitted every appendix from the production PDF. `APPENDIX_A` through
`APPENDIX_G` are now part of `SOURCES` and the final build.

## Compiler and artifact verification

Compiler: MPLAB XC8 PIC Assembler 4.00, build 2026-06-14.

Selected packs:

| Target | DFP |
|---|---|
| PIC16F17146 | PIC16F1xxxx_DFP 1.31.465 |
| PIC18F57Q43 | PIC18F-Q_DFP 1.30.487 |
| PIC16F570 | PIC16Fxxx_DFP 1.7.162 |

All builds used explicit `-mdfp`, fatal warnings except documented DFP-header diagnostic 1289,
and the default `--fixupoverflow=error`. Sixteen canonical programs passed:

| Target | Passing programs |
|---|---|
| PIC16F17146 | `spin`, `ch5`, `move`, `blink`, `blink8`, `buffer`, `paging`, `psects`, `count16`, `linear_big`, `table`, `tmr0blink`, `cmain+delay` |
| PIC18F57Q43 | `vicQ`, `cstackQ` |
| PIC16F570 | `incPort` |

Map/listing/disassembly checks confirmed:

- complete PIC16F17146 configuration output: CONFIG1–5 = `3FEC 3FBD 3F9F 3FFF 3FFF`;
- reset placement, bank/page selection, caller-page restoration, GPIO latch-before-direction
  ordering, Timer0/vector placement, and HEX generation;
- PIC16F17146 BIGRAM class `0x2000–0x27EF`, with `bigBuf` linked at `0x2000`;
- Flash-table FSR high byte `0xBF`;
- Q43 IVT base `__Livt = 0x8`, table length `0x40`, and 4-byte ISR alignment;
- Q43 compiled-stack COMRAM at `0x500`, with sibling routines `add` and `incr` sharing offset 4;
- PIC16F570 user entry at `0x0000` and callable `ENTRY` routine at `0x0005`, while retaining the
  documented physical Reset fetch through the factory OSCCAL word at `0x07FF`.

All chapter/appendix Markdown files have balanced code fences, no TODO/TBD/FIXME markers remain,
and every displayed `pic-as -mcpu` command includes `-mdfp` on the command or its continuation.

## Retrieved official Microchip material

The audit added the exact sources that were missing:

- MPLAB X IDE User's Guide DS50002027F;
- PIC18F27/47/57Q43 data sheet DS40002147H and errata DS80000870M;
- PIC10F200/202/204/206 data sheet DS40001239F and errata DS80194G;
- PIC18F-Q_DFP 1.30.487;
- PIC16Fxxx_DFP 1.7.162;
- PIC10-12Fxxx_DFP 1.8.184.

The complete inventory records revisions, dates, official URLs, purpose, supersession notes, and
the intentionally incomplete nature of the extracted PIC16F17146-only DFP subset. Complete
`.atpack` files are retained under `docs/microchip/dfp/`.

SHA-256 values for the newly added anchor files:

| File | SHA-256 |
|---|---|
| `MPLAB-X-IDE-Users-Guide-DS50002027F.pdf` | `09e5112e296314735e6139ae1968f73ee20ed9d8a44d45d72154d8f87252d83e` |
| `PIC18F27-47-57Q43-Data-Sheet-DS40002147.pdf` | `b93917cb5a0ebb417fd7b5a1b9ff48ffcee0d50c00d75c091ebf4f68896cafdd` |
| `PIC18F27-47-57Q43-Silicon-Errata-DS80000870.pdf` | `a631ebbdd8d0a323b1b56980429472b776fc34c0905005daed014757f0a6396c` |
| `PIC10F200-202-204-206-Data-Sheet-DS40001239.pdf` | `931ad978bf467275b1e6baf35203b46fb7202e59a682f2c73d58274e98e9f106` |
| `PIC10F200-202-204-206-Silicon-Errata-DS80194.pdf` | `a5ad67d2db0c760c4d47dc184f1dcac8fc36c84caaa7714076b7e9c7c4da28c1` |
| `Microchip.PIC18F-Q_DFP.1.30.487.atpack` | `aab6a1952c8e1a128f7039aaacf7266c76489e2d9e7b1b339fa04e87b78d1ef0` |
| `Microchip.PIC16Fxxx_DFP.1.7.162.atpack` | `f4e4cc7765be381ef08a7013caba848d84d02964dd7a2f9632824aa17f1c9d84` |
| `Microchip.PIC10-12Fxxx_DFP.1.8.184.atpack` | `d2b5201ecb3be0489f07ee403702db0ab07feb42f4bbdbbf33f3a58ccfcb3518` |

## Final PDF validation

Output: `output/pdf/pic-assembly-from-scratch.pdf`

- 190 PDF pages, 7 × 10 inches;
- SHA-256 `8afc447bb1cd6073549b426e555cb6f4d233abe785be0a73ff8b364f39c42d6e`;
- `qpdf --check`: no syntax or stream-encoding errors;
- all reported fonts embedded;
- cover, contents, representative prose/code/table pages, appendices, and final page rendered and
  visually inspected without clipping or unreadable output.

## Validation boundary

No Curiosity Nano or other target board was attached, so electrical behavior and real-time timing
were not bench-tested. The local MPLAB X command-line simulator launcher (`mdb.sh`) could not start
because that installation is missing `org/jline/reader/Parser`; therefore no live simulator run is
claimed. Hardware/simulator procedures were checked against the official documentation, while
runtime claims were validated through exact-device sources plus compiler, linker, map, listing,
disassembly, and HEX artifacts.
