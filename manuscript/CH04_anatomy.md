# Chapter 4 — Anatomy of an Assembly Source File

> **Reference keys:** `[DS17146]` and `[UG]` in `REFERENCES.md`.

> **Scope and validation:** PIC16F17146, enhanced mid-range core; XC8 4.00 with PIC16F1xxxx DFP 1.31.465. Examples: source- and build/link-verified; runtime not hardware-verified.

> **What you'll build:** a complete, buildable PIC16F17146 assembly program whose only
> job is to start up and spin forever in a one-line endless loop. It does nothing useful —
> and that is exactly the point. By the end of this chapter you will recognize every single
> character in a `.S` file and know why it's there.

---

## 4.1 The idea: an assembly file is just a list of *statements*

A C file is made of statements terminated by semicolons and grouped with braces. An
assembly file is simpler and flatter: it is a **list of lines**, and each line is one
*statement*. The assembler reads them top to bottom. An actual instruction mnemonic normally
becomes one machine instruction; assembler pseudo-instructions, directives, and macros can emit
zero, one, or several instructions or data bytes.

The MPLAB® XC8 PIC® Assembler recognizes exactly five statement shapes. Everything you will
ever write is one of these:

| Shape | Looks like | Purpose |
|---|---|---|
| A label alone | `loop:` | names the current spot in memory |
| Label + instruction | `loop: goto loop` | a named machine instruction |
| A directive | `PSECT code` | an order to the *assembler*, not the chip |
| A comment alone | `; spin forever` | a note for humans |
| A blank line | | breathing room |

That's the whole grammar. There is **no required column layout** — you can indent however
you like; whitespace and tabs are just separators. (Source: XC8 PIC Assembler User's Guide
§4.2, "Statement Formats.")

> **Instruction vs. directive — the distinction that trips up every beginner.**
> A *machine instruction* (`goto`, `movlw`, `clrf`) becomes bits inside the chip's program
> memory and executes at run time. A *directive* (`PSECT`, `PROCESSOR`, `CONFIG`, `END`) is
> an instruction to the *assembler program on your PC*. Most directives emit no executable
> instruction, although data directives emit data and pseudo-ops such as `BANKSEL`/`PAGESEL`
> can emit instructions. Same file, two audiences. Keep asking "who is this line talking to —
> the chip, or the assembler?"

---

## 4.2 The whole program, up front

Here it is — the entire file. Save it as `spin.S` (note the **uppercase `.S`**; we'll
explain why in §4.7). Read past it; every line is dissected below.

```asm
; ------------------------------------------------------------
;  spin.S  —  the smallest honest PIC16F17146 program
;  Starts up, then loops forever doing nothing.
; ------------------------------------------------------------

    PROCESSOR 16F17146          ; tell the assembler which chip we're targeting
#include <xc.inc>               ; pull in the register/SFR names for this chip

; --- Reset entry point ---------------------------------------
; The PIC16F17146 begins executing at program address 0x0000
; after any Reset (verified: data sheet DS40002343F §9.1).
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main                ; jump to our real code

; --- Main program --------------------------------------------
    PSECT code
main:
    goto    $                   ; "$" means "this instruction" → endless loop

    END     resetVec            ; end of source; entry point is resetVec
```

