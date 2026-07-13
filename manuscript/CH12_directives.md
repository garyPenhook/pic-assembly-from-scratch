# Chapter 12 — Directives You'll Actually Use

> **Reference keys:** `[DS17146]`, `[UG]`, and `[DFP17146]` in `REFERENCES.md`.

> **Scope and validation:** PIC16F17146, enhanced mid-range core; XC8 4.00 with PIC16F1xxxx DFP 1.31.465. Examples: source- and build/link-verified; runtime not hardware-verified.

> **What you'll build:** a program with a **`DB` lookup table** — a table of squares baked into
> program memory — that you read back by index at run time. Along the way you'll pick up the
> everyday directives that make assembly readable and adaptable: named constants (`EQU`/`SET`),
> data definition (`DB`/`DW`/`DS`), and build-time decisions (`IF`/`ELSE`). These are the tools
> that turn magic numbers into names and hard-coded data into tables.

---

## 12.1 The idea: directives talk to the assembler, not the chip

You met the instruction-vs-directive split back in Chapter 4: an instruction becomes machine code
the CPU runs; a **directive** is an order to the *assembler* that shapes the build. The User's
Guide is blunt about it — "with the exception of `PAGESEL` and `BANKSEL`, these directives do not
generate instructions" (§4.9). You've already used a handful (`PROCESSOR`, `PSECT`, `CONFIG`,
`END`, `DS`). This chapter adds the rest of the everyday set. There are dozens in the reference
(§4.9, Table 4-6); you need about eight.

---

## 12.2 Named constants: `EQU` and `SET`

Magic numbers are the enemy of readable assembly. `EQU` gives a number a name (User's Guide
§4.9.16):

```asm
LED_PIN   EQU  1            ; RC1 is bit 1 - name it once
MAXCOUNT  EQU  100
BAUD      EQU  9600
```

Now you write `bcf LATC,LED_PIN` instead of a bare `1`, and if the LED ever moves you change one
line. Key rules from §4.9.16:

- **`EQU` is define-once.** "EQU is legal only when the symbol has not previously been defined."
  Try to redefine an `EQU` symbol and you get an error.
- **It reserves no memory.** `EQU` just names a value; it's like the preprocessor's `#define`.
- **No location counter.** You can't use `$` in an `EQU` expression (they're processed
  separately from the code stream).

When you *need* a value that changes as assembly proceeds, use **`SET`** instead — "defines or
re-defines symbol value" (§4.9, Table 4-6):

```asm
row   SET  0
row   SET  row+1           ; legal - SET can be reassigned; now 1
```

**Rule of thumb:** `EQU` for real constants (pin numbers, limits), `SET` for build-time counters
you deliberately step.

---

## 12.3 Reserving vs. initializing memory

Two different jobs, two different directives — and beginners mix them up constantly:

| Directive | Job | Goes where |
|---|---|---|
| `DS n` | **reserve** n uninitialized address units | current psect (normally data memory for variables) |
| `DB` / `DW` | **initialize** constant bytes / 16-bit values | **program** memory |

### `DS` — reserve RAM (you've used this)
`DS n` "reserves, but does not initialize, the specified amount of space" (§4.9.13). The unit
depends on the psect: in a data psect (`space=1`) it reserves **bytes**; that's every `DS 1` /
`DS 2` you've written for variables. In a program psect it advances the location counter without
placing initialized bytes in the HEX file. For variables, keep it in a data psect.

### `DB`/`DW` — bake constant data into the program
`DB` "initializes bytes of program memory" (§4.9.9); `DW` does 16-bit words (§4.9.14). Arguments
can be numbers, character constants, or strings:

```asm
    PSECT myData,class=STRCODE,delta=2,noexec
msg:    DB  "Hello",0        ; a nul-terminated string (you add the 0)
sq:     DW  0,1,4,9,16       ; five 16-bit values
```

Two facts that trip people up (both from §4.9.9):

- **Strings are not auto-terminated.** `DB "Hello"` stores exactly five bytes — no trailing zero.
  If you want a C-style nul terminator, add it yourself: `DB "Hello",0`.
- **On mid-range, a `DB` byte costs a whole word.** Program memory here is 14 bits wide
  (`delta=2`), so `DB 'X',1,2` stores each byte in the *low* 8 bits of a word with the upper byte
  zeroed — the HEX shows `0058 0001 0002`. You get one program word per byte. That's normal;
  just don't expect bytes to pack two-per-word like they would on a PIC18® device.
