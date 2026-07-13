# Chapter 19 — Baseline and Enhanced-Baseline Devices (Optional Finale)

> **What you'll learn:** how your skills scale *down* to the 12-bit PIC cores. We distinguish
> plain baseline **PIC12** (the PIC10F200, with no interrupt controller), enhanced baseline
> **PIC12E**, and interrupt-capable enhanced baseline **PIC12IE** (the PIC16F570 used in the
> worked example). Memory is scarce and one `call` quirk shapes code placement on all three.

> **Sourcing note.** Plain-baseline facts are checked against the PIC10F200/202/204/206 data
> sheet **DS40001239F**, errata **DS80194G**, and the PIC10-12Fxxx DFP 1.8.184 (`ARCH=PIC12`).
> The runnable example is the *interrupt-capable enhanced-baseline* PIC16F570, checked against
> data sheet **DS40001684F**, errata **DS80000624B**, the Embedded Engineers guide §9, and
> PIC16Fxxx DFP 1.7.162 (`ARCH=PIC12IE`). Always repeat that exact-device check.

---

## 19.1 The idea: the same skills, a smaller box

The family uses **12-bit-wide instructions** — narrower than mid-range's 14 bits — and appears in
PIC10, PIC12, and some PIC16 part numbers (User's Guide §2.1). Source structure, `PSECT`,
`CONFIG`, `W`, file registers, `DS`, and macros remain familiar, but capabilities must be read
from the exact device rather than inferred from the marketing part number.

| DFP architecture | Meaning | Concrete anchor here |
|---|---|---|
| `PIC12` | plain baseline | PIC10F200: 33 instructions, two-level return stack, no interrupt controller |
| `PIC12E` | enhanced baseline without interrupts | added core features, but no interrupt vector |
| `PIC12IE` | enhanced baseline with interrupts | PIC16F570: 36 instructions, four-level return stack, vector at 0x0004, automatic context switching |

Three things shrink or vanish:

- **Fewer instructions and less memory** — you budget both carefully.
- **Interrupt capability varies.** The plain PIC10F200 has no interrupt vector and uses polling;
  the `PIC12IE` PIC16F570 has Timer0, ADC, comparator-change, and pin-change interrupts plus
  automatic W/STATUS/FSR/BSR context switching (PIC16F570 data sheet §8.11–§8.12).
- **A `call` quirk** that dictates where callable routines can start — the one genuinely new idea,
  next.

---

## 19.2 The baseline `call` restriction

Here's the wrinkle that catches everyone. When a baseline device executes a `call`, the target
address is assembled unusually (Emb Eng §9.1):

> "bits 0 through 7 of the PC register are loaded from the instruction operand, bits 9 and 10 are
> loaded from the PA bits in the STATUS register but, importantly, **bit location 8 is
> unconditionally cleared.**"

Clearing bit 8 means a `call` can only land in an address where bit 8 is 0 — i.e. the **first 256
locations of a page**. So on baseline devices:

- **A callable routine's *entry point* must be in the first 256 words of a page** (Emb Eng §9.1).
- The **same restriction applies to any instruction that modifies `PCL`** (computed jumps).
- **`goto` is *not* restricted** — jumps reach anywhere in a page.

Note what this does *not* say: a routine can still be as long as you like and fill the whole page —
only its **entry label** must sit in the low 256. Once execution is inside the routine, it runs on
normally to the page's end (Emb Eng §9.1).

---

## 19.3 The `ENTRY` class: letting the linker handle it

You don't want to hand-place every subroutine in the low 256 words. The assembler solves this with
a special linker class, **`ENTRY`** (Emb Eng §9.1). Recall from Chapter 10 that a class is a range
of addresses; `ENTRY` is defined with an *extra* address field that means "start here, but you may
extend to there":

```
-AENTRY=00h-0FFh-01FFh, ...
```

That reads: a psect placed in `ENTRY` **must start within 0x00–0xFF** (the callable region) but its
body **may run on up to 0x1FF** (the page end). Put your callable routines in a psect with
`class=ENTRY` and the linker guarantees their entry points are reachable by `call` — without
limiting the routine's length.

Routines that are only ever *jumped* to (like `main`) don't need this — they go in the ordinary
`CODE` class and can live anywhere, using the upper halves of pages that `ENTRY` can't (Emb Eng
§9.1).

