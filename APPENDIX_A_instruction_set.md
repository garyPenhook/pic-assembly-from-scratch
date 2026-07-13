# Appendix A — Instruction Set Quick Reference

This appendix gives the complete **50-instruction PIC16F17146** quick card, then compact delta
cards for the plain-baseline PIC10F200, enhanced-baseline PIC16F570, and PIC18F57Q43. The exact
device data sheet remains authoritative for encodings and device-specific extensions.

**Operand key** (data sheet §41, Table 41-1):
`f` = file register address (0x00–0x7F) · `W` = Working register · `b` = bit number (0–7) ·
`k` = literal/constant · `d` = destination (**`,w`** → result to W, **`,f`** → result to f;
default is `,f`) · `n` = FSR number (0–1) · `mm` = pre/post inc-dec mode.

**Status flags:** `C` = Carry · `DC` = Digit Carry · `Z` = Zero · `TO` = Time-Out · `PD` = Power-Down.

---

## A.1 Byte-oriented operations

| Mnemonic | Operation | Flags |
|---|---|---|
| `ADDWF f,d` | W + f → dest | C, DC, Z |
| `ADDWFC f,d` | W + f + Carry → dest | C, DC, Z |
| `ANDWF f,d` | W AND f → dest | Z |
| `ASRF f,d` | arithmetic right shift f | C, Z |
| `LSLF f,d` | logical left shift f | C, Z |
| `LSRF f,d` | logical right shift f | C, Z |
| `CLRF f` | 0 → f | Z |
| `CLRW` | 0 → W | Z |
| `COMF f,d` | complement f → dest | Z |
| `DECF f,d` | f − 1 → dest | Z |
| `INCF f,d` | f + 1 → dest | Z |
| `IORWF f,d` | W OR f → dest | Z |
| `MOVF f,d` | f → dest (use `,w` to load W) | Z |
| `MOVWF f` | W → f | — |
| `RLF f,d` | rotate f left through Carry | C |
| `RRF f,d` | rotate f right through Carry | C |
| `SUBWF f,d` | f − W → dest | C, DC, Z |
| `SUBWFB f,d` | f − W − Borrow → dest | C, DC, Z |
| `SWAPF f,d` | swap nibbles of f → dest | — |
| `XORWF f,d` | W XOR f → dest | Z |

### Byte-oriented skip

| Mnemonic | Operation | Flags |
|---|---|---|
| `DECFSZ f,d` | f − 1 → dest, **skip next if 0** | — |
| `INCFSZ f,d` | f + 1 → dest, **skip next if 0** | — |

---

## A.2 Bit-oriented operations

| Mnemonic | Operation | Flags |
|---|---|---|
| `BCF f,b` | 0 → bit b of f | — |
| `BSF f,b` | 1 → bit b of f | — |
| `BTFSC f,b` | **skip next if** bit b of f **is clear** | — |
| `BTFSS f,b` | **skip next if** bit b of f **is set** | — |

---

## A.3 Literal operations

| Mnemonic | Operation | Flags |
|---|---|---|
| `ADDLW k` | W + k → W | C, DC, Z |
| `ANDLW k` | W AND k → W | Z |
| `IORLW k` | W OR k → W | Z |
| `MOVLB k` | k → BSR (bank select) | — |
| `MOVLP k` | k → PCLATH (page select) | — |
| `MOVLW k` | k → W | — |
| `SUBLW k` | k − W → W | C, DC, Z |
| `XORLW k` | W XOR k → W | Z |

---

## A.4 Control operations

| Mnemonic | Operation | Cycles | Flags |
|---|---|---|---|
| `BRA k` | relative branch (PC+1+k) | 2 | — |
| `BRW` | relative branch (PC+1+W) | 2 | — |
| `CALL k` | call subroutine (k = 0–2047) | 2 | — |
| `CALLW` | call subroutine at PCLATH:W | 2 | — |
| `GOTO k` | jump to address | 2 | — |
| `RETURN` | return from subroutine | 2 | — |
| `RETLW k` | return, putting k in W | 2 | — |
| `RETFIE` | return from interrupt | 2 | — |

> `CALL`/`GOTO` carry an **11-bit** address (reach 2048 words = one page); the upper bits come from
> `PCLATH` (Chapter 9).

---

## A.5 Inherent operations

