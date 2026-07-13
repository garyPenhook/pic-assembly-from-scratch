# Chapter 11 — Linear Memory & Larger Variables

> **Reference keys:** `[DS17146]` and `[UG]` in `REFERENCES.md`.

> **Scope and validation:** PIC16F17146, enhanced mid-range core; XC8 4.00 with PIC16F1xxxx DFP 1.31.465. Examples: source- and build/link-verified; runtime not hardware-verified.

> **What you'll build:** a **16-bit counter** — a variable too big for one 8-bit register — that
> counts from 0 all the way to 65535 and rolls over, incrementing correctly across the byte
> boundary. Then you'll meet the **FSR/INDF** indirect-addressing machinery and the **linear
> memory** view that lets a buffer grow past the 80-byte limit of a single bank.

---

## 11.1 The idea: bytes are small, so glue them together

WREG and each directly addressable data-memory register hold 8 bits — 0 to 255. Real programs
need bigger numbers: a millisecond timer, an ADC reading, a byte count. The answer is simple and
universal: **use more than one byte and treat them as one number.** A 16-bit value is just two
adjacent bytes — a **low byte** (bits 0–7) and a **high byte** (bits 8–15) — that you agree to read
together.

The only new skill is **carrying** between them. When the low byte counts past 0xFF it wraps back
to 0x00, and that overflow has to bump the high byte — exactly like the ones column rolling into
the tens column when you count past 9.

---

## 11.2 Incrementing a 16-bit value

Reserve two bytes and pick a convention. We'll put the low byte first (the common "little-endian"
choice): `counter` is the low byte, `counter+1` is the high byte.

```asm
    PSECT udata_shr          ; common RAM - no banking to worry about
counter:
    DS      2                ; 16-bit counter: counter = low, counter+1 = high
```

To add one to the whole 16-bit value, increment the low byte; **only if it wrapped to zero** do
we also increment the high byte. The clean way uses `INCFSZ` — "increment f, skip the next
instruction if the result is 0" (data sheet §41):

```asm
    incfsz  counter,f        ; low++  ; skip the goto if it just wrapped to 0x00
    goto    ctr_done         ; no wrap -> the high byte is unchanged, done
    incf    counter+1,f      ; low wrapped 0xFF->0x00, so carry into the high byte
ctr_done:
```

Trace it: if `counter` goes 0x34 → 0x35, it's non-zero, so `incfsz` does **not** skip — the
`goto ctr_done` runs and we're finished. If `counter` goes 0xFF → 0x00, the result **is** zero,
so `incfsz` skips the `goto`, falling through to `incf counter+1,f` — the carry. That's a full
16-bit increment in three instructions, and it never needs `BANKSEL` because both bytes live in
common RAM.

