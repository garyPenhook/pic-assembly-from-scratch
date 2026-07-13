# Chapter 15 — Moving Up a Core: PIC18® Interrupts

> **Reference keys:** `[DS18Q43]`, `[ER18Q43]`, `[DFP18Q]`, `[UG]`, and `[EE]` in `REFERENCES.md`.

> **What you'll learn:** how your hard-won PIC16F17146 skills transfer *up* to the current-
> generation **PIC18-Q** family — where the instruction set is wider, data memory is easier to
> reach, and interrupts are **vectored and prioritized** instead of funneled through a single
> address. We anchor on a modern **PIC18F57Q43** (the same VIC design used across today's Q-series
> parts), and every example here is built and verified.

> **A note on sourcing.** The book's main target is the PIC16F17146. This chapter's device is the
> **PIC18F57Q43**; its facts below are confirmed against the PIC18F27/47/57Q43 data sheet
> **DS40002147H** (especially §11), silicon errata **DS80000870M**, and PIC18F-Q DFP
> **1.30.487**. The listings assemble without source diagnostics on `pic-as` v4.00. **When you
> build for a *different* PIC18, re-confirm its
> vectors and config bits against that device's data sheet** — the confirm-before-you-code habit
> from Chapter 5 never stops.

---

## 15.1 Why move up — and what stays the same

