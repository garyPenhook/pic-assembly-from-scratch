# Chapter 2 — Meet the PIC Cores

> **What you'll take away:** a map of the 8-bit PIC family — **baseline**, **enhanced baseline**,
> **mid-range**, **enhanced mid-range**, and **PIC18** — so you know exactly where our
> PIC16F17146 sits and what you're learning that transfers to every other PIC. Knowing the cores
> tells you which chapters of this book apply to which chips.

---

## 2.1 Why there are "cores" at all

Microchip's 8-bit PICs span everything from a 6-pin chip costing pennies to a feature-packed 40-pin
controller. To cover that range they share a handful of **cores** — CPU designs that differ mainly
in the **width of their instruction set** and the features built around it. Pick a core and you've
picked the instruction menu, the memory style, and the interrupt model.

The assembler groups every device into one of these cores, recorded as an **ARCH value** in the
device's INI file (data sheet info comes from your Device Family Pack; User's Guide §2.1). Here's
the whole family, straight from the User's Guide §2.1:

| Core | Instruction width | Notes | ARCH |
|---|---|---|---|
| **Baseline** | 12-bit | smallest, fewest instructions (PIC10/12/16) | `PIC12` |
| **Enhanced baseline** | 12-bit | baseline + extra instructions; *some* support interrupts | `PIC12E` / `PIC12IE` |
| **Mid-range** | 14-bit | more instructions, larger banks and pages | `PIC14` |
| **Enhanced mid-range** | 14-bit | mid-range + more instructions and features | `PIC14E` / `PIC14EX` |
| **PIC18** | 16-bit | expanded register set; extended data memory and vectored interrupts on some parts | `PIC18` / `PIC18XV` |

Read it as a ladder. As you climb, the instruction set widens (12 → 14 → 16 bits), more instructions
appear, memory grows, and the interrupt system gets richer.

---

## 2.2 The cores, one at a time

**Baseline (12-bit).** The floor of the range — tiny PIC10, PIC12, and small PIC16 parts. A 12-bit
instruction set means the fewest instructions and the tightest memory. Most baseline parts have **no
interrupts**, and their `call` instruction has a placement quirk you'll meet in Chapter 19. Great
for the smallest, cheapest jobs.

**Enhanced baseline (12-bit).** Still a 12-bit instruction set, but with additional instructions;
some of these chips add interrupt support (the `PIC12IE` ARCH), which basic baseline lacks
(User's Guide §2.1).

**Mid-range (14-bit).** The classic PIC middle ground — a 14-bit instruction set with more
instructions than baseline, plus larger data-memory banks and program-memory pages (User's Guide
§2.1). This is the world of banking and paging you'll spend Part III mastering.

**Enhanced mid-range (14-bit).** Mid-range plus extra instructions and features — and **this is our
core.** The data sheet confirms the PIC16F17146 "contains an enhanced mid-range 8-bit CPU core"
with 50 instructions, automatic interrupt context saving, a 16-level stack, and two File Select
Registers (data sheet §7). It has the modern conveniences — a single vectored interrupt with
hardware context saving (Chapter 14), linear data memory (Chapter 11), and a rich peripheral set —
while keeping the 14-bit instruction set.

**PIC18 (16-bit).** The top of the 8-bit line: a 16-bit instruction set and an expanded register set.
Interrupt hardware varies by device: traditional PIC18 parts use fixed high/low interrupt vectors,
while some newer parts add extended data memory and a **vectored interrupt controller** with
programmable priorities (User's Guide §2.1). Chapters 15 and 16 visit PIC18 so your skills carry
upward.

---

## 2.3 Where the PIC16F17146 sits — and why it's a good teacher

Our chip is **enhanced mid-range**, deliberately chosen as the spine of this book because it's the
sweet spot for learning:

- It's **modern and full-featured** — the peripherals, interrupt model, and memory layout match
  what you'll meet on current parts, not a 1990s design.
- It still has the **core challenges that make you a real PIC programmer** — banking and paging
  (Part III) — which the simplest chips hide and the biggest chips paper over.
- What you learn **transfers both directions**: down to baseline (Chapter 19) and up to PIC18
  (Chapters 15–16), because every core shares the same fundamentals — a W register, file registers,
  psects, a reset vector, and the same assembler.

Learn this one core deeply and you can sit down with almost any 8-bit PIC data sheet and be
productive.

---

## 2.4 "Which core is my chip?"

When you pick up any PIC, identify its core first — it tells you which rules apply:

1. **Check the data sheet's CPU chapter.** It will name the core (e.g. "enhanced mid-range 8-bit
   CPU," as ours does in §7).
2. **Check the ARCH value** in the device's INI file if you're unsure (User's Guide §2.1) — `PIC14E`
   means enhanced mid-range, `PIC18` means PIC18, and so on.
3. **Match it to this book:** the main chapters target enhanced mid-range; Chapter 19 covers
   baseline differences; Chapters 15–16 cover PIC18 differences.

A rough field guide by part number (always confirm against the data sheet): **PIC10/PIC12** are
often baseline; many **PIC16F1xxxx** parts (like ours) are enhanced mid-range; **PIC18F...** parts
are PIC18. But the number alone isn't definitive — the data sheet is the authority.

---

## 2.5 Common misconceptions

| Belief | Reality |
|---|---|
| "All PICs use the same assembly" | the cores differ in instruction width and features; syntax is shared but capabilities aren't (§2.1) |
| "A bigger part number means a different language" | it means a different *core*; the fundamentals (W, psects, reset vector) are the same |
| "Enhanced mid-range is just mid-range" | it adds instructions, features, automatic interrupt context saving, and linear memory (§7) |
| "Every PIC18 has the same interrupt system" | PIC18 devices range from fixed high/low vectors to newer vectored, prioritized controllers; check the exact device (§2.1; Chapter 15) |

---

## 2.6 Try it yourself

1. **Place three chips.** Look up a PIC10F200, a PIC16F17146, and a PIC18F57Q43, and state each
   one's core. Which chapters of this book apply most directly to each?
2. **Find the ARCH.** In the PIC16F17146 data sheet §7, find the sentence that names its core.
   Confirm it's enhanced mid-range.
3. **Predict the transfer.** Name one skill from later chapters (say, banking) and argue whether it
   applies to baseline, to PIC18, or to both.

---

## 2.7 Reference bridge

- **User's Guide §2.1 "Device Description"** — the authoritative descriptions of all five cores and
  their ARCH values.
- **Data sheet §7 "Enhanced Mid-Range CPU"** — confirms our chip's core and its capabilities.

**Next chapter:** you know what a microcontroller is and which core we're using. Chapter 3 gets the
tools onto your computer — MPLAB X IDE, the XC8 assembler, and the Device Family Pack for the
PIC16F17146 — and builds your first (empty) project, so you're ready to write real code in Part II.
