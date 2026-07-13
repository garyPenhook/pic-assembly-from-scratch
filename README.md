# PIC Assembly from Scratch

**A Beginner's Guide with MPLAB XC8**

PIC Assembly from Scratch is a practical, simulator-first introduction to writing, building, understanding, and programming PIC microcontrollers with the modern `pic-as` assembler included with MPLAB XC8. The book uses the PIC16F17146 as its main teaching device and then broadens the discussion to other PIC cores and real production workflows.

The goal is to make the path from a blank assembly file to programmed silicon understandable. Each major idea is introduced with an explanation, a small assembly example, the relevant linker or device behavior, common mistakes, and a hands-on exercise.

## What the book covers

### Foundations

- What a microcontroller is and how Harvard architecture, program memory, data memory, the working register, and instruction sets fit together.
- The differences between baseline, mid-range, enhanced mid-range, and PIC18 cores.
- Installing and using MPLAB X, MPLAB XC8, `pic-as`, device packs, simulators, and command-line builds.
- The anatomy of an assembly source file: labels, mnemonics, operands, directives, comments, configuration, reset vectors, and entry points.

### Core PIC programming

- Configuration bits, oscillator setup, reset behavior, and the reset vector.
- Moving literals and bytes through `W`, file registers, RAM, and special function registers.
- GPIO initialization and a complete first-blink workflow.
- Data-memory banking, program-memory pages, computed jumps, and the difference between a bank and a page.
- Psects, classes, sections, linker placement, alignment, and the relationship between source declarations and the final map file.
- Linear data memory, indirect addressing, FSRs, larger variables, buffers, and pointer-style code.

### Building real programs

- `equ`, `set`, `ds`, `db`, `dw`, conditional assembly, macros, and multiple source files.
- Interrupt setup and service routines on the PIC16F17146.
- PIC18 interrupt concepts and the architectural differences that matter when moving up a core.
- The compiled stack, calling conventions, C interoperability, and how assembly interacts with compiler-generated code.
- Reading linker map files, understanding placement decisions, generating HEX files, and programming the chip.
- Baseline and enhanced-baseline devices, including their reset and page-placement constraints.

### Reference material

The appendices provide an instruction-set quick reference, directive reference card, error and warning guide, MPLAB X and `pic-as` option reference, MPASM-to-XC8 migration notes, glossary, and a bridge from assembly concepts to C.

## Intended audience

This book is for beginners who want to learn PIC assembly, C developers who need to understand what the compiler emits, and embedded engineers migrating older MPASM projects to the XC8 `pic-as` toolchain. It assumes basic digital logic and command-line familiarity, but introduces the assembly and linker concepts from the ground up.

## Main device and toolchain

- Main teaching device: **Microchip PIC16F17146**
- Toolchain: **MPLAB X IDE**, **MPLAB XC8**, and the **`pic-as` assembler**
- Workflow: simulator-first, then build, inspect, flash, and debug on hardware

Always verify register definitions, configuration settings, electrical limits, programming procedures, and toolchain behavior against the current Microchip documentation for the exact device and compiler version in use.

## Get the book

The latest rendered PDF is available from the repository's [Releases](https://github.com/garyPenhook/pic-assembly-from-scratch/releases) page.

## Build the PDF locally

The project uses Pandoc and XeLaTeX:

```sh
make pdf
```

The result is written to `output/pdf/pic-assembly-from-scratch.pdf`. The Markdown source files, Pandoc metadata, LaTeX styling, and cover are included in this repository so the book can be revised and rebuilt.

## Repository layout

- `CH*.md` — book chapters
- `APPENDIX_*.md` — reference appendices
- `book/` — parts, metadata, cover, and styling
- `verify/` — small assembly examples and verification sources
- `output/pdf/` — the current rendered book PDF
- `Makefile` — reproducible PDF build command

## License and references

See [LICENSE](LICENSE) for the project license. Microchip names and documentation remain the property of Microchip Technology Incorporated; consult the official device and toolchain documentation for authoritative details.