> **Why not just check the Carry flag?** `incf` sets the **Z** (zero) flag, not the Carry flag, so
> the natural test for "did it wrap?" is "did it become zero?" — which is exactly what `INCFSZ`
> tests in one instruction. (For *addition* of a value you'd use `ADDWF`/`ADDWFC`, which do use
> Carry; we'll meet those when we do real arithmetic.)

---

## 11.3 The whole program — count to 65535 and watch it

```asm
; ------------------------------------------------------------
;  count16.S  —  a 16-bit counter that rolls over at 65535
; ------------------------------------------------------------

    PROCESSOR 16F17146
#include <xc.inc>
;  --- paste your Chapter 5 CONFIG block here ---

    PSECT udata_shr
counter:
    DS      2                ; low byte = counter, high byte = counter+1

    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main

    PSECT code
main:
    clrf    counter          ; start at 0x0000 (common RAM: no BANKSEL)
    clrf    counter+1
loop:
    incfsz  counter,f        ; low++
    goto    loop             ; not zero -> keep going (high unchanged)
    incf    counter+1,f      ; low wrapped -> bump high byte
    goto    loop             ; ...and continue counting

    END     resetVec
```

Build it and watch the counter climb:

```
pic-as -mcpu=16f17146 -mdfp=/path/to/PIC16F1xxxx_DFP/VERSION/xc8 \
       -Wl,-presetVec=0h -Wa,-a -Wl,-Map=count16.map count16.S
```

In the simulator, put a Watch on both `counter` and `counter+1`. Step (or run with a breakpoint
on `incf counter+1,f`) and you'll see the low byte race 0x00→0xFF over and over, and each time it
rolls over, the high byte ticks up by one. Just before the 256th low-byte rollover the value is
0xFFFF; that rollover changes both bytes to 0 and wraps the whole value to 0x0000. That's a real
16-bit variable working.

*(Tip: set a breakpoint on the `incf counter+1,f` line — it only fires once every 256 counts, so
you see the carry happen without stepping 65,000 times.)*

---

## 11.4 Reaching data indirectly: the FSRs

A 16-bit *number* is two glued bytes. A 16-bit *pointer* is something more powerful. The enhanced
mid-range core has two **File Select Registers**, `FSR0` and `FSR1`, each a 16-bit
`FSRnH:FSRnL` pair (data sheet §7.3, §9.6). An FSR holds an **address**, and the matching
**`INDFn`** register is a window onto whatever that address points at:

> "The INDFn registers are not physical registers. Any instruction that accesses an INDFn register
> actually accesses the register at the address specified by the FSR." (data sheet §9.6)

So `FSR0` is a pointer and `INDF0` is "the byte it points to." This is how you walk arrays,
buffers, and tables without hard-coding each address. Because the FSR is 16 bits, it names a full
**65,536-location** space. The usable windows (plus reserved gaps) are (§9.6):

| FSR address range | Region | What it reaches |
|---|---|---|
| 0x0000–0x1FFF | **Traditional/Banked** | the absolute address of every SFR, GPR, and common byte (§9.6.1) |
| 0x2000–0x2FEF | **Linear Data Memory window** | up to bank 50's GPR blocks, laid end-to-end; unimplemented locations read 0 (§9.6.2) |
| 0x2FF0–0x6FFF | **Reserved** | do not use |
| 0x7000–0x70FF | **Data EEPROM** | read-only through `INDF`; writes use the NVM interface (§9.6.4) |
| 0x7100–0x7FFF | **Reserved** | do not use |
| 0x8000–0xFFFF | **Program Flash** | lower 8 bits of each program word, read-only through `INDF` (§9.6.3) |

### The auto-increment moves
The real power is that reading or writing through an FSR can *advance the pointer in the same
instruction* (data sheet §41, `MOVIW`/`MOVWI`):

| Syntax | Meaning |
|---|---|
| `moviw FSR0++` | W ← *FSR0, then FSR0++ (post-increment) |
| `movwi FSR0++` | *FSR0 ← W, then FSR0++ |
| `moviw ++FSR0` / `--FSR0` | pre-increment / pre-decrement, then access |
| `moviw k[FSR0]` | access *(FSR0 + k), pointer unchanged (−32 ≤ k ≤ 31) |

There's also `ADDFSR FSR0,k` to jump the pointer by a signed offset (−32…31). Together these turn
the FSR into a clean array walker.

---

## 11.5 Walking a buffer with a pointer

Here's the indirect model in action — fill an 8-byte buffer with 0,1,2,…,7:

```asm
    PSECT udata              ; a GPR buffer (linker picks a bank)
buf:
    DS      8
    PSECT udata_shr
count:  DS  1

; ... in code ...
    ; point FSR0 at buf (its absolute address is in the 0x0000-0x1FFF region)
    movlw   low(buf)
    movwf   FSR0L
    movlw   high(buf)
    movwf   FSR0H

    movlw   8
    movwf   count            ; 8 items to write
    clrw                     ; W = 0, the first value to store
fill:
    movwi   FSR0++           ; *FSR0 = W, then advance the pointer
    addlw   1                ; next value
    decfsz  count,f          ; done all 8?
    goto    fill
```

The `low()` and `high()` operators (User's Guide §4.7) split `buf`'s address into the two bytes we
load into `FSR0L`/`FSR0H`. Then each `movwi FSR0++` stores a byte *and* steps the pointer forward —
no manual address arithmetic. Because `buf` is a GPR variable, its absolute address falls in the
**traditional** FSR region (0x0000–0x1FFF), so this "just works."

---

## 11.6 When one bank isn't enough: linear memory

Notice the catch: a single bank holds only **80 bytes** of GPR (0x20–0x6F; Chapter 8). What if you
need a 200-byte buffer? In the traditional view, incrementing an FSR past a bank's GPR runs into
core registers and SFRs — garbage. That's what **linear data memory** solves (data sheet §9.6.2):

> "Use of the linear data memory region allows buffers to be larger than 80 bytes because
> incrementing the FSR beyond one bank will go directly to the GPR memory of the next bank."

The architectural window 0x2000–0x2FEF is a *virtual* map that stitches the GPR blocks for banks
0 through 50 into one run: bank 0's GPR, then bank 1's, then bank 2's, and so on. This does **not**
mean every device implements that whole window. For the PIC16F17146, the selected DFP defines the
implemented `BIGRAM` range as **0x2000–0x27EF**, corresponding to its implemented GPR in banks
0–25 (bank 25 has only 32 GPR bytes). Point an FSR at an implemented linear address and
`moviw FSR0++` sails from one bank's RAM straight into the next — no SFR/common gaps.

Three caveats worth remembering:

- **Common RAM (0x70–0x7F) is *not* part of the linear region** (§9.6.2). Linear memory is GPR
  only.
- Unimplemented linear locations read as 0; never size an object from the architectural maximum.
- The linear address of a byte isn't the same number as its banked address — it's its position in
  that stitched-together run.

### Reserving a buffer that really crosses banks

A normal `PSECT udata` object must fit one `RAM` class range, so it cannot cross a bank boundary.
For a large enhanced-mid-range object, use `DLABS` (User's Guide §4.9.12 and Embedded Engineers
guide §5.3). Its address argument can be banked or linear; the symbol it creates is always the
equivalent **linear** address, and the linker reserves the underlying physical GPR so ordinary
variables cannot overlap it:

```asm
#define BIG_SIZE 200

; Reserve 200 physical GPR bytes beginning at banked address 0x20.
; The generated symbol bigBuf has linear value 0x2000.
    DLABS   1, 0x20, BIG_SIZE, bigBuf

; ... in code: point FSR0 at the linear object ...
    movlw   low(bigBuf)
    movwf   FSR0L
    movlw   high(bigBuf)
    movwf   FSR0H
```

`DLABS` does not belong to the current psect and emits no initial data. Because it makes a
fixed-address reservation, you must choose the banked start and length from the exact device's
implemented GPR map and check the final map file. Here 200 bytes consume all 80 bytes of bank 0,
all 80 of bank 1, and 40 bytes of bank 2; consecutive FSR accesses use 0x2000–0x20C7. For the
small, single-bank buffers a beginner writes, the traditional approach in §11.5 remains simpler.

The takeaway: **little variables → glue bytes together (§11.2); big buffers that outgrow a bank →
linear memory via the FSRs.** Same two registers, two levels of power.

---

## 11.7 What just happened

You broke the 8-bit ceiling two different ways. For a **number** bigger than a byte, you chained
bytes and carried between them with `INCFSZ`. For **data** bigger than a register — arrays and
buffers — you used the `FSR`/`INDF` pointer machinery, with auto-incrementing `moviw`/`movwi`
moves, and you learned that the **linear memory** view lets a buffer span banks as if the 80-byte
walls weren't there.

---

## 11.8 Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| 16-bit counter high byte never changes | tested the wrong condition, or used `incf`+separate check wrong | use `incfsz` on the low byte, `incf` the high byte only when it skips |
| High byte increments every count | logic inverted (carried when *not* zero) | `incfsz` skips the "done" `goto` *only* on wrap — carry belongs after the skip |
| Bytes read as a garbled 16-bit value | mixed up which byte is low vs. high | pick one convention (`counter` = low, `counter+1` = high) and keep it |
| FSR walk hits non-buffer data after ~80 bytes | buffer outgrew one bank in the traditional region | reserve it with `DLABS` and use its linear symbol (§4.9.12, §9.6.2) |
| `moviw FSR0++` won't assemble | wrong increment syntax | it's `FSRn++`/`FSRn--`/`++FSRn`/`--FSRn` (data sheet §41) |
| Pointer reads zero everywhere | `FSR0` points at an `INDF` address, or was never loaded | load `FSR0L`/`FSR0H` with a real address first (§9.6) |

(Appendix C decodes the exact message wording.)

---

## 11.9 Try it yourself

1. **Count faster to see the carry.** Preload `counter` with `0xFA` in the low byte before the
   loop, so the first rollover happens in six counts. Watch the high byte tick.
2. **Make it 24-bit.** Extend `counter` to `DS 3` and add a second carry stage (`incfsz counter+1`
   guarding `incf counter+2`). Confirm it rolls over at 16,777,215.
3. **Read the buffer back.** After filling `buf` in §11.5, re-point `FSR0` at `buf` and use
   `moviw FSR0++` in a loop to read each byte into W; watch the values 0…7 appear.
4. **Sum a buffer.** Walk `buf` with `moviw FSR0++`, adding each byte into a running total with
   `addwf` — your first indirect-addressing algorithm.

---

## 11.10 Reference bridge

- **Data sheet §9.6 "Indirect Addressing"** — the FSR/INDF model, traditional and linear data,
  the EEPROM read window, program Flash reads, and reserved address ranges.
- **Data sheet §41** — the `MOVIW`, `MOVWI`, `ADDFSR`, and `INCFSZ` instruction details.
- **User's Guide §4.7** — the `low()`/`high()` operators for splitting an address.
- **User's Guide §4.9.12 and Embedded Engineers guide §5.3** — `DLABS`, fixed physical
  reservation, and its automatically generated linear symbol.

**Next chapter (Part IV):** you've been writing straight-line code with the occasional loop.
Chapter 12 broadens your toolkit with the **directives you'll actually use** — `EQU`, `DB`/`DW`
data tables, `ORG`, conditional assembly, and the macro basics — so your programs can define
constants, embed lookup tables, and adapt at build time.