---

## 19.4 A baseline example

Microchip's PIC16F570 example writes increasing values to PORTA (Emb Eng §9). This is an
**enhanced-baseline PIC12IE** example, chosen because it demonstrates the `ENTRY` rule. It is not
evidence that all baseline devices share the PIC16F570's interrupts, memory map, or instructions.

```asm
PROCESSOR 16F570
#include <xc.inc>

CONFIG "FOSC = EXTRC_CLKOUT" // illustrative: requires external RC hardware
CONFIG "WDTE = OFF"
CONFIG "CP = OFF"
CONFIG "IOSCFS = 8MHz"
CONFIG "CPSW = OFF"
CONFIG "BOREN = OFF"
CONFIG "DRTEN = OFF"

PSECT udata_shr                 ; common memory (baseline has little of it)
counter: DS 1
loc:     DS 1

; Physical Reset fetch is 0x7FF (factory OSCCAL); it rolls over here.
PSECT userEntry,class=CODE,delta=2
userEntry:
    ljmp    main                ; ljmp: page-safe jump (Chapter 9)

PSECT code
main:
    movlw   0
    tris    PORTA               ; baseline 'tris' instruction: 0 -> all outputs
    clrf    counter
    movf    counter,w
loop:
    fcall   increment           ; fcall: page-safe call (Chapter 9)
    movwf   PORTA               ; write directly to PORTA - no LATx on baseline
    goto    loop

; a CALLABLE routine -> must go in the ENTRY class
PSECT entryCode,class=ENTRY,delta=2
increment:
    movwf   loc
    incf    loc,w
    return

    END     userEntry
```

Three baseline-specific details in that listing:

1. **`increment` is in `class=ENTRY`** because `main` *calls* it (`fcall increment`). That's what
   guarantees its entry point lands in a page's low 256. `main` itself is only *jumped* to
   (`ljmp main`), so it stays in the ordinary `code` psect (Emb Eng §9.1).
2. **No `LATx` on this PIC16F570.** Write `PORTA` directly and set direction with the dedicated
   `tris` instruction. Recheck the registers on any other device.
3. **Use long pseudo-instructions where page placement is not guaranteed.** `ljmp main` and
   `fcall increment` are page-safe. The raw `goto loop` is a local branch within the same small
   psect; verify final placement in the list/map before making that assumption in larger code.

The `EXTRC_CLKOUT` setting matches Microchip's toolchain example and requires suitable external
RC hardware; choose oscillator settings for your actual board before expecting the HEX to run.
Errata DS80000624B's Sleep/wake issue affects silicon A1 when DRT is enabled; this example sets
`DRTEN = OFF`. The errata also clarifies the enable conditions for comparator-change and
interrupt-on-change flags—recheck those notes before adding such an ISR.

There is an important reset-path exception here. PIC16F570 hardware begins at **0x7FF**, the last
implemented program word, where Microchip programs an oscillator-calibration `MOVLW` value. After
that instruction, the PC rolls over to **0x000**, our `userEntry` psect (data sheet §4.1/§4.7.1).
Do not erase or replace the factory calibration word. Microchip's guide calls the psect at 0
`resetVec`; this book uses `userEntry` so it is not confused with the physical Reset fetch.

Build it just like any other project (Emb Eng §9.2):

```
pic-as -mcpu=16F570 -mdfp=/path/to/Microchip.PIC16Fxxx_DFP/1.7.162/xc8 \
  -Wl,-puserEntry=0h -Wa,-a -Wl,-Map=incPort.map incPort.S
```

---

## 19.5 Seeing `ENTRY` in the map file

