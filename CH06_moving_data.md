# Chapter 6 — Moving Data: W, Literals, and File Registers

> **Reference keys:** `[DS17146]` and `[UG]` in `REFERENCES.md`.

> **Scope and validation:** PIC16F17146, enhanced mid-range core; XC8 4.00 with PIC16F1xxxx DFP 1.31.465. Example: source- and build/link-verified; simulator/hardware runtime not verified.

> **What you'll build:** a tiny program that loads a number, stashes it in a memory location,
> clears its working copy, then reads the number back — and you'll *watch each value move* in
> the simulator's Watch window. No blinking yet; this is the chapter where "data" stops being
> abstract and becomes three registers you can see change.

---

## 6.1 The idea: almost everything flows through one register

Look at the PIC16F17146's core data-path diagram in the data sheet (DS40002343F §7, Figure
7-1). Nearly every arrow into and out of the ALU passes through a single 8-bit register called
**W — the Working register** (shown as "W Register" in that figure). W is the chip's scratch
register. You load a value into W, the ALU operates using W, and an instruction can place its
result in W or back in a file register.

This is the mental shift from high-level languages. In C you write `x = a + b` and the compiler
finds registers for you. In PIC® assembly *you* are the compiler: to add two numbers you load
one into W, then add the other to W. W is the crossing point that almost all data traffic must
go through. Get comfortable with it and the rest of the instruction set falls into place.

> **Fact check.** The enhanced mid-range CPU in this chip has **50 instructions** and W sits at
> the center of the data path alongside the STATUS register and ALU (data sheet §7, §7.4).
> A great many of those 50 instructions are just different ways of moving data into W, out of
> W, or combining something with W.

---

## 6.2 Two kinds of "value": literals and file registers

Most instructions that move or combine byte values use one of two kinds of operand:

- A **literal** — a constant number baked into the instruction itself. `movlw 0x2A` means
  "move the *literal* 0x2A into W." The `l` in `movlw` stands for *literal*. The value lives
  inside the program, not in RAM.
- A **file register** — any byte of the chip's **data memory**. "File register" is the classic
  PIC term for "an addressable byte of RAM." `movwf myByte` means "move W into the *file
  register* named `myByte`." The `f` stands for *file register*.

So `movlw` brings a fixed constant in from your code, and the file-register instructions shuffle
data between W and RAM. That's the whole game at this level.

---

## 6.3 What counts as a "file register"?

Here's the part that surprises newcomers: on a PIC, **almost everything is a file register.**
The data memory isn't just your variables — the ports, the timers, the configuration of every
peripheral, and even W itself all live in the same addressable data space. The data sheet lays
out how each 128-byte **bank** of data memory is divided (§9.2):

| Region | Size per bank | What lives there |
|---|---|---|
| Core registers | 12 bytes (offsets 0x00–0x0B) | `INDF0/1`, `PCL`, `STATUS`, `FSR0L/H`, `FSR1L/H`, `BSR`, **`WREG`**, `PCLATH`, `INTCON` |
| Special Function Registers | up to 20 bytes | peripheral controls: `PORTA`, `TRISC`, `LATA`, timer registers… |
| General Purpose RAM (GPR) | up to 80 bytes (0x20–0x6F) | *your* variables |
| Common RAM | 16 bytes (0x70–0x7F) | your variables, reachable from **every** bank |

Two facts from that table matter enormously right now:

1. **W is mapped into the file-register address space.** The dedicated CPU working register
   appears as `WREG` at offset 0x09 of every bank (data sheet §9.2.2), so file-register
   instructions such as `clrf WREG` can access it. That does not make W ordinary SRAM: it is a
   CPU register with special instruction encodings and ALU behavior.
2. **Common RAM (0x70–0x7F) is reachable from every bank** (§9.2.5). This is the beginner's
   escape hatch from the banking headache we'll tackle in Chapter 8: put a variable there and
   you can touch it without any bank-selection ceremony.

