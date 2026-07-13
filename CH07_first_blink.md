# Chapter 7 — Your First Blink

> **Reference keys:** `[DS17146]`, `[CNANO]`, and `[UG]` in `REFERENCES.md`.

> **Scope and validation:** PIC16F17146 Curiosity Nano; XC8 4.00 with PIC16F1xxxx DFP 1.31.465. Example: source- and build/link-verified; bench blink not yet hardware-verified.

> **What you'll build:** the "hello, world" of hardware — a physically blinking LED on the
> PIC16F17146 Curiosity Nano. You'll configure a real pin, drive it, and add a delay so your
> eye can see it. This is the chapter where the chip finally *does something in the world*.

---

## 7.1 The idea: direction, latch, and input mode

Every I/O pin on this chip is controlled by a small stack of registers. Two registers actually
control a simple digital output; a third controls the pin's input buffer. The data sheet lists all
eight port-control registers in §16.1; these are the ones that matter today:

| Register | Job | The rule (data sheet) |
|---|---|---|
| `TRISx` | **direction** | bit = 0 → **output**; bit = 1 → input (§16.4) |
| `ANSELx` | **input-buffer mode** | bit = 1 → analog input (reset default); bit = 0 → **digital input** (§16.5) |
| `LATx` | **output value** | write here to drive the pin high/low (§16.3) |

The `x` is the port letter — `TRISC`, `ANSELC`, `LATC` for Port C, and so on. Three things to
burn into memory right now, because each one is a classic first-blink failure:

1. **TRIS is backwards from what you'd guess.** `0` means output. Mnemonic: TRIS bit = "is it an
   inpu**t**? 1 = yes." Clearing the bit lets the pin drive out (§16.4).
2. **Pins wake up with their input buffers in analog mode.** An analog-mode pin reads as zero
   through `PORTx` and cannot serve as a digital peripheral input. But the data sheet is explicit:
   `ANSELx` has **no effect on digital output functions**; with TRIS clear, the latch still drives
   the pin (§16.5). We clear ANSEL so RC1 is fully defined as digital GPIO and can be read later,
   not because the LED output requires it.
3. **Drive `LAT`, never `PORT`.** Writing the pin's value through `PORTx` invites a
   read-modify-write glitch; "as a general rule, output operations to a port must use the LAT
   register" (§16.3). Writing `LATx` sets the same pin, safely.

> **What about PPS?** You may have heard the PIC16F17146 needs *Peripheral Pin Select* to use a
> pin. Not for this. Every pin's output defaults to its own data latch after Reset (PPS output
> code `0x00 = LATxy`, data sheet §16.12 and Table 18-2), so driving `LATC` reaches the pin with
> **no PPS setup at all**. PPS matters when you route a *peripheral* (like a PWM or UART) onto a
> pin — we'll use it then. A software-driven LED needs none of it.

---

## 7.2 Which pin? Meet LED0

On the PIC16F17146 Curiosity Nano, the yellow user LED (**LED0**) is wired to pin **RC1**
(Curiosity Nano user guide DS50003388B §4.2.1). One more crucial detail from that same section:

> "Driving the connected I/O line to GND can also activate the LED."

That means LED0 is **active-low**: the LED lights when RC1 is driven **low**, and turns off when
RC1 is **high**. So in our code, `bcf LATC,1` (drive low) = **LED on**, and `bsf LATC,1` (drive
high) = **LED off**. Don't let the inversion trip you up — if your first build seems "on when it
should be off," this polarity is why.

*(No Curiosity Nano? Any LED from a GPIO through a ~330 Ω resistor to ground works; then the
logic is normal — high = on. Adjust the two bit instructions accordingly.)*

---

## 7.3 Configuring the pin, step by step

We set up RC1 in three moves. First select digital input mode, then preload the output latch **while
the pin is still an input**, and only then enable the output driver. Preloading avoids a brief active-low
LED pulse: after Reset the latch is zero, and clearing TRIS before writing LAT would momentarily
drive RC1 low.

Each access uses `BANKSEL` to select the register's bank and `BANKMASK()` to put only the
register's within-bank address into the instruction. Chapter 8 explains both; using the pair now
keeps the default linker's overflow checks strict.

```asm
    BANKSEL ANSELC
    bcf     BANKMASK(ANSELC),ANSELC_ANSC1_POSN ; RC1 digital input mode
    BANKSEL LATC
    bsf     BANKMASK(LATC),LATC_LATC1_POSN     ; preload LED OFF (high)
    BANKSEL TRISC
    bcf     BANKMASK(TRISC),TRISC_TRISC1_POSN  ; enable RC1 output last
```

After these three writes RC1 is a digital output, driven high, LED dark — without an output glitch.

---

## 7.4 Making it blink: the delay

