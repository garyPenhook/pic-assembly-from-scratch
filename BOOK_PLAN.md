# Book Plan: *PIC Assembly from Scratch — A Beginner's Guide with MPLAB XC8*

Target chip: **PIC16F17146** (PIC16F17126/46 family, enhanced mid-range core, 14/20-pin).
All PIC16F17146 hardware facts are confirmed against **DS40002343F** before appearing in the
text; secondary-device facts use their exact-device data sheets, errata, and DFPs.

---

## Source Materials

| Source | Pages | Role in book |
|---|---|---|
| MPLAB XC8 PIC Assembler — Guide for Embedded Engineers (50002994C) | 54 | Tutorial spine / worked examples |
| MPLAB XC8 PIC Assembler — User's Guide (DS50002974E) | 233 | Reference: driver, syntax, directives, linker, utilities, error catalog |
| PIC16F17126/46 Data Sheet (DS40002343F) | 723 | Authoritative source for every register/pin/config/peripheral fact |

Verified target-chip facts (from DS40002343F, pp. 3–4):
- Operating voltage 1.8–5.5 V; industrial/extended temperature grades.
- Up to 35 I/O pins; one input-only pin; IOC on up to 25 pins; one external interrupt pin.
- **Peripheral Pin Select (PPS)** for digital I/O mapping.
- Timers: **TMR0** (8/16-bit configurable), **TMR1/TMR3** (16-bit, gate control), **TMR2/4/6** (8-bit, Hardware Limit Timer).
- 2× CCP, up to 4× PWM (16-bit), 4× CLC, 1× CWG, 1× NCO.
- 2× EUSART (RS-232/485/LIN), 2× MSSP (SPI + I²C).
- **ADCC**: 12-bit differential ADC with Computation; 2× 8-bit DAC.
- CRC with memory scan; DIA/DCI; Storage Area Flash (SAF); boot block.

> Register addresses, bit names, configuration settings, and pin functions are checked against
> the local exact-device data sheet, errata, and selected DFP — never accepted from memory alone.

---

## 1. Positioning & Premise

**Audience.** Complete beginners to assembly language with some prior programming exposure (any
language) but no microcontroller, register, or data-sheet experience. Hobbyists, EE/CS students,
embedded newcomers.

**Gap filled.** The two Microchip guides are *reference*, not *teaching* — they assume you already
understand psects, banking, cores, and the toolchain. This book teaches the mental model first,
then hands over the reference vocabulary so the official guides become usable afterward.

**Core promise.** "By the end you can write and build a working PIC assembly program, inspect its
linked artifacts, and follow the documented simulator/programming workflows for the PIC16F17146 —
and read the official XC8 Assembler User's Guide without getting lost."

**Guiding principles.**
- Technical chapters end with a buildable example or an artifact-reading exercise; introductory
  chapters can end with a data-sheet or architecture exercise.
- No concept is introduced more than one chapter before it is used.
- **Reverse the source ordering:** teach mid-range (PIC16F17146) first — the beginner's most likely
  core — then generalize up to PIC18 and down to baseline. (The Embedded Engineers guide leads with
  PIC18; that is wrong for beginners.)

---

## 2. Architecture — 5 Parts, 19 core chapters + appendices

### Part I — Foundations
- **Ch 1 — What Is a Microcontroller?** CPU vs. MCU, Harvard architecture, program vs. data memory,
  the W register, what an instruction set is. Concept chapter; ends with a labeled-diagram exercise.
- **Ch 2 — Meet the PIC Cores.** Baseline (12-bit) / mid-range (14-bit) / enhanced mid-range /
  PIC18 (16-bit); where the PIC16F17146 sits (enhanced mid-range). *Source: User's Guide §2.1.*
- **Ch 3 — Installing the Toolchain.** MPLAB X IDE, XC8, Device Family Pack for PIC16F17146,
  selecting the device, simulator-first workflow. *Source: User's Guide §2.2, §3.5.*
  Runnable: an empty project that builds.

### Part II — Your First Programs (tutorial spine)
- **Ch 4 — Anatomy of an Assembly Source File.** Statement format, labels, mnemonics, operands,
  comments, `#include <xc.inc>`, `PROCESSOR`. *Source: User's Guide §4.2–4.4; Emb. Eng. §3.1–3.3.*
  Runnable: `GOTO $` idle loop.