Open the map (Chapter 17's skill) and you'll see the two classes do their jobs (Emb Eng §9.1):

```
TOTAL   Name        Link   Load   Length   Space
  CLASS CODE
        userEntry      0      0        5      0
        code         1F5    1F5        B      0        <- upper half of a page: fine, only jumped to
  CLASS ENTRY
        entryCode      5      5        3      0        <- low 256 of a page: callable
```

`code` landed at 0x1F5 — the *top* of a page, which is fine because nothing `call`s into it.
`entryCode` landed at 0x5 — safely inside the entry region, so `fcall increment` works. The linker
enforced the baseline rule for you; the map file proves it.

> **A cost to know.** The linker finds `ENTRY` psects harder to place than plain `CODE` ones,
> because of the low-256 restriction (Emb Eng §9.1). So mark a routine `ENTRY` only if it's
> actually called or reached via a `PCL`-modifying instruction — leave everything else in `CODE`
> to make the most of those upper page halves.

---

## 19.6 What just happened (and a look back)

You scaled all the way down to the 12-bit baseline core and found the same discipline with tighter
limits. The plain PIC10F200 has 33 instructions and no interrupt controller; the worked
PIC16F570 is `PIC12IE`, has 36 instructions and interrupts, and writes `PORTA` via `tris`. Both
share the key placement rule: **callable routines must start in the low 256 words of a page**,
which the **`ENTRY` class** handles for you.

And with that, you've traveled the entire 8-bit PIC range: **baseline (12-bit)** here, the
**enhanced mid-range (14-bit) PIC16F17146** through the heart of the book, and **PIC18 (16-bit)** in
Chapters 15–16. The core skills never changed — reset vector, psects, banking, the build pipeline,
reading a data sheet before you write a line — only the size of the box around them. That's the
real lesson: learn one PIC deeply and you can meet any of them.

---

## 19.7 Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| `call` to a routine jumps to the wrong place | routine's entry point is above the low 256 of its page | put callable routines in `class=ENTRY` (Emb Eng §9.1) |
| Linker "can't place" an `ENTRY` psect | too many callable routines competing for the low 256 | move non-called code to `CODE`; keep `ENTRY` for true entry points |
| `bsf LATA,0` won't assemble for PIC16F570 | this device has no `LATx` register | write `PORTA` directly; set direction with `tris` |
| Assumed the PIC16F570 has no ISR | confused plain `PIC12` with `PIC12IE` | PIC16F570 vectors at 0x0004; PIC10F200 has no interrupt controller |
| Paging bug on a `call`/`goto` | used raw instructions across a page | use `fcall`/`ljmp` (Chapter 9) |
| Reset behaves unexpectedly | assumed Reset starts at 0 | PIC16F570 fetches 0x7FF (factory calibration), then rolls to user entry 0; other devices differ |

(Appendix C decodes the exact message wording.)

---

## 19.8 Try it yourself

1. **Read the classes.** Build the PIC16F570 example and confirm in the map that `entryCode` is in
   `ENTRY` (low address) while `code` sits high in a page.
2. **Force the failure.** Move `increment` into the plain `code` psect, rebuild, and see whether
   the linker (or the running program) objects to a call landing above the low 256.
3. **Port a routine.** Take Chapter 13's `delay` and adapt it for PIC16F570: `class=ENTRY` if it's
   called, `tris`/`PORT` instead of `LAT`, and page-safe transfers where final placement is not
   guaranteed.
4. **Datasheet drill.** Compare PIC10F200 and PIC16F570: program-memory size, reset behavior,
   return-stack depth, instruction count, and interrupt capability.

---

## 19.9 Reference bridge

- **Embedded Engineers guide §9** — the full baseline example, the `call` entry-point restriction,
  and the `ENTRY` class.
- **User's Guide §2.1** — the baseline vs. enhanced-baseline core descriptions (including which
  have interrupts).
- **User's Guide §5.3** — the `ENTRY` linker class definition and the other predefined classes.
- **PIC10F200 data sheet DS40001239F §4.7–§4.8** — plain-baseline call restriction and stack;
  its feature/instruction tables establish the 33-instruction, non-interrupt anchor.
- **PIC16F570 data sheet DS40001684F §4.6–§4.7 and §8.11–§8.12** — the same call rule plus the
  `PIC12IE` interrupt vector and automatic context switching.

**Where to next:** that's the last core chapter. The **appendices** are your working references —
the instruction-set and directive quick-cards, a guide to decoding the assembler's error and
warning messages (Appendix C), the MPLAB X option reference, an MPASM→XC8 migration cheat sheet, a
glossary, and a bridge from assembly into XC8 C. Keep them beside you as you write your own PIC
assembly from scratch.