If we just toggled the pin in a tight loop it would switch millions of times a second — far too
fast to see. We need to *waste time* between toggles. The classic tool is a **nested
decrement-and-skip loop** built from `DECFSZ` ("decrement f, skip next instruction if it hit
zero," data sheet §41 Table 41-3):

```asm
delay:
    movlw   0xFF
    movwf   d1              ; outer counter = 255
d_outer:
    movlw   0xFF
    movwf   d2              ; inner counter = 255
d_inner:
    decfsz  d2,f            ; d2--, skip the goto when d2 reaches 0
    goto    d_inner         ; ...otherwise keep looping
    decfsz  d1,f            ; d1--, skip when d1 reaches 0
    goto    d_outer
    return
```

**How long is that?** One instruction cycle is **four oscillator cycles** (data sheet §41). Our
Chapter 5 config selects `FOSC = 1 MHz`, so one instruction cycle is nominally **4 µs**. Counting
the one-cycle decrements, two-cycle `goto` instructions, two-cycle taken skips, setup, and
two-cycle `return`, the routine body takes 196,098 instruction cycles. The `call` adds two more:
196,100 × 4 µs = **0.7844 second** per call. Including the few LED and loop instructions, the
nominal full on/off period is about **1.569 seconds** (about 0.637 Hz). Real timing follows the
internal oscillator's tolerance; this is a busy-wait, not a precision timer.

`d1` and `d2` are two bytes we'll keep in **common RAM** so the delay never has to think about
banks (Chapter 6's trick).

---

## 7.5 The whole program

Save as `blink.S`. This listing includes the complete Chapter 5 configuration so the hardware
clock and delay agree; if your selected DFP differs, re-audit the tokens as described there.

```asm
; ------------------------------------------------------------
;  blink.S  —  blink LED0 (RC1) on the PIC16F17146 Curiosity Nano
;  LED0 is active-low: drive RC1 low = ON, high = OFF.
; ------------------------------------------------------------

    PROCESSOR 16F17146
#include <xc.inc>

; --- Configuration Words: XC8 4.00 / PIC16F1xxxx_DFP 1.31.465 ---
    CONFIG "FEXTOSC = OFF"
    CONFIG "RSTOSC = HFINTOSC_1MHz"
    CONFIG "CLKOUTEN = OFF"
    CONFIG "CSWEN = ON"
    CONFIG "VDDAR = HI"
    CONFIG "FCMEN = ON"

    CONFIG "MCLRE = EXTMCLR"
    CONFIG "PWRTS = PWRT_64"
    CONFIG "LPBOREN = OFF"
    CONFIG "BOREN = NSLEEP"
    CONFIG "DACAUTOEN = OFF"
    CONFIG "BORV = LO"
    CONFIG "ZCD = OFF"
    CONFIG "PPS1WAY = ON"
    CONFIG "STVREN = ON"

    CONFIG "WDTCPS = WDTCPS_31"
    CONFIG "WDTE = OFF"
    CONFIG "WDTCWS = WDTCWS_7"
    CONFIG "WDTCCS = SC"

    CONFIG "BBSIZE = BB512"
    CONFIG "LVP = ON"
    CONFIG "BBEN = OFF"
    CONFIG "SAFEN = OFF"
    CONFIG "WRTAPP = OFF"
    CONFIG "WRTB = OFF"
    CONFIG "WRTC = OFF"
    CONFIG "WRTD = OFF"
    CONFIG "WRTSAF = OFF"

    CONFIG "CP = OFF"
    CONFIG "CPD = OFF"

; --- two delay counters in COMMON RAM (no banking needed) ----
    PSECT udata_shr
d1: DS  1
d2: DS  1

; --- reset entry point (chip starts at 0x0000, §9.1) ---------
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main

; --- main ----------------------------------------------------
    PSECT code
main:
    ; --- prepare RC1, preload OFF, then enable its output driver ---
    BANKSEL ANSELC
    bcf     BANKMASK(ANSELC),ANSELC_ANSC1_POSN
    BANKSEL LATC
    bsf     BANKMASK(LATC),LATC_LATC1_POSN
    BANKSEL TRISC
    bcf     BANKMASK(TRISC),TRISC_TRISC1_POSN

    ; --- blink forever ---
loop:
    bcf     BANKMASK(LATC),LATC_LATC1_POSN ; drive RC1 low  -> LED ON
    call    delay
    bsf     BANKMASK(LATC),LATC_LATC1_POSN ; drive RC1 high -> LED OFF
    call    delay
    goto    loop

; --- nominal 0.7844 s busy-wait delay at FOSC = 1 MHz --------
delay:
    movlw   0xFF
    movwf   d1
d_outer:
    movlw   0xFF
    movwf   d2
d_inner:
    decfsz  d2,f
    goto    d_inner
    decfsz  d1,f
    goto    d_outer
    return

    END     resetVec
```

`TRISC` and `LATC` are both in bank 0, so the final `BANKSEL TRISC` leaves the correct bank selected
for `LATC`. The delay counters are in common RAM and `delay` never changes BSR, so that bank-state
assumption holds across both calls. If a future callee or edit can change BSR, reselect `LATC` before
accessing it; bank state is part of a routine's contract, not a global guarantee.

---

## 7.6 Build & run it

Set `DFP` as shown in Chapter 3, then build with the default strict operand-overflow policy. The
source's `BANKMASK()` operands make the intended truncation explicit, so no fixup-warning or
fixup-ignore option is needed:

```
pic-as -mcpu=16f17146 -mdfp="$DFP" -Wl,-presetVec=0h \
       -Wa,-a -Wl,-Map=blink.map blink.S
```

**On the Curiosity Nano:** create the project for **PIC16F17146** (Chapter 3), add `blink.S` with
the same DFP and the `-presetVec=0h` linker option, build (**Ctrl+Shift+B**), and program the board
over USB via the MPLAB® Debugger (Chapter 18). The yellow LED0 should complete one on/off cycle
about every 1.57 seconds.

**On the simulator (no board):** run to the loop, put a Watch on `LATC`, and step — you'll see
bit 1 of `LATC` flip between the `bcf` and `bsf`. (You can't *see* an LED in the simulator, but
you can watch the latch that would drive it.)

---

## 7.7 What just happened

You reached out of the CPU and touched the physical world. The safe output sequence was: choose
the input-buffer mode with **ANSEL**, preload the inactive level in **LAT**, then enable the output
driver with **TRIS**. The loop changed LAT only after the driver was active, with a delay between
changes so they were visible.

You also used four instruction *categories* for real: literal (`movlw`), byte (`movwf`),
bit (`bcf`/`bsf`), and control (`call`/`goto`/`return`) — the backbone of the whole 50-instruction
set.

---

## 7.8 Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| LED stays off | `TRISC` bit left set (pin is an input) | clear the masked `TRISC1` bit to enable the output driver (§16.4) |
| LED on when you expect off (and vice-versa) | LED0 is active-low | clear the masked `LATC1` bit for ON; set it for OFF (CNANO §4.2.1) |
| A later read of RC1 is always zero even while the output is high | `ANSELC1` was left in analog input mode | clear `ANSELC1`; ANSEL affects the input buffer, not the output driver (§16.5) |
| Output behaves unpredictably after other port operations | code used read-modify-write on `PORTC` | write or modify `LATC` instead (§16.3) |
| Build error: fixup overflow on `ANSELC` | high-bank operand was not masked | keep `BANKSEL ANSELC` and use `BANKMASK(ANSELC)` as the instruction operand |
| Loop stops toggling after one pass | an errant `BANKSEL` inside the loop moved the bank off bank 0 | keep the loop touching only `LATC`; select its bank once before the loop |

(Appendix C decodes the exact assembler/linker message text.)

---

## 7.9 Try it yourself

1. **Change the rate.** In `delay`, change the outer-counter load from `0xFF` to `0x80`.
   Predict, then observe, that both on-time and off-time become roughly half as long.
2. **Make a heartbeat.** Copy `delay` to `delay_short`, use `0x40` for its outer count, and call
   the short version after LED ON while retaining the long version after LED OFF.
3. **Blink a second pin.** Pick another free Port C pin routed to the edge connector, wire an
   external LED + resistor, configure it exactly like RC1, and blink both — one on while the
   other is off. (Watch the polarity: your external LED to ground is active-*high*.)
4. **Prove the ANSEL distinction.** Comment out the masked `bcf ANSELC,...` line. The physical
   LED still blinks because ANSEL does not affect output, but a simulator Watch/read of `PORTC`
   bit 1 reports zero. Restore the line before using RC1 as a digital input.
5. **Read the switch (stretch).** SW0 is on RC0 (CNANO §4.2.2) with no external pull-up. Keep
   `TRISC0` set for input, clear `ANSELC0`, enable `WPUC0` (§16.6), and read `PORTC` bit 0.
   We'll do inputs properly later; try "LED on only while the button is pressed."

---

## 7.10 Reference bridge

- **Data sheet §16 "I/O Ports"** — every port register (`TRIS`, `LAT`, `ANSEL`, `WPU`, `INLVL`,
  `SLRCON`, `ODCON`), including the output and input-buffer distinctions used here.
- **Data sheet §41 "Instruction Set Summary"** — the full 50 instructions; you've now used
  `movlw`, `movwf`, `bcf`, `bsf`, `decfsz`, `call`, `return`, `goto`.
- **Curiosity Nano guide §4.2** — the board's LED, switch, and crystal connections.

**Next chapter (and Part III):** you've been typing `BANKSEL` and `BANKMASK()` as a verified pair.
Chapter 8 finally opens up **data memory banking** — what both forms do, why the chip needs banks,
and how to place and reach your own variables anywhere in RAM.
