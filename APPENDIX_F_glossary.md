# Appendix F — Glossary

Plain-language definitions of the terms used in this book. The chapter in brackets is where the
term is introduced or explained in depth.

## Quick index

[A](#a) · [B](#b) · [C](#c) · [D](#d) · [E](#e) · [F](#f) · [G](#g) · [H](#h) · [I](#i) · [L](#l) · [M](#m) · [O](#o) · [P](#p) · [R](#r) · [S](#s) · [T](#t) · [W](#w)

## A

---

**Access bank** — On PIC18®, a region of data memory reachable without bank selection (the PIC18
counterpart to mid-range common RAM). *(Ch 15)*

**ALU (Arithmetic-Logic Unit)** — The part of the CPU that performs arithmetic and bitwise
operations, working through the W register. *(Ch 1)*

**ANSEL (ANSELx)** — The analog-select register for a port. A pin defaults to *analog* after reset;
clear its ANSEL bit to make it a digital I/O. *(Ch 7)*

**ARCH** — The core-architecture value in a device's INI file (`PIC12`, `PIC14E`, `PIC18`, …) that
tells the assembler which core it's building for. *(Ch 2)*

**Assembler** — The tool (`pic-as`) that translates mnemonic instructions and directives into
machine-code opcodes in an object file. *(Ch 1, 3)*

## B

**Bank / Banking** — A core-specific division of data memory. PIC16F17146 uses 128-byte banks and
BSR selection; PIC18 banks are 256 bytes; small baseline devices use their own STATUS/BSR rules.
*(Ch 8, 15, 19)*

**Baseline** — A 12-bit-instruction PIC core. DFP `PIC12` denotes plain baseline (for example,
PIC10F200 without interrupts); `PIC12E` and `PIC12IE` are enhanced variants, with `PIC12IE`
explicitly interrupt-capable (for example, PIC16F570). *(Ch 2, 19)*

**BSR (Bank Select Register)** — On enhanced mid-range/PIC18 and some enhanced-baseline devices,
holds the current data-memory bank number; `BANKSEL` emits the core-appropriate selection code.
*(Ch 8)*

## C

**Common RAM** — On PIC16F17146, 16 bytes at bank offsets 0x70–0x7F mirrored into every bank, so
they need no `BANKSEL`. Other devices have different shared/Access regions. *(Ch 6, 8, 15)*

**Compiled stack** — A linker-allocated region for routine-local variables, with the locals of
non-overlapping routines reused to save RAM. No stack pointer; not reentrant. *(Ch 16)*

**Config bits (Configuration Words)** — Nonvolatile settings (oscillator, watchdog, MCLR,
protection) read at start-up; set with `CONFIG`. Their number and fields are device-specific.
*(Ch 5)*

**Core** — A CPU design shared across many PICs, distinguished mainly by instruction width
(baseline 12-bit, mid-range/enhanced 14-bit, PIC18 16-bit). *(Ch 2)*

## D

**delta (psect flag)** — Bytes per program-memory address. Mid-range code is word-addressable, so
code psects use `delta=2`; data uses `delta=1`. *(Ch 10)*

**DFP (Device Family Pack)** — A package that teaches the tools a specific chip's registers, config
bits, and memory. *(Ch 3)*

**Directive** — An order to the assembler (e.g. `PSECT`, `EQU`, `CONFIG`), not a CPU opcode.
Some generate instructions (`BANKSEL`, `PAGESEL`), data (`DW`), or reserved storage (`DS`).
*(Ch 4, 12; App B)*

## E

**EEPROM (Data EEPROM)** — Small non-volatile data memory that survives power-off, accessed like a
peripheral. *(Ch 1)*

**Enhanced mid-range** — The 14-bit core of our PIC16F17146: mid-range plus more instructions,
automatic interrupt context saving, and linear memory. *(Ch 2)*

## F

**File register** — Any addressable byte of data memory — including SFRs and W itself. *(Ch 6)*

**FSR / INDF** — The two 16-bit File Select Registers hold addresses; reading/writing `INDFn`
accesses the byte the FSR points to (indirect addressing). *(Ch 11)*

## G

**GIE (Global Interrupt Enable)** — The master interrupt-enable bit; on PIC16F17146 it is
`INTCON` bit 7, while PIC18 naming/priority gates can differ. *(Ch 14, 15)*

## H

**Harvard architecture** — Separate program and data memories on separate buses, each with its own
address 0. *(Ch 1)*

**HEX file** — The Intel-HEX program image (records of data + checksum) that a programmer burns into
the chip. Uses byte addresses. *(Ch 18)*

**Hexmate** — The utility that manipulates HEX files (merge, checksum, fill, convert). *(Ch 18)*

## I

**INTCON** — On PIC16F17146, the core Interrupt Control register at mirrored offset 0x0B
(including GIE, PEIE, and INTEDG). Other cores/devices may use `INTCON0`/`INTCON1` or different
layouts. *(Ch 14, 15, 19)*

**Interrupt / ISR** — A hardware event that redirects the CPU to a service routine. PIC16F17146
and PIC16F570 use vector 0x0004; PIC18F57Q43 can use a vector table or legacy 0x08/0x18 vectors.
Return is via the core-appropriate `RETFIE`. *(Ch 14, 15, 19)*

## L

**LAT (LATx)** — The output-latch register; write here to drive a pin (safer than writing `PORTx`).
*(Ch 7)*

**Linear memory** — A virtual FSR view (0x2000–0x2FEF) that stitches every bank's GPR into one
contiguous run, for buffers larger than one bank. *(Ch 11)*

**Linker** — The tool that gathers psects, places each in its class's address range, resolves
symbols, and emits the HEX. *(Ch 10, 17)*

**Literal** — A constant value baked into an instruction (e.g. the `k` in `movlw k`). *(Ch 6)*

## M

**Macro** — A named block of source text the assembler pastes in wherever it's invoked (compile
-time reuse). *(Ch 13)*

