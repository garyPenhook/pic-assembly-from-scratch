# Chapter 8 — Data Memory & Banking

> **Reference keys:** `[DS17146]`, `[UG]`, and `[DFP17146]` in `REFERENCES.md`.

> **Scope and validation:** PIC16F17146, enhanced mid-range core; XC8 4.00 with PIC16F1xxxx DFP 1.31.465. Examples: source- and build/link-verified; runtime not hardware-verified.

> **What you'll build:** the same blinking LED as Chapter 7 — but this time with the training
> wheels off. You'll replace the `--fixupoverflow` linker crutch with the *real* `BANKSEL` and
> `BANKMASK` you write yourself, and you'll finally understand what every one of those lines has
> been doing. This is the chapter that turns "cargo-cult `BANKSEL`" into knowledge.

---

## 8.1 The idea: an instruction can only point 128 bytes

Here is the whole reason banking exists, in one fact. A file-register instruction on this chip —
`movwf`, `clrf`, `bcf`, and friends — reserves only a **7-bit field** for the address of the byte
it touches. Seven bits count from 0 to 127. So a single instruction can only name one location
inside a **128-byte window**.

But the PIC16F17146 has far more than 128 bytes of data memory. The data sheet spells out the
solution (§9.2): the data memory is split into **up to 64 banks of 128 bytes each**, and a
separate register — the **Bank Select Register (BSR)** — chooses *which* bank those 7 address
bits refer to. Put formally (§9.2.1):

> "Data memory uses a 13-bit address. The upper six bits of the address define the Bank Address
> and the lower seven bits select the registers/RAM in that bank."

So a full data address is **6 bank bits + 7 offset bits = 13 bits**. The instruction supplies the
7 offset bits; **BSR supplies the 6 bank bits.** That division of labor is the entire banking
system. Everything else is bookkeeping to keep BSR pointing where you think it is.

```
 full 13-bit data address:   bbbbbb ooooooo
                             └──┬──┘ └───┬───┘
                          BSR (bank)   instruction (offset 0-127)
```

---

## 8.2 What's in a bank

The architecture gives each of the 64 banks the same 128-byte *address layout*, although a
particular bank can implement fewer SFRs or GPR bytes (data sheet §9.2, Figure 9-2):

| Offset in bank | Region | Notes |
|---|---|---|
| 0x00–0x0B | **12 core registers** | `WREG`, `STATUS`, `BSR`, `FSR0/1`, `INDF0/1`, `PCL`, `PCLATH`, `INTCON` — mirrored in every bank |
| 0x0C–0x1F | **Special Function Registers** | up to 20 peripheral-control bytes (varies by bank) |
| 0x20–0x6F | **SFR or General Purpose RAM** | up to 80 bytes of *your* variables; high SFR banks use this range too |
| 0x70–0x7F | **Common RAM** | 16 bytes, **mirrored into every bank** |

Two features fall out of this layout that you've already been leaning on:

- **Core registers and common RAM appear in *every* bank.** That's why `WREG` and your
  `udata_shr` variables (Chapter 6) never needed a `BANKSEL` — no matter what BSR holds, offsets
  0x00–0x0B and 0x70–0x7F mean the same thing. Common RAM is the banking escape hatch precisely
  because it's un-banked.
- **Everything else moves.** `PORTC`, `TRISC`, `ANSELC`, and your GPR variables live in specific
  banks, and you must set BSR before touching them.

> **Reality check on "64 banks."** The address space *allows* 64 banks, but this chip doesn't
> implement GPR in all of them — high banks are used heavily for SFRs, and unimplemented locations
> read as 0 (data sheet §9, Figures 9-6 through 9-10). The banks that matter hold the SFRs (spread
> across banks 0–61) and the GPR/common RAM your program actually uses.

---

## 8.3 `BANKSEL`: setting the bank

To point BSR at the right bank, you *could* compute the bank number and load it yourself. On this
enhanced mid-range core there's a dedicated instruction for it — **`MOVLB k`** ("Move literal to
BSR," data sheet §41). But you rarely write it by hand. Instead you use the assembler's
**`BANKSEL`** directive and name the object you're about to access:

```asm
    BANKSEL TRISC          ; assembler figures out TRISC's bank, emits movlb <that bank>
    bcf     TRISC,1
```

`BANKSEL TRISC` asks the linker "which bank is `TRISC` in?" and generates the instruction to load
BSR with that number (User's Guide §4.1.2 — on enhanced mid-range and PIC18® devices it expands to
a single `movlb`). You get portability for free: move to a chip where `TRISC` lives elsewhere and
`BANKSEL` still emits the right thing.