- **Ch 5 — Configuration Bits & the Reset Vector.** `CONFIG` directive for the PIC16F17146
  (oscillator, WDT, MCLR — confirmed against DS40002343F config-word section), reset vector at 0.
  *Source: Emb. Eng. §3.2.* Runnable: correctly-configured minimal program.
- **Ch 6 — Moving Data: W, Literals, and File Registers.** `MOVLW`, `MOVWF`, `MOVF`, W register,
  literals vs. file registers, `BANKSEL` teaser. *Source: User's Guide §4.1.*
  Runnable: copy a value between registers, watch it in the simulator.
- **Ch 7 — Your First Blink.** Full walk-through on PIC16F17146: ANSEL (digital-select) →
  TRIS (direction) → LAT (drive), a nested-delay loop, driving LED0 on **RC1** (active-low,
  verified CNANO §4.2.1). The payoff chapter. **Note:** PPS is *not* needed — pins default to
  their data latch as output source (§16.12); PPS is deferred to the peripheral-routing chapter.
  *Source: Emb. Eng. §4, re-taught; data sheet §16, §41.*
  Runnable: LED blinks (simulator LAT watch + Curiosity Nano hardware sidebar).

### Part III — Memory: The Hard Part, Made Gentle
- **Ch 8 — Data Memory & Banking.** Why banks exist, `BANKSEL`, common/shared RAM.
  *Source: Emb. Eng. §4.3, §5.1.* Runnable: variable in a high bank accessed correctly.
- **Ch 9 — Program Memory & Paging.** Pages, `PAGESEL`, what happens when you forget.
  *Source: Emb. Eng. §5.2.* Runnable: a `CALL` across a page boundary.
- **Ch 10 — Psects: Organizing Code & Data.** The `PSECT` directive demystified (the one concept
  the official guides assume). Predefined vs. user-defined, class, flags (`delta`, `space`, `reloc`).
  *Source: User's Guide §4.8, §5.2; Emb. Eng. §3.5–3.6.* Runnable: custom psect seen in the map file.
- **Ch 11 — Linear Memory & Larger Variables.** Multi-byte variables, linear addressing on enhanced
  mid-range. *Source: Emb. Eng. §5.3.* Runnable: a 16-bit counter.

### Part IV — Building Real Programs
- **Ch 12 — Directives You'll Actually Use.** Curated subset: `EQU`, `SET`, `DB`/`DW`, `ORG`,
  `GLOBAL`/`EXTERN`, `MACRO`/`ENDM`, `IF`/`ELSE`/`ENDIF`. *Source: User's Guide §4.9 (filtered).*
  Runnable: a `DB` lookup table.
- **Ch 13 — Macros & Multiple Source Files.** Writing macros, splitting a project,
  `GLOBAL`/`EXTERN` linkage, archiver/librarian intro. *Source: Emb. Eng. §4.1, §5; User's Guide §7.1.*
  Runnable: two-file project with a shared macro library.
- **Ch 14 — Interrupts on the PIC16F17146.** Interrupt vector, automatic core context save,
  shared-state rules, `INTCON`,
  servicing a TMR0/TMR2 interrupt, defining and using bits. All vector/register facts confirmed
  against DS40002343F interrupt chapter. *Source: Emb. Eng. §7.* Runnable: timer-driven blink via ISR.
- **Ch 15 — Moving Up a Core: PIC18 Interrupts.** How PIC18 differs — priority/vectored interrupts,
  expanded registers, extended data memory. Uses a modern **PIC18F57Q43** (verified against its data
  sheet §11 + build-tested). *Source: PIC18F57Q43 data sheet §11; Emb. Eng. §3, §8.* Runnable: PIC18
  vectored-interrupt example.
- **Ch 16 — The Compiled Stack.** Why PIC assembly uses a compiled (not hardware) stack for locals;
  stack directives. *Source: Emb. Eng. §6; User's Guide §5.5.* Runnable: a function with locals.

### Part V — Toolchain Mastery & Going Further
- **Ch 17 — The Linker & Map Files.** What the linker does, reading a map file, memory ranges,
  default linker classes, linker-defined symbols. *Source: User's Guide §6, §5.3–5.4.*
  Runnable: locate every symbol from Ch 7 in its map file.
- **Ch 18 — Utilities, Hex Files & Programming the Chip.** Hexmate, generating/merging HEX,
  checksums, flashing real silicon (Curiosity Nano). *Source: User's Guide §7.2.*
  Runnable: blink on physical hardware.