**Map file** — The linker's report of where every psect and global symbol landed. *(Ch 17)*

**Mid-range** — The classic 14-bit PIC core with banking and paging. *(Ch 2)*

## O

**Opcode** — The numeric machine-code form of an instruction, stored in program memory. *(Ch 1)*

**Page / Paging** — On enhanced mid-range, `CALL`/`GOTO` address a 2048-word page and PCLATH
supplies upper bits. Baseline pages and `CALL` entry restrictions differ; PIC18 does not need
`PAGESEL`. *(Ch 9, 15, 19)*

## P

**PCLATH** — The register supplying the high program-counter bits for `goto`/`call` (the "page
register"). *(Ch 9)*

**PEIE (Peripheral Interrupt Enable)** — On PIC16F17146, `INTCON` bit 6 gates PIE1–PIE6 sources
(PIE0 sources do not use it). Other devices differ. *(Ch 14)*

**PIC18** — The 16-bit top of the 8-bit line; expanded registers, `movff`, vectored/prioritized
interrupts on many parts. *(Ch 2, 15)*

**PORT (PORTx)** — Reading it returns the pin levels; writing it writes the latch (prefer `LATx` for
output). *(Ch 7)*

**PPS (Peripheral Pin Select)** — Maps digital peripheral signals to I/O pins. Not needed for a
software-driven LED (pins default to their data latch). *(Ch 7)*

**Program memory (Program Flash)** — Non-volatile memory holding your instructions and constants.
*(Ch 1)*

**Psect (program section)** — A named, relocatable block of code or data the linker places into
memory. *(Ch 10)*

## R

**Reset vector** — The device-defined program address fetched after Reset. It is 0x0000 on the
PIC16F17146 and PIC18F57Q43; PIC16F570 instead fetches its factory calibration word at 0x7FF and
then rolls over to user entry 0. *(Ch 4, 15, 19)*

**RETFIE** — Return-from-interrupt: pops the return address and re-enables interrupts. Automatic
context restoration is core-specific: PIC16F17146 and PIC16F570 switch shadow/secondary state;
PIC18F57Q43 uses `retfie f` to restore its fast WREG/STATUS/BSR stack. *(Ch 14, 15, 19)*

## S

**Shadow registers** — On PIC16F17146, Bank-63 copies of WREG, STATUS, BSR, PCLATH, FSR0, and
FSR1 used for automatic interrupt context saving. Other cores save a different set or require an
explicit fast-return mode. *(Ch 14, 15, 19)*

**space (psect flag)** — Which memory space a psect lives in: `0` = program, `1` = data (resolves
the Harvard address overlap). *(Ch 10, 17)*

**STATUS** — A core status register holding ALU flags such as Z, C, and DC plus core-specific
status/page fields. Its exact bits are device-specific. *(Ch 1, 11, 19)*

## T

**TRIS (TRISx)** — The data-direction register: bit `0` = output, `1` = input. *(Ch 7)*

## W

**W (Working register)** — The 8-bit accumulator most instructions read from or write to; also a
file register named `WREG`. *(Ch 1, 6)*
