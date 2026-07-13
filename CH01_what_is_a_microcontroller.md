# Chapter 1 — What Is a Microcontroller?

> **Reference keys:** `[DS17146]` and `[UG]` in `REFERENCES.md`.

> **What you'll take away:** a clear mental picture of what's actually inside the chip you're
> about to program — the CPU, the two kinds of memory, the working register, and the idea of an
> instruction set. No code yet; this chapter builds the map you'll navigate for the rest of the
> book. It ends with a labeling exercise, not a build.

---

## 1.1 A whole computer on one chip

A **microcontroller** (MCU) is a complete little computer squeezed onto a single chip: a processor,
its memory, and a set of built-in peripherals, all together. That's the difference from the CPU in
a laptop — a desktop processor needs external RAM chips, storage, and support hardware, while a
microcontroller has everything it needs to run a program on board the moment you power it up.

Our chip for this book, the **PIC16F17146**, is a textbook example. Its block diagram (data sheet
DS40002343F, Figure 1) shows three things clustered together (data sheet §"Block Diagram"):

- a **CPU** — the part that executes instructions,
- **memory** — Program Flash Memory, Data Memory (RAM), and Data EEPROM,
- **peripherals** — timers, an analog-to-digital converter, serial ports, I/O ports, and more.

You write a program, it gets stored in the chip's flash, and on power-up the CPU starts executing
it — driving pins, reading sensors, talking to other devices. That's embedded programming: software
that reaches out and touches the physical world.

---

## 1.2 Two separate memories: the Harvard design

Here's the first idea that shapes *everything* in PIC® assembly. On a PIC® microcontroller, **program memory and data
memory are physically separate**, on their own buses. The data sheet states it plainly (§9):

> "In Harvard architecture devices, the data and program memories use separate buses that allow for
> concurrent access of the two memory spaces."

This is the **Harvard architecture**, and it has two big consequences you'll feel throughout the
book:

- **Your instructions live in one place, your variables in another.** Program Flash holds the
  code; Data RAM holds the variables your code manipulates. They're different memories with their
  *own address 0* — program address 0 and data address 0 are completely different physical
  locations. (This is why Chapter 10's `space` flag and Chapter 17's map-file "Space" column exist —
  the tools must always know *which* memory you mean.)
- **The chip can fetch the next instruction while working on data**, because the two buses don't
  compete. That's part of why PICs are efficient at their clock speed.

The PIC16F17146 actually has **three** memory regions (data sheet §9):

| Memory | Holds | Volatile? |
|---|---|---|
| **Program Flash Memory** | your program (instructions) + constants | no — keeps its contents with power off |
| **Data Memory (RAM)** | your variables while the program runs | yes — loses its contents when power is removed |
| **Data EEPROM** | small amounts of data you want to survive power-off | no |

For now, remember the headline: **code and variables live in separate worlds.** Keeping that
straight is half of understanding PIC assembly.

---

## 1.3 Inside the CPU: the working register

The CPU is where instructions execute. The PIC16F17146 uses what Microchip calls an **enhanced
mid-range 8-bit core** with **50 instructions** and, at its center, a single 8-bit scratch register
called **W — the Working register** (data sheet §7). A great many operations flow through W: you
load a value into it, the arithmetic-logic unit (ALU) combines it with something, and the result can
go back to W or to a file register.

Three pieces of the CPU are worth naming now (you'll meet them all again):

- **W (Working register)** — the 8-bit accumulator that most instructions read from or write to.
- **The ALU** — the arithmetic-logic unit that adds, subtracts, and does bitwise operations.
- **The STATUS register** — a set of flags (like "the last result was zero" or "there was a carry")
  that the ALU updates as a side effect.

"8-bit" means the natural unit of work is a **byte** — a value from 0 to 255. When you need bigger
numbers you'll glue bytes together (Chapter 11), but the CPU handles them one byte at a time.

---

## 1.4 What an "instruction set" is

The CPU only understands a fixed, finite menu of very small operations — its **instruction set**.
Each instruction does one tiny thing: "load this constant into W," "add this register to W," "if
this bit is set, skip the next instruction," "jump to that address." The PIC16F17146's menu has
exactly **50 instructions** (data sheet §7.4).

That's the whole vocabulary. There's no `print`, no `if/else`, no `while` — you *build* those out of
the primitive instructions. Assembly programming is the craft of expressing what you want using
only that small menu. It feels restrictive at first and then, surprisingly quickly, becomes a kind
of clarity: nothing is hidden, and you know exactly what the chip does on every cycle.

Each instruction is stored as a number (an **opcode**) in program memory. The **assembler** — the
tool this book is about — is what translates the human-readable mnemonics you type (`movlw`,
`addwf`, `goto`) into those opcodes. You write `movlw 0x2A`; the assembler emits the bits the CPU
recognizes.

---

## 1.5 The shape of a PIC program

Putting it together, here's the life of a PIC program, which the rest of the book fills in:

1. You write assembly instructions in a text file.
2. The **assembler** turns them into opcodes and the **linker** places them at real addresses in
   program flash, producing a **HEX file** (Chapters 17–18).
3. A **programmer** burns the HEX into the chip's flash (Chapter 18).
4. On power-up or reset, the CPU begins fetching and executing instructions from a fixed starting
   point — the **reset vector** (Chapter 4).
5. The firmware remains in control until a reset or loss of power; it normally loops, waits, or
   sleeps rather than "exiting" to an operating system.

You now have the map: a CPU with a working register and a 50-instruction menu, two separate
memories for code and data, peripherals to reach the outside world, and a toolchain that turns your
text into something the chip runs.

---

## 1.6 Common misconceptions

| Belief | Reality |
|---|---|
| "Variables and code share one memory like on a PC" | PICs are Harvard: program and data memory are separate, with their own address spaces (§9) |
| "The CPU can do big operations in one step" | it's 8-bit — it works a byte at a time; larger values are built up (Chapter 11) |
| "Assembly has loops and if-statements" | it has only ~50 primitive instructions; you build control flow from them |
| "The chip needs external RAM/storage" | a microcontroller has its memory and peripherals on board |

Volatile does **not** mean "automatically initialized to zero." General-purpose RAM does not have a
defined power-up value on this device; startup code must initialize every variable before relying on
it. Volatile means only that RAM does not retain its state when power is removed.

---

## 1.7 Try it yourself

1. **Label the block diagram.** Open the PIC16F17146 data sheet to its Block Diagram (Figure 1) and
   identify, in your own words, the CPU, the three memories, and three peripherals. Sketch it.
2. **Sort the list.** For each item — "an LED blink pattern," "the current sensor reading," "a
   calibration constant that must survive power-off" — decide whether it belongs in Program Flash,
   Data RAM, or Data EEPROM, and why.
3. **Count to 255.** Explain in one sentence why an 8-bit register can hold values only from 0 to
   255, and predict what happens when you add 1 to 255. (You'll confirm it in Chapter 11.)

---

## 1.8 Reference bridge

- **Data sheet §7 "Enhanced Mid-Range CPU"** — the core, the W register, the ALU, and the
  50-instruction set at a glance.
- **Data sheet §9 "Memory Organization"** — the three memories and the Harvard split.
- **Data sheet "Block Diagram" (Figure 1)** — the whole chip on one page.

**Next chapter:** the PIC16F17146 is one of several PIC "cores." Chapter 2 places it in the family —
baseline, mid-range, enhanced mid-range, and PIC18 — so you understand what's specific to our chip
and what carries across the whole 8-bit PIC line.