- **`DB`/`DW` can't make RAM variables.** "The DB directive cannot be used to create objects in
  data memory. For that, use the DS directive" (§4.9.9). `DB` is for *constants in flash*; `DS`
  is for *variables in RAM*.

> **XC8 4.00 width note.** The 2024 guide documents `DDW` for 32-bit constants, but the XC8 4.00
> release notes still list it as unsupported (known issue XC8-1817). XC8 4.00 adds `DQW` for
> 64-bit constants (XC8-2722). This chapter sticks to verified `DB` and `DW`; do not rely on `DDW`
> without testing the exact installed tool version.

---

## 12.4 The program — a `DB` lookup table you read at run time

Let's bake a table of squares (0²…7²) into program memory with `DB`, then read an entry by index.
Reading program-memory data uses the FSR trick from Chapter 11: point an FSR into the 0x8000+
program-Flash window by setting bit 7 of `FSR0H` (data sheet §9.1.1.2, §9.6.3).

The data-sheet example says its `HIGH` directive sets that mapping bit for a program-memory label,
but XC8 4.00 pic-as `high(label)` only extracts the numerical high byte. Therefore the code below
sets the bit explicitly with `| 0x80`; the generated disassembly must show `FSR0H` loaded with a
value whose bit 7 is set.

```asm
; ------------------------------------------------------------
;  table.S  —  a DB lookup table of squares, read by index
; ------------------------------------------------------------

    PROCESSOR 16F17146
#include <xc.inc>
;  --- paste your Chapter 5 CONFIG block here ---

INDEX     EQU  3             ; which entry to look up (3 -> 3*3 = 9)

    PSECT udata_shr
result: DS  1                ; the looked-up value lands here

    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main

    PSECT code,delta=2
main:
    ; point FSR0 at the squares table in PROGRAM memory
    movlw   low(squares)
    movwf   FSR0L
    movlw   high(squares) | 0x80 ; explicit program-flash mapping bit for XC8 pic-as
    movwf   FSR0H

    moviw   INDEX[FSR0]      ; W <- squares[INDEX]  (relative-offset read)
    movwf   result           ; stash it (common RAM: no BANKSEL)
    goto    $

; --- the lookup table, baked into program memory ------------
    PSECT data               ; provided STRCODE program-data psect on PIC16
squares:
    DB  0, 1, 4, 9, 16, 25, 36, 49     ; square(0) .. square(7)

    END     resetVec
```

Build and watch it:

```
pic-as -mcpu=16f17146 -mdfp=/path/to/PIC16F1xxxx_DFP/VERSION/xc8 \
       -Wl,-presetVec=0h -Wa,-a -Wl,-Map=table.map table.S
```

In the simulator, put a Watch on `result`, run to the `goto $`, and confirm `result` = **9**
(= 3²). Change `INDEX` to 5, rebuild, and it becomes 25. You just stored constant data in flash
and indexed into it — the foundation of every font table, sine table, and state-machine table
you'll ever write.

> **The classic alternative: `RETLW` tables.** Older code builds lookup tables from a chain of
> `RETLW` instructions reached by a computed jump (`BRW`/`ADDWF PCL`) — the data sheet shows this
> pattern in §9.1.1.1. The `DB` + FSR method above is the modern, readable equivalent; know that
> `RETLW` tables exist because you'll meet them in other people's code.

---

## 12.5 Build-time decisions: conditional assembly

`IF`/`ELSIF`/`ELSE`/`ENDIF` let you include or exclude code **when you build**, not at run time
(User's Guide §4.9.31). The argument is a constant expression; if it's non-zero, the block is
assembled:

```asm
DEBUG   EQU  1               ; flip to 0 for a production build

    IF DEBUG
        bsf   LATC,0         ; light a debug pin
    ELSE
        nop                  ; production: do nothing
    ENDIF
```

This is how one source file produces different builds — debug vs. release, or one board variant
vs. another — with no run-time cost, because the un-taken branch never becomes machine code. Two
cautions from §4.9.31:

- Both branches are still *scanned*, so they must be syntactically valid even when not assembled.
- **Don't put `EQU` inside an `IF`.** `EQU` (and other directives) are processed regardless of the
  condition, so an `EQU` in a false branch still takes effect. Keep constant definitions outside
  conditional blocks.

### Fail the build on purpose: `ERROR` and `MESSG`
You can make the assembler stop with your own message when something's misconfigured
(§4.9.17, §4.9.38):

```asm
    IF BAUD > 115200
        ERROR "BAUD rate too high for this clock"   ; halts assembly
    ENDIF
```

`ERROR` halts the build; `MESSG` prints an advisory but lets it continue. These turn silent
mistakes into loud, build-time failures — a cheap, powerful safety net.

---

## 12.6 A quick tour of the rest

You'll reach for these occasionally; know they exist (all User's Guide §4.9):