| Mnemonic | Operation | Flags |
|---|---|---|
| `NOP` | no operation | — |
| `SLEEP` | enter Sleep mode | TO, PD |
| `CLRWDT` | clear Watchdog Timer | TO, PD |
| `RESET` | software device reset | — |
| `TRIS f` | load TRIS register from W (legacy) | — |

---

## A.6 Indirect / FSR operations

| Mnemonic | Operation | Flags |
|---|---|---|
| `ADDFSR n,k` | FSRn + k → FSRn (k = −32…31) | — |
| `MOVIW ++FSRn` / `--FSRn` | pre-inc/dec FSRn, then INDFn → W | Z |
| `MOVIW FSRn++` / `FSRn--` | INDFn → W, then post-inc/dec FSRn | Z |
| `MOVIW k[FSRn]` | *(FSRn + k) → W, FSRn unchanged (k = −32…31) | Z |
| `MOVWI ++FSRn` / `--FSRn` | pre-inc/dec FSRn, then W → INDFn | — |
| `MOVWI FSRn++` / `FSRn--` | W → INDFn, then post-inc/dec FSRn | — |
| `MOVWI k[FSRn]` | W → *(FSRn + k), FSRn unchanged | — |

That's the full 50 (data sheet §41, Table 41-3). Everything else you type is either a *directive*
(Appendix B) or an assembler *pseudo-instruction* (below).

---

## A.7 Assembler conveniences (not part of the 50)

Some generate one or more real instructions; the `*MASK()` forms are expression macros that emit
no instruction (User's Guide §4.1):

| Pseudo-op | Expands to / does |
|---|---|
| `BANKSEL obj` | emits `movlb` to select `obj`'s data bank (Chapter 8) |
| `BANKMASK(obj)` | expression macro: trims an operand to its bank offset; emits no instruction |
| `PAGESEL lbl` | emits `movlp` to select `lbl`'s program page (Chapter 9) |
| `PAGEMASK(lbl)` | expression macro: trims an operand to the call/goto field; emits no instruction |
| `fcall lbl` | page-safe call pseudo-instruction; XC8 4.00 may emit page select/restore code even when the final target shares a page (Chapter 9) |
| `ljmp lbl` | page-safe jump pseudo-instruction; may expand to page-selection code plus `goto` (Chapter 9) |

---

## A.8 Cross-core delta cards

These cards highlight what changes; they are not substitutes for the full instruction tables.

| Core/device anchor | Instruction-set shape | Important differences from PIC16F17146 |
|---|---|---|
| Plain baseline `PIC12`: PIC10F200 | 33 single-word, 12-bit instructions | two-level return stack; `RETLW` is the return form; no `RETURN`, `RETFIE`, `MOVLB`, or interrupt controller |
| Enhanced baseline `PIC12IE`: PIC16F570 | 36 single-word, 12-bit instructions | adds `MOVLB`, `RETURN`, and `RETFIE`; four-level return stack and interrupt support |
| PIC18: PIC18F57Q43 | standard 16-bit PIC18 set plus device extensions | explicit access operand `,c`/`,a` vs `,b`; `MOVFF`/`MOVFFL`, `LFSR`, multiply, conditional branches, `PUSH`/`POP`, table read/write, fast `CALL`/`RETURN`/`RETFIE` modes |

Transfer rules also change: baseline `CALL` and PCL-modifying instructions can enter only the
first 256 words of a 512-word page (Chapter 19); enhanced mid-range `CALL`/`GOTO` use PCLATH and
2048-word pages; PIC18 uses byte-addressed program memory and does not need `PAGESEL`.

> **Data-sheet wording note.** DS40002343F Table 41-3 prints `RETFIE k`, but its detailed
> instruction entry says **Operands: None** and shows `RETFIE`. Use the operand-free form on the
> PIC16F17146; PIC18 fast return is the separate `retfie f` syntax described in Chapter 15.

## A.9 Reference

- **Data sheet §41 "Instruction Set Summary"** — the authoritative table (Table 41-3) and per
  -instruction detail (syntax, operands, cycles, encoding, status).
- **User's Guide §4.1** — the assembler's instruction deviations, the `,w`/`,f` operand styles,
  and the pseudo-instructions above.
- **PIC10F200 data sheet DS40001239F §10** and **PIC16F570 data sheet DS40001684F §13** — the
  two 12-bit-core instruction tables.
- **PIC18F27/47/57Q43 data sheet DS40002147H §44** — the Q43 standard and extended instruction
  tables.