> **Why banks exist at all (the one-paragraph version).** A file-register instruction only has
> room to name a **7-bit** offset (0–127) — enough for one 128-byte bank. To reach more RAM,
> the chip keeps a **Bank Select Register (BSR)** that picks *which* bank those 7 bits refer to;
> the full data address is 6 bank bits + 7 offset bits (§9.2.1). Common RAM cheats: it's mirrored
> into all banks, so its offset means the same thing no matter what BSR holds. Chapter 8 is
> devoted to the banks; for now we simply sidestep them.

---

## 6.4 The three instructions you need today

These are the documented instruction forms used by the device and assembler (data sheet §9.1.1;
User's Guide §4.1), not teaching-language simplifications:

| Instruction | Meaning | Example |
|---|---|---|
| `movlw k` | **W ← literal k** (an 8-bit constant) | `movlw 0x2A` → W becomes 0x2A |
| `movwf f` | **file register f ← W** | `movwf myByte` → myByte becomes whatever W holds |
| `movf f,w` | **W ← file register f** | `movf myByte,w` → W becomes myByte's value |

### The `,w` / `,f` destination operand — don't leave it off
Many byte instructions can send their result to *either* W or back to the file register, and you
choose with a destination operand (User's Guide §4.1.1):

- **`,w`** → result goes to **W**.
- **`,f`** → result goes back to the **file register**.

So `movf myByte,w` copies myByte *into W*, while `movf myByte,f` reads myByte and writes it
back to *itself* (useful only for its side effect on the STATUS flags — a trick for later).

> **Trap — the silent default.** If you omit the destination, the assembler assumes **`,f`**
> (User's Guide §4.1.1). That means a careless `movf myByte` does **not** load W — it writes
> myByte back to itself and leaves W untouched. The guide "highly recommends" you always write
> the destination explicitly, and so do I. Nearly every beginner loses an hour to this once.

> **Trap — `movfw` doesn't exist here.** If you've seen older MPASM code use `movfw foo`, that
> pseudo-instruction is **not** implemented by the XC8 assembler. Write the standard
> `movf foo,w` instead (User's Guide §4.1.4).

---

## 6.5 The whole program

Save as `move.S`. Add your Chapter 5 `CONFIG` block at the top for real hardware; it's omitted
here so the data movement stays in focus.

```asm
; ------------------------------------------------------------
;  move.S  —  watch a value travel: literal -> RAM -> W
; ------------------------------------------------------------

    PROCESSOR 16F17146
#include <xc.inc>
;  (CONFIG block from Chapter 5 goes here for real silicon)

; --- one byte of storage in COMMON RAM (0x70-0x7F) -----------
; Common RAM is reachable from every bank, so NO BANKSEL is
; needed to touch myByte. (Assembler psect: udata_shr, class
; COMMON — User's Guide §5.2; common RAM — data sheet §9.2.5.)
    PSECT udata_shr
myByte:
    DS      1                   ; reserve 1 byte

; --- reset entry point (chip starts at 0x0000, §9.1) ---------
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main

; --- the code ------------------------------------------------
    PSECT code
main:
    clrf    myByte             ; define RAM before observing it (reset value is undefined)
    movlw   0x2A                ; (1) W <- literal 0x2A  (decimal 42)
    movwf   myByte             ; (2) myByte <- W        (myByte = 0x2A)
    movlw   0x00                ; (3) W <- 0             (wipe W on purpose)
    movf    myByte,w           ; (4) W <- myByte        (W = 0x2A again)
    goto    $                   ; (5) stop here forever

    END     resetVec
```

Notice there is **no `BANKSEL` and no `BANKMASK`** anywhere. That's the payoff of putting
`myByte` in common RAM — its address (somewhere in 0x70–0x7F) has no bank bits to worry about,
so every instruction just works. Enjoy it now; Chapter 8 explains what you're being spared.

---

## 6.6 Build & run it — and actually watch

Build exactly as before, with `DFP` set as in Chapter 3:
```
pic-as -mcpu=16f17146 -mdfp="$DFP" -Wl,-presetVec=0h \
       -Wa,-a -Wl,-Map=move.map move.S
```

Now the important part — *observe the moves*:

1. Start the **MPLAB Debugger** simulator (Chapter 3: **F5** on the debug configuration).
2. In the **Run and Debug** view open **Variables**, or add a **Watch** on `myByte` and on `WREG`.
   (W shows up as `WREG` because, as §6.3 noted, the working register is mapped into the
   file-register address space under that name.)
3. **Step one instruction at a time** and watch. The initial `clrf` makes the otherwise-undefined
   RAM byte deterministic:
   - After line (1): `WREG` = 0x2A, `myByte` remains 0.
   - After line (2): `myByte` = 0x2A.
   - After line (3): `WREG` = 0x00 — proof the copy in `myByte` is independent.
   - After line (4): `WREG` = 0x2A again — you just read RAM back into W.
   - Line (5): the PC freezes (your endless loop from Chapter 4).

Seeing those two values change on separate steps is the entire point of this chapter. Data
movement is no longer a concept — it's two numbers you watched move.

---

## 6.7 What just happened

You exercised the fundamental cycle of all PIC assembly: **literal → W → file register → W.**
Every larger program is this pattern repeated and combined. Loading a port value, saving a
sensor reading, setting up a timer — all of it is `movlw`/`movwf`/`movf` with the occasional
arithmetic instruction mixed in.

You also met W wearing both of its hats: the ALU's dedicated working register *and* a CPU register
mapped into the file space as `WREG`. And you got your first, painless taste of data memory by
hiding in common RAM.

---

## 6.8 Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| `movf myByte` doesn't change W | destination defaulted to `,f`, writing myByte to itself | write `movf myByte,w` explicitly |
| `movfw` reported as unknown | that MPASM pseudo-instruction isn't in XC8 | use `movf foo,w` (User's Guide §4.1.4) |
| Fixup/overflow once you move `myByte` out of common RAM | a GPR variable needs bank selection + masking | that's Chapter 8; keep it in `udata_shr` for now |
| Loaded a constant but W is wrong | `movwf k` used where you meant `movlw k` | `movlw` = load literal; `movwf` = store W to a file register |
| `movlw 0FFh` fine but `movlw FFh` errors | hex constant must start with a digit | write `0FFh` or `0xFF` (Chapter 4 §4.5) |

(Appendix C decodes the exact assembler message text.)

---

## 6.9 Try it yourself

1. **Add a second variable.** Reserve `myByte2` in the same `udata_shr` psect, and write code
   that copies `myByte` into `myByte2` through W. Step through and confirm both hold 0x2A.
2. **Prove the default bites.** Change line (4) to `movf myByte` (no `,w`), rebuild, and step
   through. Watch `WREG` *not* update. Then fix it and watch the difference. Feel the trap so
   you never fall in it later.
3. **Clear W two ways.** Replace `movlw 0x00` with `clrf WREG` and confirm that both make W
   zero. Then inspect `STATUS.Z`: `clrf` sets Z, while `movlw` does not affect STATUS. Equal data
   results do not imply equal side effects (data sheet §9.2.2 and §41).

---

## 6.10 Reference bridge

- **Data sheet §7 "Enhanced Mid-Range CPU"** — the core data path, W, STATUS, and the
  50-instruction set at a glance.
- **Data sheet §9.2 "Data Memory Organization"** — banks, core registers, GPR, and common RAM,
  now that you've used them.
- **User's Guide §4.1 "Assembly Instruction Deviations"** — the `,w`/`,f` operand styles and the
  `movfw` note, formally.
- **User's Guide §5.2 "Assembler-provided Psects"** — where `udata_shr`, `udata`, and `code`
  come from.

**Next chapter:** you can now move bytes around at will. Chapter 7 points those bytes at the
outside world — choosing the input-buffer mode with `ANSEL`, enabling the output driver with
`TRIS`, and driving it with `LAT` to make an LED blink. That's the first program that does
something you can *see*.
