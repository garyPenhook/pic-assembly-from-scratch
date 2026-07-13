# Appendix E — MPASM → XC8 Migration Notes

If you have older PIC assembly written for **MPASM** (Microchip's legacy assembler), it won't build
as-is under the MPLAB XC8 PIC assembler (`pic-as`) — the syntax differs in several places. This
appendix is a starter cheat-sheet of the changes you'll hit most; every delta here is documented in
the XC8 PIC Assembler User's Guide sections cited.

> **Authoritative full reference.** Microchip's **MPLAB XC8 PIC Assembler Migration Guide
> DS50002973B** describes the nearest XC8 syntax and directives for MPASM code. For anything
> beyond the common cases below, use that guide and rebuild against the exact device pack.

---

## E.1 The high-frequency changes

| Concept | MPASM | XC8 (`pic-as`) | Source |
|---|---|---|---|
| Destination operand | `,0` (W) / `,1` (file) | **`,w`** (W) / **`,f`** (file) | §4.1.1 |
| PIC18 access bit | `,0` / `,1` | **`,c`**/`,a` (access) / `,b` (banked) | §4.1.1 |
| Move file to W | `movfw foo` | **`movf foo,w`** (no `movfw`) | §4.1.4 |
| Config bits | `__CONFIG` / `config` word | **`CONFIG "SETTING = VALUE"`** | §4.9.7 |
| Include device defs | `#include <p16f...inc>` | **`#include <xc.inc>`** (one header, all devices) | §3.3 (Emb Eng) |
| Reserve RAM | `res`/`cblock` | **`PSECT udata` + `DS n`** | §4.9.13, §5.2 |
| Program sections | MPASM sections | **`PSECT name, class=…, delta=…, space=…`** | §4.8, §4.9.48 |
| Bank select | `banksel` | **`BANKSEL`** (+ `BANKMASK()` on the operand) | §4.1.2–3 |
| Page select | `pagesel` | **`PAGESEL`** (+ `PAGEMASK()`; or use `fcall`/`ljmp`) | §4.1.2–3 |

---

## E.2 Things that trip up MPASM porters

- **Operand address masking is now explicit.** MPASM often hid bank/page bits; XC8 makes you mask
  with `BANKMASK()`/`PAGEMASK()` or use `fcall`/`ljmp`, or you'll get *fixup overflow* errors.
  `--fixupoverflow=warn:lstwarn` truncates and reports legacy cases; it does not select the correct
  bank/page and is not the migration fix (User's Guide §4.1.3; Chapters 8–9).
- **Case sensitivity.** XC8 identifiers are case-sensitive (`Fred` ≠ `fred`); mnemonics and
  directives are not (User's Guide §4.3, §4.6). Legacy code that was sloppy about label case may
  break.
- **Hex constants need a leading digit.** `FFh` becomes `0FFh` (User's Guide §4.5).
- **`#include <xc.inc>` replaces per-device headers.** Don't include `pic16f....inc` files or
  maintain your own — `xc.inc` provides the SFR/bit definitions for your selected device
  (Emb Eng §3.3).
- **The `.S` extension matters.** Use uppercase `.S` so the C preprocessor runs (enabling
  `#include`/`#define`); lowercase `.s` skips it (User's Guide §4.6.4).
- **PIC18 fast modes.** XC8 writes interrupt fast return as `retfie f`; a fast call uses
  `call target,f`. The data-sheet `0`/`1` forms are also accepted, but `f` is clearer (User's
  Guide §4.1.6–§4.1.7).
- **Current standalone builds require `-mdfp`.** Point it at the complete selected pack's `xc8`
  directory; an extracted single-device header directory is not enough.

---

## E.3 A tiny before/after

MPASM style:
```asm
    banksel PORTA
    movf    PORTA,0        ; W = PORTA
    movwf   temp,1         ; temp = W
    __CONFIG _WDT_OFF
```

XC8 (`pic-as`) style:
```asm
    BANKSEL PORTA
    movf    BANKMASK(PORTA),w    ; W = PORTA
    BANKSEL temp
    movwf   BANKMASK(temp)       ; temp = W (MOVWF has no destination operand)
    CONFIG "WDTE = OFF"
```

---

## E.4 Reference

- **MPLAB XC8 PIC Assembler Migration Guide** — the complete MPASM→XC8 equivalence reference
  (User's Guide §1.2, Recommended Reading).
- **User's Guide §4.1** — instruction deviations (operand styles, `movfw`, masking).
- **User's Guide §4.9.7** — the `CONFIG` directive.
- **Chapters 8–9** — banking/paging and the masking that MPASM used to hide.
