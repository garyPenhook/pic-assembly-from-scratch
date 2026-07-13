# Appendix B — Directive Reference Card

Directives are orders to the **assembler**, not CPU opcodes. `BANKSEL`, `BANKISEL`, and
`PAGESEL` can generate instructions; `DB`/`DW`/`DQW` generate initialized data; `DS` reserves
storage; many others only control assembly or linking (User's Guide §4.9). `#include` is a C
preprocessor directive, included here because every preprocessed `.S` file needs it.

---

## B.1 The directives you'll use constantly

| Directive | Purpose | Chapter |
|---|---|---|
| `PROCESSOR dev` | name the target device (must match `-mcpu`) | 4 |
| `#include <xc.inc>` | pull in the device's register/SFR/bit definitions | 4 |
| `CONFIG "SET = VAL"` | set a configuration bit | 5 |
| `PSECT name,flags` | declare/resume a program section (see B.3) | 4, 10 |
| `END [label]` | end of source; optional entry-point label | 4 |
| `EQU` | define a constant (define-once) | 12 |
| `SET` | define/**redefine** a value | 12 |
| `DS n` | reserve n uninitialized units (RAM variables) | 6, 12 |
| `DB` / `DW` / `DQW` | initialize constant bytes / words / 64-bit values in program memory | 12 |
| `GLOBAL sym` | export a symbol / reference an external one | 13 |
| `EXTRN sym` | import a symbol defined in another module | 13 |
| `MACRO` … `ENDM` | define a macro (with args, `&` concatenation) | 13 |
| `LOCAL lbl` | unique label per macro expansion | 13 |
| `IF`/`ELSIF`/`ELSE`/`ENDIF` | conditional assembly | 12 |
| `BANKSEL obj` | select `obj`'s data bank (emits code) | 8 |
| `PAGESEL lbl` | select `lbl`'s program page (emits code) | 9 |

---

## B.2 The rest of the directives (reference)

From User's Guide §4.9, Table 4-6, with the XC8 4.00 release-note update. You'll rarely need most
of these as a beginner, but here's the map:

**Data & storage:** `DABS` (absolute storage), `DLABS` (linear-memory absolute storage),
`ORG` (move location counter within current psect), `ALIGN` (align to a boundary).

**Symbols & linkage:** `PUBLIC` (make symbols accessible), `SIGNAT` (function signature).

**Source inclusion and conditionals:** assembler `INCLUDE`, `IF`, `ELSIF`, `ELSE`, `ENDIF`, and
the `END` directive already shown above.

**Messages & build control:** `ERROR` (halt with a message), `MESSG` (advisory message),
`WARN` (warning), `ERRORLEVEL` (enable/disable message numbers), `RADIX` (default number base),
`ASMOPT` (optimizer control — no effect in the PIC assembler).

**Repetition:** `REPT` (repeat n times), `IRP` (repeat per list item), `IRPC` (repeat per
character).

**Listing file:** `LIST` / `NOLIST`, `EXPAND` / `NOEXPAND` (macro expansion),
`COND` / `NOCOND` (conditional code in listing), `TITLE` / `SUBTITLE`, `PAGELEN`,
`PAGEWIDTH`.

**Compiled-stack / call-graph (Chapter 16):** `FNCONF`, `FNROOT`, `FNSIZE`, `FNCALL`, `FNARG`,
`FNINDIR`, `FNADDR`, `FNBREAK`; `CALLSTACK` reports remaining hardware call-stack depth to an
optimizer (the current PIC assembler performs no such optimization).

**Bank/page for indirect:** `BANKISEL` (bank select for indirect access on some devices).

**Debug/intermediate (usually tool-generated, not hand-written):** `LINE`, `FILE`,
`DEBUG_SOURCE`.

> **XC8 4.00 compatibility note.** Release notes add `DQW` for 64-bit program-memory constants.
> Although the 2024 assembler guide documents `DDW`, XC8 4.00 still lists `DDW` as unsupported
> known issue XC8-1817. Do not depend on `DDW` without testing the installed compiler version.

---

## B.3 `PSECT` flags (the ones that matter)

`PSECT name, flag, flag, …` — the flags define the section's attributes (User's Guide §4.9.48,
Table 4-10). The four you'll actually use on the PIC16F17146:

| Flag | Meaning | Rule for our chip |
|---|---|---|
| `class=NAME` | which linker class (memory range) | `CODE` for program memory, `BANKn`/`COMMON`/`RAM` for data |
| `delta=n` | bytes per address unit | **`delta=2`** for code (word-addressable); `1` (default) for data |
| `space=n` | which memory space | **`0` = program**, `1` = data |
| `reloc=n` | alignment boundary | default `1` on mid-range (PIC18 code needs `2`) |

Other flags you may meet (Table 4-10): `global` (default) / `local` (concatenate across modules or
not), `ovrld` (overlay same-named contributions; useful for relocatable vector tables), `abs`
(with `ovrld`, makes symbols truly absolute), `bit` (holds bit objects, scale 8),
`size=`/`limit=` (bounds), `pure` (read-only), `with=` (co-locate with another psect), and
`optim=` (allowed optimizations; no effect in hand-written PIC assembler code).

### Common psect declarations, ready to copy

```asm
PSECT resetVec,class=CODE,delta=2     ; reset/interrupt code, positioned with -Wl,-p...
PSECT code                            ; assembler-provided ordinary program-code psect
PSECT udata                           ; RAM variables (any GPR bank) - BANKSEL to use
PSECT udata_shr                       ; RAM variables in common RAM (no BANKSEL)
PSECT udata_bankn                     ; RAM variables in a specific bank n
```

(The assembler-provided psects `code`, `udata`, `udata_shr`, `udata_bankn`, `data` come pre-wired to
the right class once you `#include <xc.inc>`; User's Guide §5.2.)

---

## B.4 Number formats (quick reminder)

Default radix is **decimal** (User's Guide §4.5). Other bases:

| Base | Write it | Note |
|---|---|---|
| Decimal | `255` or `255D` | default |
| Hex | `0xFF` or `0FFh` | **must start with a digit** — `0FFh`, not `FFh` |
| Binary | `11111111B` | uppercase `B` suffix |
| Octal | `377o` / `377q` | — |

---

## B.5 Reference

- **User's Guide §4.9 "Assembler Directives"** — Table 4-6 (all directives) and each directive's
  detailed description.
- **User's Guide §4.9.48 "Psect Directive"** — Table 4-10, the complete flag list.
- **User's Guide §5.2 / §5.3** — the assembler-provided psects and the linker classes they map to.