Build it (we'll walk through this command in §4.6):

```
pic-as -mcpu=16f17146 -mdfp="$DFP" -Wl,-presetVec=0h \
       -Wa,-a -Wl,-Map=spin.map spin.S
```

If it produces `spin.hex` with no errors, you have just assembled a PIC program. Everything
from here is understanding *why each line was necessary*.

---

## 4.3 Line by line

### Comments — `;`
```asm
; Starts up, then loops forever doing nothing.
```
A semicolon that isn't inside a string begins a comment; everything to its end-of-line is
ignored by the assembler (User's Guide §4.4). Comments can sit on their own line or trail an
instruction:
```asm
    goto    $        ; endless loop
```
> **Trap:** because our file is preprocessed (uppercase `.S`), you *may* also use C-style
> `//` and `/* ... */` comments. But **never** put a `;` comment on a `#define` line — the
> preprocessor doesn't strip `;` comments, so the text leaks into your macro and breaks the
> build. On preprocessor lines, use `//`. (User's Guide §4.4.)

### `PROCESSOR 16F17146` — naming the target
This directive tells the assembler which device's rules and register set to use. It must
match the chip. We verified the exact part is the **PIC16F17146**, one of the
PIC16F17126/46 family, an *enhanced mid-range* core (data sheet DS40002343F, cover & §9.1).

### `#include <xc.inc>` — getting the register names
Out of the box, the assembler does **not** know that `LATA`, `PORTC`, or `TRISA` mean
anything — Special Function Register names are not built in (User's Guide §4.6.4). The line
```asm
#include <xc.inc>
```
pulls in the header that *equates* every SFR name to its hardware address for your selected
chip. After this line, writing `LATA` in an instruction refers to the real Port A latch.
The header also defines handy per-bit symbols (e.g. `RB5`) and field equates of the form
`REGISTERNAME_FIELDNAME_POSN`. We use none of them in `spin.S`, but every later program
needs this line, so it's a habit worth forming now.

### `PSECT resetVec,class=CODE,delta=2` — declaring a program section
A **psect** ("program section") is a named box that your code and data live in; the linker
later places each box at a real address. This is *the* concept the official guides assume you
already know — Chapter 10 is devoted to it. For now, absorb just three things about this line:

- **`resetVec`** is the name we chose for this box.
- **`class=CODE`** says "this box holds executable instructions," so the linker puts it in
  program memory.
- **`delta=2`** says "each address in this memory space is represented by 2 data bytes." On the
  PIC16F17146, program memory is word-addressed and each implemented word is **14 bits** wide,
  so a custom program-space psect must use `delta=2` (User's Guide §4.9.48.4). The device
  implements 16,384 words at 0x0000–0x3FFF even though its 15-bit PC can address a 32K-word
  architectural space (data sheet §9.1). The assembler-provided `code` psect already has the
  correct flags. PIC18 program memory is byte-addressed (`delta=1`) and executable psects normally
  use `reloc=2` for instruction alignment; do not copy this declaration to PIC18 unchanged.

### `resetVec:` and the reset vector
```asm
resetVec:
    goto    main
```
`resetVec:` is a **label** — a name for "the address of the next instruction" (User's Guide
§4.6.5). Why does this one matter so much? Because the PIC16F17146 **always begins executing
at program address 0x0000 after a Reset** (verified: data sheet DS40002343F §9.1 —
"The Reset vector is at 0000h"). In §4.6 we tell the linker to place the `resetVec` psect
*at* address 0. So the very first thing the chip does on power-up is run this `goto main`.

Why jump instead of putting `main` here directly? Because address 0x0004 is the **interrupt
vector** (also §9.1). Real programs need those first few locations kept clear so an interrupt
can land at 0x0004 without colliding with your main code. Jumping out immediately is the
standard, safe pattern — you'll reuse it in every program.

### `PSECT code` and `main:`
```asm
    PSECT code
main:
    goto    $
```
A second box, named `code`, holding the body of the program. `main:` labels its first
instruction.

The star of the show is `goto $`. The symbol **`$` means "the address of this very
instruction"** (User's Guide §4.6.3). So `goto $` jumps to itself, forever — a deliberate,
one-line infinite loop. On a real chip the CPU would sit here spinning; on the simulator
you'll watch the program counter freeze at this address. It's the assembly equivalent of
`while(1);`.

> **Why `$` counts differently on different chips.** Any offset you add to `$` is measured in
> the chip's *native* addressing. On mid-range parts like ours, program memory is
> word-addressable, so `$+1` means "one instruction later." On PIC18 (byte-addressable) `$+2`
> is the next instruction. You won't hit this in `spin.S`, but file it away (User's Guide
> §4.6.3).

### `END resetVec` — that's all, folks
```asm
    END     resetVec
```
The `END` directive marks the end of the source file. Naming `resetVec` after it identifies
the program's entry point. Lines after `END` are ignored.

---

## 4.4 The rules for names (identifiers)

You invented three names above: `resetVec`, `main`, and the psect names. The assembler's
rules for legal names (User's Guide §4.6):

- Made of letters, digits, and the special characters `$`, `?`, `_`.
- **Cannot start with a digit or `$`.**
- **Case-sensitive** — `Main`, `main`, and `MAIN` are three different symbols. (Note that
  *instruction mnemonics and directives* are **not** case-sensitive: `goto`, `GOTO`, and
  `GoTo` are the same instruction. Only your identifiers care about case.)
- A name can't collide with a mnemonic (`goto`), a directive (`PSECT`), or an operator
  (`mod`, `and`).

Legal: `resetVec`, `_temp`, `loop1`, `?flag`. Illegal: `1st` (starts with digit), `$x`
(starts with `$`), `goto` (reserved).

---

## 4.5 Numbers, when you need them

`spin.S` uses only the literal `0h`, but you'll need the number rules immediately after this
chapter. The assembler's default radix is **decimal**, and other bases use a suffix or the
`0x` prefix (User's Guide §4.5):

| Base | How to write 255 | Rule |
|---|---|---|
| Decimal | `255` or `255D` | default; no suffix needed |
| Hexadecimal | `0xFF` or `0FFh` | `0x` prefix **or** `h` suffix; a `h`-suffixed number must start with a digit, so `0FFh`, not `FFh` |
| Binary | `11111111B` | uppercase `B` suffix |
| Octal | `377o` or `377q` | `o`/`q` suffix |

> **Trap:** `FFh` is an *error* — the assembler thinks it's an identifier. Write `0FFh`. This
> is the single most common "why won't my constant assemble?" mistake.

---

## 4.6 Build & run it

### On the command line
```
pic-as -mcpu=16f17146 -mdfp="$DFP" -Wl,-presetVec=0h \
       -Wa,-a -Wl,-Map=spin.map spin.S
```
Decoding the options (patterned on the Embedded Engineers guide §4.4):

- **`-mcpu=16f17146`** — the target device. Must match your `PROCESSOR` directive.
- **`-mdfp="$DFP"`** — the XC8 4.00 command-line path to the selected DFP's `xc8`
  directory; Chapter 3 shows how to set `DFP`. MPLAB X supplies it from the project pack.
- **`-Wl,-presetVec=0h`** — a *linker* option (`-Wl,` = "pass to linker"). It places our
  `resetVec` psect at address `0`, so our `goto main` lands on the reset vector the chip
  jumps to. This is the line that makes the whole thing actually run.
- **`-Wa,-a`** — a *assembler* option (`-Wa,` = "pass to assembler") requesting a **list
  file** (`spin.lst`) showing the machine code generated for each source line. Open it — it's
  the best way to *see* your instructions become bits.
- **`-Wl,-Map=spin.map`** — produce a **map file** showing where every psect ended up. We'll
  live in this file in Chapter 17.

### In your IDE
Create the project (Chapter 3): in VS Code run **`MPLAB: Create New Project`**, choose device
**PIC16F17146** and the **XC8 (pic-as)** toolchain, add `spin.S`, and build with **Ctrl+Shift+B**.
The reset-vector placement and list/map options are set through the project's build settings (in
MPLAB X IDE they go in Project Properties → pic-as Linker/Global Options, without the leading
`-Wl,`/`-Wa,`; Embedded Engineers guide §4.4).

### Watch it do nothing (productively)
Start the **MPLAB Debugger** simulator (Chapter 3: `Debug: Add Configuration` → MPLAB Debugger,
then **F5**), step once — you land on `resetVec`'s `goto main`. Step again — you're on `main`'s
`goto $`. Step a third time — the Program Counter doesn't move. That frozen PC *is* your endless
loop working. No hardware required.

---

## 4.7 What just happened

1. On Reset the PIC16F17146 fetched the instruction at **0x0000** (data sheet §9.1).
2. We had placed `goto main` there, so control jumped to `main`.
3. `main` ran `goto $`, jumping to itself forever.

Two instruction words of program memory, and you've exercised the reset vector, two psects, a
label, the location counter, and the whole build pipeline.

> **Why "uppercase `.S`"?** The uppercase extension tells the driver to run the **C
> preprocessor** over your file first, which is what makes `#include` and `#define` work
> (User's Guide §4.6.4). A lowercase `.s` skips preprocessing and your `#include <xc.inc>`
> would fail. When in doubt, use `.S`.

---

## 4.8 Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| `#include <xc.inc>` not found / SFR names undefined | file saved as lowercase `.s`, so no preprocessing | rename to uppercase `.S` |
| Code assembles but chip never runs your program | forgot `-Wl,-presetVec=0h`, so `resetVec` isn't at 0x0000 | add the linker option (or set psect origin in IDE) |
| Fixup/overflow or "won't fit" on a custom program-space psect | `delta` not set to 2 on a baseline/mid-range psect | add `delta=2` to that custom psect; provided psects already carry their flags |
| A hex constant like `FFh` reported as an unknown symbol | hex needs a leading digit | write `0FFh` or `0xFF` |
| "duplicate symbol" between your name and a keyword | you named something `and`, `mod`, `goto`… | rename the identifier |

(Cross-reference: Appendix C decodes the exact wording of these assembler messages.)

---

## 4.9 Try it yourself

1. **Break it on purpose.** Change `goto $` to `goto here` with no `here:` label. Build.
   Read the exact error text, then fix it by adding the label. (Learning to read errors is
   half of assembly.)
2. **Prove the reset vector matters.** Remove `-Wl,-presetVec=0h` from the build command,
   rebuild, and inspect `spin.map` — note where `resetVec` landed and predict whether the
   chip would run your code. Put the option back.
3. **Read the machine code.** Open `spin.lst` and find the opcode bytes generated for
   `goto main`. You don't need to decode them yet — just confirm that one source line became
   one instruction word.

---

## 4.10 Reference bridge

You're now ready to read these sections of the official **MPLAB XC8 PIC Assembler User's
Guide** without getting lost:

- **§4.2 Statement Formats** — the five shapes, formally.
- **§4.4 Comments** and **§4.5 Constants** — the full comment and number rules.
- **§4.6 Identifiers** — including the location counter `$` and how labels work.

**Next chapter:** `spin.S` runs on the simulator's defaults, but a *real* PIC16F17146 needs
its **Configuration bits** set — the oscillator, watchdog, and MCLR choices burned in
alongside your code. Chapter 5 adds the `CONFIG` block and explains why the chip won't
reliably start without it.
