# Chapter 14 — Interrupts on the PIC16F17146

> **Reference keys:** `[DS17146]`, `[ER17146]`, `[UG]`, and `[DFP17146]` in `REFERENCES.md`.

> **Scope and validation:** PIC16F17146, enhanced mid-range core; XC8 4.00 with PIC16F1xxxx DFP 1.31.465. Examples: source- and build/link-verified; simulator/hardware runtime not verified.

> **What you'll build:** a blinking LED again — but this time **your main code does nothing**. A
> hardware timer (TMR0) overflows on its own, interrupts the CPU, and a short service routine
> toggles the LED. You'll learn how an interrupt hijacks the processor, why the PIC16F17146 saves
> your registers *for you*, and the one line you must never forget (clearing the flag).

---

## 14.1 The idea: let hardware interrupt you

Every program so far has *polled* — spun in a loop asking "is it time yet?" That wastes the CPU
and scales badly once you have several things to watch. An **interrupt** flips the model: you set
up a hardware event, go do something else (or nothing), and when the event fires the processor
**automatically stops**, jumps to a service routine, runs it, and resumes exactly where it left
off — as if the interruption never happened.

On the PIC16F17146, here's precisely what the hardware does when an enabled interrupt fires while
interrupts are globally on (data sheet §12.5):