- **Ch 19 (optional) — Baseline and Enhanced-Baseline Devices.** The 12-bit world: plain PIC12
  (PIC10F200, no interrupts) versus PIC12IE (PIC16F570, interrupt-capable), callable-entry
  placement, and tight constraints. *Source: exact device data sheets + Emb. Eng. §9.*

### Appendices
- **A — Instruction Set Quick Reference** (by core). *From User's Guide §4.1.*
- **B — Directive Reference Card** (full §4.9; beginner subset flagged).
- **C — Decoding Error & Warning Messages** — turn User's Guide §8 (100+ pp.) into a debugging
  skill; 15 most-common beginner errors with fixes.
- **D — MPLAB X Assembler Option Reference.** *From User's Guide §3.4.*
- **E — MPASM → XC8 Migration Notes** (points to the Migration Guide).
- **F — Glossary** (psect, bank, page, W, literal, vector, PPS, relocation, …).
- **G — From Assembly to C** — where XC8 C fits; inline-asm teaser.

---

## 3. Per-Chapter Template (adapted where a chapter is conceptual)

1. **What you'll build** — the runnable end state, up front.
2. **The idea** — plain-English concept, one diagram.
3. **The code** — full listing, line-annotated.
4. **Build & inspect it** — exact MPLAB X clicks / command line; simulator setup where useful.
5. **What just happened** — trace registers/memory.
6. **Common mistakes** — 2–4 real error messages (cross-ref Appendix C) + fixes.
7. **Try it yourself** — 2–3 graded exercises (solutions in the companion repo).
8. **Reference bridge** — "Now read §X of the official User's Guide; you're ready for it."

---

## 4. Recurring Devices & Assets

- **Primary target:** PIC16F17146 for Parts I–IV. **PIC18F57Q43** (modern Q-series) for Ch 15–16.
  Baseline PIC16F570/PIC10F for Ch 19.
- **Tool-first:** canonical examples build at the command line and can be inspected in listings,
  maps, disassembly, and HEX output; simulator and Curiosity Nano procedures are additive.
- **Companion sources:** the `verify/` directory contains the canonical build-tested listings; the
  root `Makefile` builds the complete book PDF.
- **"Data Sheet Dive" sidebars:** teach the reader to confirm each register/pin/config fact against
  DS40002343F — building the single most important embedded habit early.

---

## 5. Source-to-Chapter Coverage Matrix

| Source section | Lands in |
|---|---|
| Emb. Eng. §3 (PIC18 basic) | Ch 15 (moved later, deliberately) |
| Emb. Eng. §4 (Mid-range basic) | Ch 4–8 |
| Emb. Eng. §5 (Multi-file/paging/linear) | Ch 9, 11, 13 |
| Emb. Eng. §6 (Compiled stack) | Ch 16 |
| Emb. Eng. §7 (Interrupts mid-range) | Ch 14 |
| Emb. Eng. §8 (Interrupts PIC18) | Ch 15 |
| Emb. Eng. §9 (Baseline) | Ch 19 |
| User's Guide §3 (Driver/options/IDE) | Ch 3, App. D |
| User's Guide §4 (Assembly language) | Ch 4–6, 10, 12, App. A/B |
| User's Guide §5 (Features/psects/stack) | Ch 10, 16, 17 |
| User's Guide §6 (Linker/map) | Ch 17 |
| User's Guide §7 (Utilities) | Ch 13, 18 |
| User's Guide §8 (Errors/warnings) | App. C (used throughout) |

Every source section is accounted for; the 117-page message catalog is repackaged as a debugging
skill rather than dumped.

---

## 6. Production Plan

- **Delivered length:** about 189 pages in the current 7×10-inch layout, including all 19 chapters
  and seven appendices. Coverage, not padding to an earlier page estimate, is the completion gate.
- **Draft order:** Part II first (Ch 4–7) — the spine that validates the pedagogy — then III, IV,
  then I and V.
- **Verify-before-done gate:** each canonical runnable listing must assemble and link with the
  stated XC8/DFP combination, and relevant map/listing/disassembly/HEX artifacts must be inspected.
  Config bits, register names, pin assignments, and device behavior are checked against the local
  exact-device data sheet, errata, and DFP. Simulator and physical-board execution remain separate
  runtime validation steps and are not claimed by the source audit.
- **Milestones:** (1) Ch 4–7 drafted + all examples building; (2) Parts III–IV; (3) Part I & V +
  appendices; (4) full technical-review pass; (5) companion repo frozen to match the text.
