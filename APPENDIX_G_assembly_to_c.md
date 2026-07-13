# Appendix G — From Assembly to C

> **Reference keys:** `[CUG]`, `[UG]`, and `[DS17146]` in `REFERENCES.md`.

You've learned to program the PIC16F17146 in pure assembly — the deepest way to understand a chip.
In practice, most production firmware is written in **C** (with the MPLAB® XC8 C compiler), dropping
to assembly only where it's genuinely needed. This appendix shows how your assembly knowledge fits
into a C world, so you can move fluidly between them.

---

## G.1 Why C, and why assembly still matters

C gives you loops, `if`/`else`, functions with real locals, and portability — the compiler handles
banking, paging, and the compiled stack for you. For most work it's faster to write and easier to
maintain. So why did learning assembly matter?

- **You now understand what C compiles *to*.** Banking, the reset vector, config bits, interrupt
  vectors, the compiled stack — C hides them, but you know they're there and can debug them.
- **You can read the disassembly.** When a C program misbehaves at the register level, the
  Disassembly view is just the assembly you already read fluently.
- **You can drop to assembly where it counts** — tight timing loops, a specific instruction
  sequence, or squeezing a few bytes — because the assembler and the C compiler **share the same
  assembly language** (User's Guide §2).

---

## G.2 The same tool underneath

This is the key connection: the assembler you've used **is the same assembler the XC8 C compiler
uses**. As the User's Guide puts it (§2), the internal assembler "is the same as that used by the
MPLAB XC8 C Compiler tool, with the assembly language being common between both tools." So the
`movlw`, `BANKSEL`, `PSECT`, and `CONFIG` you know carry straight over.

Config bits are a good example of the overlap. In assembly you wrote:
```asm
CONFIG "WDTE = OFF"
```
In C, the equivalent pragma is:
```c
#pragma config WDTE = OFF
```
Same settings, same values (the MPLAB X Configuration Bits window generates both forms).

---

## G.3 Inline assembly inside C

When you need a specific instruction sequence inside a C function, XC8 lets you embed assembly with
`__asm()` (XC8 C Compiler User's Guide DS50002737L §C language extensions):

```c
void exact_nop(void) {
    __asm("nop");
}
```

Each `__asm("…")` injects assembly text into the compiler's output; multiple instructions can be
separated with `\n`. The `asm()` spelling is also accepted, but the current C guide recommends
`__asm()`. Inline assembly is not optimized by the assembler optimizer, and the compiler cannot
infer all register/memory effects from an arbitrary text string. Keep snippets small. For an
unlock sequence, use the exact device header symbols, banking/access operands, and data-sheet
ordering—do not paste a generic PPS sequence across devices.

---

## G.4 Mixing whole assembly modules with C

You can also keep entire routines in assembly and call them from C, or vice-versa. An assembly
routine marked for external linkage can be declared `extern` in C and called like any C function,
provided it follows the compiler's current ABI. Symbol decoration, argument/return locations,
preserved state, reentrancy, and stack model can vary by core and compiler version, so inspect the
C-generated assembly and map rather than inventing a convention. The details are documented in
the **MPLAB XC8 C Compiler User's Guide for PIC MCU (DS50002737L)**, which the
assembler guide points to for "writing assembly code to be linked with C source code, or... in-line
with C code" (User's Guide §2).

---

## G.5 A suggested path forward

1. **Rebuild a book example in C.** Take the Chapter 14 timer-blink and write it in XC8 C —
   `TMR0` setup, an interrupt function, a pin toggle. Compare the compiler's disassembly to the
   assembly you wrote; you'll recognize every instruction.
2. **Read one map file from a C build.** The same psect/class/map vocabulary applies, although C
   emits additional compiler-managed sections and runtime support.
3. **Drop to `__asm()` once.** Find a spot in a C program that needs an exact instruction sequence
   and write it inline. That's the sweet spot where your assembly fluency pays off.
4. **Keep the data sheet habit.** Whether in C or assembly, confirm every register, bit, and config
   setting against the device data sheet before you rely on it — the discipline this whole book was
   built on.

---

## G.6 Reference

- **User's Guide §2 "Assembler Overview"** — the shared assembler and assembly language between the
  PIC assembler and the XC8 C compiler.
- **MPLAB XC8 C Compiler User's Guide for PIC MCU DS50002737L** — the authoritative guide to C, to
  mixing C with assembly, and to the calling convention.

---

*That's the end of the book. You started not knowing what a file register was; you can now write,
build, simulate, flash, and debug PIC assembly from the reset vector up — and read the official
Microchip guides without getting lost. Go build something.*