1. finishes/flushes the current instruction,
2. **clears GIE** (so the ISR isn't itself interrupted),
3. pushes the current PC onto the stack,
4. **automatically saves your critical registers** to shadow registers (§12.9),
5. loads the PC with the **interrupt vector, 0x0004**.

Your Interrupt Service Routine (ISR) runs, and a **`RETFIE`** instruction reverses it all: pops
the return address, restores the saved registers, and sets GIE back — resuming your main code
untouched (§12.5).

> **Remember the vectors (Chapter 4).** Reset sends the chip to **0x0000**; an interrupt sends it
> to **0x0004** (data sheet §9.1, §12.5). That's why we've always kept the reset code tiny and
> jumped away — to leave 0x0004 free for the ISR.

---

## 14.2 Turning an interrupt on

Three switches control whether an interrupt reaches the CPU (data sheet §12.5):

- **GIE** — Global Interrupt Enable, `INTCON` bit 7. The master switch (§12.10.1).
- **PEIE** — Peripheral Interrupt Enable, `INTCON` bit 6. A second gate for *most* peripherals.
- **The specific enable bit** — e.g. `TMR0IE` for the Timer0 interrupt.

`INTCON` is a **core register** — it appears at offset 0x0B in *every* bank (Chapter 8), so you
can touch GIE and PEIE without any `BANKSEL`.

### The PEIE subtlety worth knowing
The generic rule is "GIE + PEIE + the specific enable." But there's an exception the data sheet is
explicit about (§12.10.2, PIE0 note): the interrupt sources in the **PIE0** register — `TMR0IE`,
`IOCIE`, `INTE` — **do not require PEIE**. Only sources in PIE1 through PIE6 need it. Since our
timer's enable (`TMR0IE`) lives in PIE0, we enable it with just **GIE + TMR0IE** — no PEIE
needed. (Setting PEIE anyway would be harmless, but it's good to know why we don't have to.)

| Register | Holds | Needs PEIE? |
|---|---|---|
| `PIE0` (`TMR0IE`, `IOCIE`, `INTE`) | core-ish sources | **No** (§12.10.2) |
| `PIE1`–`PIE6` (all other peripherals) | peripheral sources | **Yes** (§12.10.8) |

---

## 14.3 The gift of automatic context saving

On older, *classic* mid-range PICs, the first thing every ISR had to do was manually copy `W` and
`STATUS` into temporary variables (and restore them before returning) — because the ISR would
clobber them and wreck the interrupted code. The Embedded Engineers guide (§7.3) shows that
"manual context switch" dance.

**You don't need it here.** The enhanced mid-range core saves and restores your context *in
hardware*. On interrupt entry it automatically stashes, and on `RETFIE` restores, these registers
(data sheet §12.9):

- `WREG`
- `STATUS` (except the TO and PD bits)
- `BSR`
- the `FSR` registers
- `PCLATH`

They live in **shadow registers** in Bank 63, and are readable/writable if you ever need them.
The practical upshot is liberating: **inside your ISR you can use W, change banks with `BANKSEL`,
and alter STATUS — the hardware restores the listed CPU context.** No save/restore boilerplate is
needed for those registers. This does **not** restore application RAM, peripheral registers, table
state, or any other temporary you modify. Save other machine state when required, and give every
RAM object shared with `main` an explicit ownership/atomicity rule.

---

## 14.4 The rule you must never break: clear the flag

When TMR0 overflows it sets its flag bit, **`TMR0IF`** (`PIR0` bit 5). That flag is what triggers
the interrupt — and the data sheet says it "must be cleared by software" (§12.10.9). If your ISR
doesn't clear it, the instant you `RETFIE` and re-enable interrupts, the still-set flag fires the
interrupt *again*, immediately, forever. Your program appears frozen inside the ISR.

**Every ISR must acknowledge the source it handled at the data-sheet-specified point, and its flag
must be clear before exit.** For TMR0 the acknowledgement is simply clearing `TMR0IF`, and doing it
early is appropriate:

```asm
    BANKSEL PIR0
    bcf     BANKMASK(PIR0),5     ; clear TMR0IF - or the interrupt re-fires endlessly
```

(The flag is a *request* bit and gets set by hardware regardless of the enable bits — so you also
clear it once *before* enabling the interrupt, to start from a clean slate. Other peripherals can
require a read, write, or ordered sequence instead of a simple `bcf`; always use that peripheral's
chapter and errata.)

### One vector means you must dispatch

Every interrupt source on this device reaches the same 0x0004 vector. This example enables only
TMR0, so the ISR can service it directly. Once you enable more than one source, qualify a request
with both its flag and its enable bit, dispatch all enabled pending sources deterministically, and
decide what happens if several are pending together. Keep every path bounded — no busy waits or
unbounded loops inside an ISR.

Interrupts also create concurrency. An 8-bit load/store is indivisible on this core, but a multi-byte
value shared between `main` and the ISR is not read or written atomically as a whole. Use a brief
GIE-masked critical section, a stable double-read, or a single-writer handoff protocol rather than
assuming the automatic context save protects shared RAM.

---

## 14.5 Setting up TMR0 to overflow periodically

We'll run Timer0 as a free-running 16-bit counter off the system clock, so it rolls over 0xFFFF →
0x0000 at a steady rate and sets `TMR0IF` each time (data sheet §22). Two control registers:

- **`T0CON1`** — clock source and prescaler. We pick `CS = 010` (**FOSC/4**), `ASYNC = 0`
  (synchronous), `CKPS = 0000` (**1:1** prescale). That's `0b0100_0000` = **0x40** (§22.5.2).
- **`T0CON0`** — enable and mode. We set `EN = 1` (on) and `MD16 = 1` (**16-bit**), postscaler
  `OUTPS = 0000` (1:1). That's `0b1001_0000` = **0x90** (§22.5.1).

**How fast does it overflow?** Our Chapter 5 config runs the chip at **1 MHz**, so FOSC/4 =
**250 kHz**. A 16-bit counter overflows every 65536 counts: 65536 ÷ 250000 ≈ **0.26 s**. So the
LED toggles about every quarter-second — a brisk ~1.9 Hz full blink cycle. Increase `CKPS`
(prescaler) to slow it down. Configure `T0CON1` and the disabled mode value in `T0CON0` first,
clear the pending flag, enable the source, then write `T0CON0 = 0x90` to start the timer and set GIE
last. Writing either Timer0 control register clears both prescaler and postscaler (§22.2.3–22.2.4).

---

## 14.6 The whole program — a timer-driven blink

```asm
; ------------------------------------------------------------
;  tmr0blink.S  —  LED blinks from a TMR0 interrupt; main() idles
; ------------------------------------------------------------

    PROCESSOR 16F17146
#include <xc.inc>
;  --- paste your Chapter 5 CONFIG block here ---

; --- reset vector (0x0000) -----------------------------------
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main

; --- interrupt vector (0x0004) -------------------------------
; Positioned at 0x0004 by:  -Wl,-pintVec=0004h
    PSECT intVec,class=CODE,delta=2
isr:
    ; NO manual context save needed - hardware did it (§12.9)
    BANKSEL PIR0
    bcf     BANKMASK(PIR0),5     ; clear TMR0IF (MUST do this)
    BANKSEL LATC
    movlw   0x02                 ; mask for RC1 (bit 1)
    xorwf   LATC,f               ; toggle the LED
    retfie                       ; restore context + re-enable GIE

; --- main ----------------------------------------------------
    PSECT code,delta=2
main:
    ; RC1 as a digital output (Chapter 7)
    BANKSEL ANSELC
    bcf     BANKMASK(ANSELC),1
    BANKSEL LATC
    bsf     LATC,1               ; preload LED off BEFORE making the pin an output
    BANKSEL TRISC
    bcf     TRISC,1

    ; TMR0: configure FOSC/4, 1:1 prescale, 16-bit, but leave it disabled
    BANKSEL T0CON1
    movlw   0x40
    movwf   BANKMASK(T0CON1)     ; CS=FOSC/4, ASYNC=0, CKPS=1:1
    movlw   0x10
    movwf   BANKMASK(T0CON0)     ; EN=0, MD16=1, OUTPS=1:1

    ; enable the TMR0 interrupt (PIE0 source -> no PEIE needed)
    BANKSEL PIR0
    bcf     BANKMASK(PIR0),5     ; clear any pending TMR0IF
    BANKSEL PIE0
    bsf     BANKMASK(PIE0),5     ; TMR0IE = 1
    BANKSEL T0CON0
    movlw   0x90
    movwf   BANKMASK(T0CON0)     ; start TMR0 only after its flag/enable are ready
    bsf     INTCON,7             ; GIE = 1 last (INTCON is mirrored in every bank)

idle:
    goto    idle                 ; main does nothing - the ISR runs the show

    END     resetVec
```

Build it, placing the ISR at the interrupt vector:

```
pic-as -mcpu=16f17146 -mdfp=/path/to/PIC16F1xxxx_DFP/VERSION/xc8 \
       -Wl,-presetVec=0h -Wl,-pintVec=0004h \
       -Wa,-a -Wl,-Map=tmr0blink.map tmr0blink.S
```

On the Curiosity Nano the yellow LED blinks ~1.9 Hz while `main` sits in `idle` doing absolutely
nothing — the timer and the ISR carry the whole workload. In the simulator, set a breakpoint on
`xorwf LATC,f` and watch it hit every ~65536 timer counts; note that `WREG` is preserved across
the interrupt even though the ISR loaded it with 0x02 (that's automatic context saving at work).

---

## 14.7 What just happened

You inverted the program's structure. Instead of `main` babysitting the LED, a hardware timer
raises an interrupt, the CPU vectors to **0x0004**, your ISR clears the flag and toggles the pin,
and `RETFIE` restores everything. You leaned on the enhanced mid-range core's **automatic context
saving** for the documented CPU registers, enabled the interrupt with just **GIE + TMR0IE** (no
PEIE, because TMR0 is a PIE0 source), and acknowledged TMR0 by clearing its flag before exit.
This is the foundation of every responsive embedded program — timers, buttons, serial bytes, all
serviced by interrupts while `main` does higher-level work.

---

## 14.8 Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| Program seems frozen, LED solid | ISR didn't clear `TMR0IF` — it re-fires instantly | `bcf BANKMASK(PIR0),5` in the ISR (§12.10.9) |
| Interrupt never fires | GIE or the specific enable not set | set `INTCON` GIE (bit 7) and `PIE0` TMR0IE (bit 5) (§12.5) |
| A *PIE1–6* peripheral interrupt never fires | forgot PEIE for that source | set `INTCON` PEIE (bit 6) — but PIE0 sources don't need it (§12.10.2) |
| Main code corrupted after an interrupt | ISR changed RAM/peripheral state not covered by the shadow registers | hardware restores only the §12.9 list; preserve every other shared temporary explicitly |
| ISR at wrong place / chip resets on interrupt | ISR psect not at 0x0004 | position it with `-Wl,-pintVec=0004h` (§12.5) |
| Wrong handler runs after adding another source | ISR assumes every entry is TMR0 | test each source's enable **and** flag; dispatch all pending enabled sources |
| Torn multi-byte value shared with `main` | interrupt occurred between byte accesses | use a short critical section, stable read, or single-writer handoff |
| Timer never overflows | wrote `T0CON0` enable before configuration, or EN=0 | configure while disabled; start with `T0CON0 = 0x90` after flag/enable setup (§22.2.3) |

(Appendix C decodes the exact message wording.)

---

## 14.9 Try it yourself

1. **Change the rate.** Set `CKPS` in `T0CON1` to 1:16 (`0b0100`, so `T0CON1 = 0x44`) and confirm
   the blink slows by ~16×. Compute the new period from FOSC/4.
2. **Do work in `main` too.** Replace the `idle` loop with a slow software counter in common RAM
   and watch it keep counting *while* the ISR blinks the LED — proof the two run "at once."
3. **Prove the flag rule.** Delete the `bcf BANKMASK(PIR0),5` from the ISR, run, and watch the
   program hang. Restore it. Feel why the rule is absolute.
4. **Confirm auto-save.** In the ISR, add `movlw 0x99` before `retfie`. Put a watch on `WREG`, set
   a breakpoint in `main` after the first interrupt, and confirm `WREG` is *not* 0x99 — the
   hardware restored it.

---

## 14.10 Reference bridge

- **Data sheet §12 "INT – Interrupts"** — the interrupt logic, `INTCON`/`PIE`/`PIR`, automatic
  context saving (§12.9), and the full enable sequence (§12.5).
- **Data sheet §22 "TMR0"** — Timer0 modes, clock/prescaler (`T0CON0`/`T0CON1`), and the overflow
  interrupt (§22.3.2).
- **Embedded Engineers guide §7** — the mid-range interrupt example, including the *manual*
  context switch you don't need on this enhanced core (useful when you meet classic PICs).
- **PIC16F17126/46 silicon errata DS80001009E** — checked for the target revision; it lists no
  TMR0 or automatic-context-save anomaly. Recheck the current errata for the silicon you actually
  program.

**Next chapter:** the PIC16F17146 has a single interrupt vector and saves context for you.
Chapter 15 moves *up* a core to **PIC18®**, whose interrupt system differs — vectored/prioritized
interrupts, an expanded register set, and its own conventions — so you can carry your interrupt
skills onto the larger 8-bit family.