| Directive | Use |
|---|---|
| `ORG n` | move the location counter *within the current psect* (relative, not absolute — §4.9.42; Chapter 10) |
| `RADIX` | change the default number base |
| `REPT n` / `IRP` / `IRPC` | repeat a block n times / once per list item / once per character |
| `TITLE` / `SUBTITLE` | set listing-file headers |
| `#include <xc.inc>` | pull in the device register definitions (you use this every file) |

`MACRO`/`ENDM`, `GLOBAL`, and `EXTRN` are directives too — but they're the heart of the *next*
chapter, so we'll give them full treatment there rather than a one-line mention.

---

## 12.7 What just happened

You expanded from "instructions only" to the directive toolkit real programs lean on: `EQU`/`SET`
to name values, `DS` to reserve RAM vs. `DB`/`DW` to bake constants into flash, a working `DB`
lookup table read by index, and `IF`/`ELSE`/`ERROR` to make build-time decisions and catch
mistakes before they ship. None of these emit instructions — they shape *what gets built* — and
that's exactly why they make code cleaner and more adaptable.

---

## 12.8 Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| "symbol already defined" on a constant | redefined an `EQU` | use `SET` if you need to reassign (§4.9.16) |
| `DB "text"` behaves as if longer/shorter than expected | strings aren't auto-terminated | add your own `,0` for a nul terminator (§4.9.9) |
| Lookup table reads garbage | FSR points at banked/reserved data instead of 0x8000+ program Flash | load `FSR0H` with `high(label) \| 0x80` and verify bit 7 in disassembly (§9.1.1.2) |
| `DB` used for a variable, value never changes | `DB` writes flash (read-only at run time) | use `DS` in a `space=1` psect for RAM variables (§4.9.13) |
| Code in a false `IF` branch still assembled | it was an `EQU`/directive, processed regardless | move constant definitions outside the `IF` (§4.9.31) |
| Byte table twice the expected size in flash | mid-range stores one word per `DB` byte | expected on 14-bit cores (`delta=2`); not a bug (§4.9.9) |

(Appendix C decodes the exact message wording.)

---

## 12.9 Try it yourself

1. **Name the blink pin.** Go back to Chapter 7's `blink.S` and replace every literal `1` (the
   RC1 bit) with `LED EQU 1`. Confirm it still builds and blinks — and that changing one line
   would move the LED.
2. **Extend the table.** Add 8²…10² to the `squares` table, set `INDEX` to 9, and confirm
   `result` = 81.
3. **Store a string.** Define `DB "PIC",0` in a code psect, then read the three characters back
   into RAM one at a time with `moviw FSR0++`. Watch 'P','I','C' appear.
4. **Guard a constant.** Add `IF INDEX > 7` / `ERROR "index out of range"` / `ENDIF` above the
   lookup, set `INDEX` to 9, and watch the build fail with your message. Then extend the table so
   it passes.

---

## 12.10 Reference bridge

- **User's Guide §4.9** — the full directive table (Table 4-6) and every directive's detail;
  you can now navigate all of it.
- **User's Guide §4.9.9 / §4.9.14 / §4.9.13** — `DB`, `DW`, and `DS` specifics.
- **User's Guide §4.9.16 / §4.9.31** — `EQU`/`SET` and conditional assembly.
- **User's Guide §4.7** — expression operators, including what pic-as `low()` and `high()`
  actually extract from a symbol value.
- **Data sheet §9.1.1 / §9.6.3** — reading constants from program memory (RETLW and FSR methods).
- **XC8 4.00 release notes, "What's New" and "Known Issues"** — `DQW` addition (XC8-2722) and
  the still-unsupported `DDW` directive (XC8-1817).

**Next chapter:** you've written everything in one file so far. Chapter 13 introduces **macros**
(`MACRO`/`ENDM`) to package repeated instruction sequences, and **`GLOBAL`/`EXTRN`** to split a
program across multiple source files and link them together — the first step toward organizing a
real, growing project.