The PIC18 core is the top of the 8-bit PIC line: a **16-bit-wide instruction set**, more
instructions, an expanded register set, and (on modern parts) extended data memory and a vectored
interrupt controller (User's Guide §2.1). The reassuring news first: **most of the workflow you
learned still applies.** Source files, psects, `CONFIG`, `#include <xc.inc>`, `W`, file registers,
`BANKSEL`, labels, macros, `GLOBAL`/`EXTRN` — all identical. What changes is a handful of
core-specific details. Learn those and you can read and write PIC18 assembly today.

---

## 15.2 The assembler-level differences

These are device-independent — they apply to *any* PIC18 — and you can rely on them from the XC8
guides:

| Topic | Mid-range (16F17146) | PIC18 |
|---|---|---|
| Program memory addressing | word-addressable → `delta=2` | **byte-addressable → `delta=1`** (default) (User's Guide §4.9.48.4) |
| Code alignment | none (`reloc=1`) | **word-aligned → `reloc=2`** on code psects (§4.9.48.16; Emb Eng §3.6) |
| Bank-free RAM | 16 B common RAM | **Access bank** — a larger fast region via `udata_acs` (Emb Eng §3.5) |
| Move memory→memory | not available | **`movff` / `movffl`** — copy across ordinary PIC18 data memory, no bank select (§4.1.5) |
| Program paging | `PAGESEL` needed | `PAGESEL` **accepted but does nothing** — PIC18 handles it differently (§4.1.2) |
| Instruction operands | `,w`/`,f` | adds an **access operand** `,c`/`,a` (access bank) vs `,b` (banked) (§4.1.1) |

### The `delta`/`reloc` swap
This trips up everyone porting code. On mid-range you wrote `class=CODE,delta=2`. On PIC18 you
write `class=CODE,reloc=2` — **because PIC18 program memory is byte-addressable** (so `delta`
stays at its default of 1) but **instructions must be word-aligned** (so `reloc=2`):

```asm
PSECT resetVec,class=CODE,reloc=2      ; PIC18: reloc=2, NOT delta=2
resetVec:
    goto start
```

### The Access bank — PIC18's "common RAM," bigger
On mid-range you dodged banking with 16 bytes of common RAM. PIC18 gives you a larger **Access
bank** reached without `BANKSEL`. You place variables there with the `udata_acs` psect and use the
access operand `,c` (or `,a`) on instructions (Emb Eng §3.5):

```asm
PSECT udata_acs
max:  DS 1
tmp:  DS 1
...
    clrf  max,c            ; ',c' = access bank, no BANKSEL needed
```

### `movff` — copy anywhere to anywhere
The single most convenient PIC18 instruction: `movff src,dst` moves one file register to another
**across ordinary PIC18 data memory, no bank selection at all** (User's Guide §4.1.5). On devices
with extended data memory, the assembler can select the longer `movffl` form. The mid-range
`movf`/`movwf` two-step through W becomes one instruction:

```asm
    movff  PORTA,tmp       ; tmp = PORTA, W untouched, no banking
```

---

## 15.3 PIC18 interrupts: two models

Mid-range gave you exactly one interrupt vector (0x0004). PIC18 offers **two priority levels** and,
on modern parts, a **vectored interrupt controller (VIC)**. Which model you get is chosen by the
**`MVECEN`** configuration bit (data sheet §11.3):

- **Legacy mode (`MVECEN = OFF`)** — two *fixed* vectors. The data sheet is explicit: `IVTBASE`
  defaults to **0x000008**, so the **high-priority vector is at 0x0008** and the **low-priority
  vector is at 0x0018** (eight instruction words higher) (§11.3.3). You write one ISR per priority
  level at those addresses.
- **Vectored mode (`MVECEN = ON`)** — a **table** of vectors, **one ISR per interrupt source**. The
  hardware reads the table and jumps straight to the right handler, so you don't poll flags to find
  the source. This is the modern approach and what we use below.

In vectored mode the hardware computes each ISR address from the table (§11.3.3):

> **Interrupt Vector Address = IVTBASE + (2 × Vector Number).**

Every interrupt source has a fixed **vector number**. On the PIC18F57Q43, **Timer0 is vector number
31** (verified from the device's interrupt-source table). Enabling priorities uses the **`IPEN`**
bit (in `INTCON0`), and the global enable splits into **`GIEH`** (high) and **`GIEL`** (low).

---

## 15.4 The vectored interrupt controller, by example

Here is a complete, build-verified PIC18F57Q43 timer-interrupt program — the PIC18 counterpart to
Chapter 14's blink. Timer0 overflows, the VIC vectors to our ISR, and the ISR toggles a pin.

```asm
    PROCESSOR 18F57Q43
#include <xc.inc>

    CONFIG "FEXTOSC = OFF"
    CONFIG "RSTOSC = HFINTOSC_1MHZ"   // internal osc, 1 MHz
    CONFIG "CLKOUTEN = OFF"
    CONFIG "PR1WAY = ON"
    CONFIG "CSWEN = ON"
    CONFIG "FCMEN = ON"
    CONFIG "MCLRE = EXTMCLR"
    CONFIG "PWRTS = PWRT_OFF"
    CONFIG "MVECEN = ON"              // vectored interrupt controller
    CONFIG "IVT1WAY = ON"
    CONFIG "LPBOREN = OFF"
    CONFIG "BOREN = SBORDIS"
    CONFIG "BORV = VBOR_2P45"
    CONFIG "ZCD = OFF"
    CONFIG "PPS1WAY = ON"
    CONFIG "STVREN = ON"
    CONFIG "LVP = ON"
    CONFIG "XINST = OFF"              // XC8 requires the extended set off
    CONFIG "WDTCPS = WDTCPS_31"
    CONFIG "WDTE = OFF"
    CONFIG "WDTCWS = WDTCWS_7"
    CONFIG "WDTCCS = SC"
    CONFIG "BBSIZE = BBSIZE_512"
    CONFIG "BBEN = OFF"
    CONFIG "SAFEN = OFF"
    CONFIG "DEBUG = OFF"
    CONFIG "WRTB = OFF"
    CONFIG "WRTC = OFF"
    CONFIG "WRTD = OFF"
    CONFIG "WRTSAF = OFF"
    CONFIG "WRTAPP = OFF"
    CONFIG "CP = OFF"
    GLOBAL __Livt

PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto    start

; Timer0 is interrupt vector number 31 on PIC18F57Q43.
PSECT ivt,class=CODE,reloc=2,ovrld
ivtbase:
    ORG     31*2
    DW      tmr0Isr shr 2

PSECT textISR,class=CODE,reloc=4
tmr0Isr:
    bcf     BANKMASK(PIR3),PIR3_TMR0IF_POSN,c
    movlw   1
    xorwf   BANKMASK(LATA),f,c
    retfie  f

PSECT code
start:
    ; IVTLOCK/IVTBASE are in bank 4, not the Q43 Access Bank.
    bcf     BANKMASK(INTCON0),INTCON0_GIE_POSN,c
    BANKSEL IVTLOCK
    movlw   0x55
    movwf   BANKMASK(IVTLOCK),b
    movlw   0xAA
    movwf   BANKMASK(IVTLOCK),b
    bcf     BANKMASK(IVTLOCK),IVTLOCK_IVTLOCKED_POSN,b
    movlw   low highword __Livt
    movwf   BANKMASK(IVTBASEU),b
    movlw   high __Livt
    movwf   BANKMASK(IVTBASEH),b
    movlw   low __Livt
    movwf   BANKMASK(IVTBASEL),b
    movlw   0x55
    movwf   BANKMASK(IVTLOCK),b
    movlw   0xAA
    movwf   BANKMASK(IVTLOCK),b
    bsf     BANKMASK(IVTLOCK),IVTLOCK_IVTLOCKED_POSN,b

    BANKSEL ANSELA             ; RA0 as a digital output
    clrf    BANKMASK(ANSELA),b
    clrf    BANKMASK(LATA),c
    clrf    BANKMASK(TRISA),c

    ; Timer0 registers are in bank 3.
    BANKSEL T0CON0
    clrf    BANKMASK(T0CON0),b
    bsf     BANKMASK(T0CON0),T0CON0_MD16_POSN,b
    movlw   0x40
    movwf   BANKMASK(T0CON1),b
    bsf     BANKMASK(IPR3),IPR3_TMR0IP_POSN,b
    bcf     BANKMASK(PIR3),PIR3_TMR0IF_POSN,c
    bsf     BANKMASK(PIE3),PIE3_TMR0IE_POSN,c
    bsf     BANKMASK(T0CON0),T0CON0_EN_POSN,b
    bsf     BANKMASK(INTCON0),INTCON0_IPEN_POSN,c
    bsf     BANKMASK(INTCON0),INTCON0_GIEH_POSN,c
idle:
    goto    idle
    END     resetVec
```

Build it, linking the vector table at the legacy base 0x8:

```
pic-as -mcpu=18F57Q43 -mdfp=/path/to/Microchip.PIC18F-Q_DFP/1.30.487/xc8 \
  -Wl,-presetVec=0h -Wl,-pivt=08h -Wa,-a -Wl,-Map=vic.map vic.S
```

Five PIC18-specific ideas in that program:

1. **A vector *table*, not a fixed address.** Each source has a slot; Timer0's is #31. `ORG 31*2`
   places the entry at the right offset *within the table* (each vector is 2 bytes). This is the one
   place `ORG` is genuinely recommended — and it's still psect-relative, exactly as Chapter 10
   warned.
2. **`DW tmr0Isr shr 2`.** The table stores the ISR address **shifted right by 2**, because the
   hardware forms the jump target by shifting left — which is *why* the ISR sits on a 4-byte
   boundary (`reloc=4`).
3. **`retfie f` — the fast return.** The Q43 saves WREG, STATUS, and BSR on its fast stack; the
   `f` operand restores them on the way out (data sheet §9.1.3.4; User's Guide §4.1.6). Protect
   any additional registers or shared multi-byte state that an ISR changes; the fast return is
   not a blanket save of every peripheral or file register.
4. **`IVTBASE` locates the table.** The hardware finds the table via the `IVTBASE` registers, loaded
   through the device-defined `0x55`/`0xAA` unlock sequence, using the linker
   symbol **`__Livt`** (our table's address). The table is *relocatable*; you could keep several and
   switch them at runtime (data sheet §11.3.1).
5. **`ovrld` on the table psect.** Vector entries from different files overlay into one table at the
   right offsets regardless of assembly order — that's how a big project adds ISRs incrementally.

> **Verified.** This program assembles on `pic-as` v4.00 with the PIC18F-Q DFP, and the map file
> shows the `ivt` psect linked at **address 0x8** with length **0x40** (`__Livt = 0x8`) — exactly
> the table layout the vector-number math predicts (31 × 2 + 2 = 0x40).

The explicit `BANKSEL`/`BANKMASK` operands matter on the Q43. Its Access Bank maps physical GPR
`0x500–0x55F` and SFR `0x460–0x4FF`; `IVTLOCK`/`IVTBASE` (`0x459–0x45F`) and Timer0
(`0x31A–0x31B`) are outside it (data sheet §9.4.2 and DFP 1.30.487). Marking those registers
`,c` would address the wrong Access Bank location or trigger a fixup diagnostic.

---

## 15.5 What actually changed, at a glance

Coming from Chapter 14, here's the whole delta:

| | 16F17146 (mid-range) | PIC18F57Q43 (PIC18) |
|---|---|---|
| Interrupt vector | single, fixed at 0x0004 | vector **table** (`MVECEN=ON`), or dual fixed vectors 0x08/0x18 (`MVECEN=OFF`) |
| Priorities | none | high / low (`IPEN`, `GIEH`/`GIEL`) |
| Find the source | poll flag bits in the ISR | hardware vectors straight to the ISR |
| Context save | automatic (§12.9) | Q43 fast stack saves WREG/STATUS/BSR; `retfie f` restores them |
| Acknowledge source | follow the peripheral rule | TMR0IF must be cleared in software |
| Code psect flags | `class=CODE,delta=2` | `class=CODE,reloc=2` |
| Escape banking | common RAM (`udata_shr`) | Access bank (`udata_acs`) + `movff` |

Every ISR must acknowledge its source exactly as that peripheral specifies. For this example,
that means clearing `PIR3.TMR0IF` in software; do not generalize that operation to flags that are
hardware-cleared or read-only on another peripheral.

---

## 15.6 What just happened

Moving to a modern PIC18 keeps 90% of what you know and swaps a few core-specific details: a
byte-addressable program memory (`reloc=2`, not `delta=2`), a roomier Access bank plus the
whole-memory `movff`, and — the headline — a **vectored, prioritized interrupt system** where a
table of ISR addresses (found via `IVTBASE`, using **Address = IVTBASE + 2×vector#**) replaces the
single 0x0004 vector. The habits stay identical: keep the reset code tiny, let the hardware save
context, and acknowledge each interrupt source exactly as its peripheral requires.

---

## 15.7 Common mistakes (porting from mid-range)

| Symptom | Cause | Fix |
|---|---|---|
| Code psect won't align / build error on PIC18 | used `delta=2` (a mid-range habit) | PIC18 code uses `class=CODE,reloc=2` (§4.9.48) |
| ISR runs from the wrong address | ISR psect not `reloc=4`, or forgot `shr 2` in the table | ISR on a 4-byte boundary; store `DW isr shr 2` |
| Interrupts never vector correctly | `IVTBASE` not loaded / unlock sequence skipped | load `IVTBASE` from `__Livt` via the 0x55/0xAA unlock (§11.3.1) |
| Build error mentioning the extended instruction set | `XINST` left on | set `CONFIG "XINST = OFF"` (XC8 requires it off) |
| Used the wrong vector number | assumed a source's IRQ number | confirm it in your device's interrupt-source table (Timer0 = 31 on the Q43) |
| Interrupt re-fires forever | TMR0 flag was not cleared | clear `PIR3.TMR0IF`; use each peripheral's documented acknowledge rule |

---

## 15.8 Try it yourself

1. **Diff the two blinks.** Put Chapter 14's `tmr0blink.S` beside the Q43 program above and list
   every line that differs. Sort each difference into "assembler syntax" vs. "hardware/interrupt
   model."
2. **Read the map.** Build the example and open `vic.map`; find the `ivt` psect at link address
   **0x8** and confirm its length is **0x40** (the gap the `ORG 31*2` created plus the 2-byte
   entry).
3. **Add a second vector.** Add a second source's ISR at its own table slot (another `ORG n*2` /
   `DW isr shr 2` in the `ovrld` `ivt` psect, using that source's vector number) and confirm both
   vectors coexist in the map.
4. **Legacy mode.** Set `MVECEN = OFF`, put an ISR at 0x0008, and confirm from the data sheet
   (§11.3.3) why that address is the high-priority vector.

---

## 15.9 Reference bridge

- **PIC18F57Q43 data sheet §11 "Vectored Interrupt Controller"** — `IVTBASE`, the address
  calculation (§11.3.3), priorities, and the full interrupt-source/vector-number table.
- **PIC18F27/47/57Q43 silicon errata DS80000870M** — revision-specific restrictions to recheck
  before hardware deployment; revision M adds no VIC/TMR0 restriction to this example.
- **Embedded Engineers guide §3 / §8** — Microchip's worked PIC18 assembly examples (Access bank,
  `movff`, `reloc=2`, the `IVTBASE` unlock).
- **User's Guide §4.1** — PIC18 instruction deviations: access operands, `movff`/`movffl`,
  `retfie f`, and why `PAGESEL` is a no-op.

**Next chapter:** interrupts introduced the idea of routines with their own private state.
Chapter 16 tackles **the compiled stack** — how assembly on PIC allocates local variables for
subroutines (there's no hardware data stack), why the linker overlays them, and how to declare a
routine's locals so several functions can safely share memory.