> **Trap — never put `BANKSEL` right after a skip.** On some cores `BANKSEL` can expand to more
> than one instruction, so it must not immediately follow a skip instruction like `btfsc`/`btfss`
> (User's Guide §4.1.2). On enhanced mid-range it's a single `movlb`, but forming the habit now
> saves you on other PICs.

---

## 8.4 `BANKMASK`: making the address fit

Setting the bank is only half the job. Consider `ANSELC`. Its full address on this chip is
**0x1EA0** (data sheet §9, Figure 9-12). Split that into the 13-bit form:

```
0x1EA0 = 11 1101  010 0000   (binary)
         └──┬──┘  └───┬───┘
         bank 0x3D   offset 0x20
         (= 61)
```

So `ANSELC` is **offset 0x20 in bank 61.** Now here's the problem: an instruction's address field
is only 7 bits, but the symbol `ANSELC` carries the *full* 13-bit value 0x1EA0. If you wrote
`bcf ANSELC,1`, the assembler would try to stuff 0x1EA0 into a 7-bit slot — far too big — and the
linker would raise a **fixup overflow error**.

`BANKMASK()` fixes this by ANDing away the upper (bank) bits, leaving just the 7-bit offset the
instruction can hold (User's Guide §4.1.3):

```asm
    BANKSEL ANSELC              ; BSR <- 61   (the bank bits)
    bcf     BANKMASK(ANSELC),1  ; use offset 0x20 (the low 7 bits) - fits!
```

**This is exactly the two-part dance banking always requires:**
1. **`BANKSEL`** puts the *bank* into BSR.
2. **`BANKMASK`** trims the *operand* down to the 7-bit offset.

They are independent and you almost always need both. `BANKSEL` alone without masking → fixup
overflow. `BANKMASK` alone without `BANKSEL` → the instruction reaches offset 0x20 of *whatever
bank BSR happened to hold* — a silent, nasty bug.

> **The Chapter 7 mystery, solved.** Back in the blink program we added
> `-Wl,--fixupoverflow=warn` and skipped `BANKMASK`. That option told the linker "truncate every
> over-large operand to fit automatically" — i.e., *do the masking for me* (User's Guide §4.1.3).
> It's convenient, but it masks **every** overflowing operand globally, which can hide an unrelated
> addressing mistake. Writing `BANKMASK` only at the operands that intentionally need truncation
> leaves the linker's default overflow checks active everywhere else. From here on we do it by hand.

---

## 8.5 Placing your own variables in a bank

For your variables, you pick where they live with the psect you reserve them in (the
assembler-provided psects from Chapter 6, User's Guide §5.2):

| Psect | Where the variable lands | Needs `BANKSEL`? |
|---|---|---|
| `udata_shr` | common RAM (0x70–0x7F) | **no** — mirrored in all banks |
| `udata` | any free GPR bank (linker chooses) | yes |
| `udata_bank0` … `udata_bankn` | GPR in *that specific* bank | yes (that bank) |

Most of the time `udata` is right: you don't care which bank a variable is in, so let the linker
place it and let `BANKSEL` name it. Reach for `udata_bankn` only when a variable *must* be in a
particular bank (rare for beginners).

---

## 8.6 The whole program — blink, banked by hand

This is Chapter 7's blink with the crutch removed. Watch how `ANSELC` (bank 61) needs
`BANKMASK`, while `TRISC`/`LATC` (bank 0, offsets below 0x80) don't — their bank bits are already
zero, so nothing overflows. We also add a real GPR variable, `blinks`, to make the banking
concrete.

```asm
; ------------------------------------------------------------
;  blink8.S  —  Chapter 7 blink, with banking done manually
; ------------------------------------------------------------

    PROCESSOR 16F17146
#include <xc.inc>
;  --- paste your Chapter 5 CONFIG block here ---

; a counter in general-purpose RAM (linker picks a bank)
    PSECT udata
blinks: DS  1

; delay counters in common RAM (no banking needed)
    PSECT udata_shr
d1: DS  1
d2: DS  1

    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main

    PSECT code
main:
    ; count starts at zero
    BANKSEL blinks
    clrf    BANKMASK(blinks)        ; blinks lives in a GPR bank -> mask it

    ; configure RC1 as a digital output
    BANKSEL ANSELC                  ; movlb 61  (ANSELC is 0x1EA0)
    bcf     BANKMASK(ANSELC),1      ; offset 0x20, RC1 -> digital
    BANKSEL TRISC                   ; movlb 0
    bcf     TRISC,1                 ; bank 0 offset 0x14 - no mask needed
    BANKSEL LATC                    ; movlb 0
    bsf     LATC,1                  ; LED off (active-low); BSR now = bank 0

loop:
    bcf     LATC,1                  ; LED ON  (BSR still bank 0 - no BANKSEL)
    call    delay
    bsf     LATC,1                  ; LED OFF
    call    delay

    ; tally the blinks (demonstrates banked GPR access)
    BANKSEL blinks
    incf    BANKMASK(blinks),f      ; blinks++
    BANKSEL LATC                    ; re-select bank 0 for the next loop pass
    goto    loop

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

Two things to notice, both central to banking discipline:

- **After `BANKSEL blinks` we must `BANKSEL LATC` again** before the loop repeats, because
  reading `blinks` moved BSR to `blinks`'s bank. If we forgot, the next `bcf LATC,1` would hit
  offset 0x1A of the *wrong* bank. Tracking "where is BSR right now?" is the core skill of
  banked programming.
- **`TRISC` and `LATC` skip `BANKMASK`** only because they sit in bank 0, where the bank bits are
  already 0. It's never *wrong* to wrap them in `BANKMASK` too — many programmers do, for
  consistency and safety.

---

## 8.7 Build & run it — no crutch this time

```
pic-as -mcpu=16f17146 -mdfp=/path/to/PIC16F1xxxx_DFP/VERSION/xc8 \
       -Wl,-presetVec=0h -Wa,-a -Wl,-Map=blink8.map blink8.S
```

Notice `--fixupoverflow` is **gone** — because we masked every over-large operand ourselves, the
linker has nothing to complain about. The LED blinks exactly as before, but now *you* control the
banking. Open the `.lst` file and find your `BANKSEL` lines: you'll see each one became a
`movlb` with the bank number the linker computed (e.g. `movlb 0x3D` for `ANSELC`).

---

## 8.8 What just happened

You learned the two-part contract behind a direct access to banked data: **`BANKSEL` loads the bank
into BSR; `BANKMASK` trims the operand to its 7-bit offset.** You saw *why* — the 128-byte reach of
a file-register instruction — and you saw the escape hatches (core registers and common RAM) that
let you dodge it when you can. Most importantly, you now know what all those `BANKSEL` lines from
Chapters 6 and 7 were really doing, and the `--fixupoverflow` option is a choice you make, not magic
you depend on.

---

## 8.9 Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| Linker: "fixup overflow" on an SFR access | `BANKSEL` present but operand not masked | wrap the operand in `BANKMASK()` (§4.1.3) |
| Wrong RAM byte read/written, no error | `BANKMASK` used but `BANKSEL` forgotten | always pair them; select the bank first |
| Code worked, then broke after adding a RAM access mid-loop | that access moved BSR; later instructions assumed the old bank | re-`BANKSEL` the register you return to |
| `BANKSEL`/`BANKMASK` reported undefined | forgot `#include <xc.inc>` | the macros come from the header (§4.1.3) |
| Variable in `udata` needs banking but you expected none | only `udata_shr` (common RAM) is bank-free | use `udata_shr` for hot variables, or `BANKSEL` the `udata` one |

(Appendix C decodes the exact message wording.)

---

## 8.10 Try it yourself

1. **Read the bank numbers.** Build `blink8.S`, open the `.lst` file, and confirm `BANKSEL
   ANSELC` became `movlb 0x3D` (61) and `BANKSEL LATC` became `movlb 0`. Match them to the
   addresses in data-sheet §9.
2. **Cause the bug on purpose.** Delete the `BANKSEL LATC` that re-selects bank 0 before
   `goto loop`, rebuild, and run on the simulator. Watch the LED behavior break, and use the
   Watch window to see which bank BSR is stuck in.
3. **Move a variable into a chosen bank.** Change `blinks` from `PSECT udata` to
   `PSECT udata_bank0`, rebuild, and confirm from the map file it landed in bank 0. Then try
   `udata_shr` and confirm `BANKSEL blinks` is no longer needed.
4. **Hand-compute an offset.** Take `LATA` (find its address in §9, Figure 9-3) and work out its
   bank and 7-bit offset by hand, the way we did for `ANSELC`.

---

## 8.11 Reference bridge

- **Data sheet §9.2 "Data Memory Organization"** — banks, BSR, the 13-bit address split, and the
  full per-bank memory maps you can now read.
- **User's Guide §4.1.2–4.1.3** — `BANKSEL`, `PAGESEL`, `BANKMASK`, `PAGEMASK`, and the
  `--fixupoverflow` option, formally.
- **Data sheet §41** — `MOVLB` and the file-register instructions whose 7-bit address field
  started this whole story.

**Next chapter:** data memory has banks; *program* memory has the same problem one level up. When
your code grows past one **page**, `goto` and `call` can't reach across the boundary on their own.
Chapter 9 introduces **paging** and `PAGESEL` — the program-memory twin of everything you just
learned.
