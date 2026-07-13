# Assembly from Scratch for PIC® Microcontrollers

**A Beginner's Guide with MPLAB® XC8**

Assembly from Scratch for PIC® Microcontrollers is a practical, simulator-first introduction to writing, building, understanding, and programming Microchip PIC® microcontrollers with the modern `pic-as` assembler included with the MPLAB® XC8 toolchain. The book uses the PIC16F17146 as its main teaching device and then broadens the discussion to other PIC® cores and real production workflows.

The goal is to make the path from a blank assembly file to programmed silicon understandable. Each major idea is introduced with an explanation, a small assembly example, the relevant linker or device behavior, common mistakes, and a hands-on exercise.

## What the book covers

### Foundations

- What a microcontroller is and how Harvard architecture, program memory, data memory, the working register, and instruction sets fit together.
- The differences between baseline, mid-range, enhanced mid-range, and PIC18 cores.
- Installing and using the MPLAB® X integrated development environment, the MPLAB® XC8 toolchain, `pic-as`, device packs, simulators, and command-line builds.
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
- PIC18® interrupt concepts and the architectural differences that matter when moving up a core.
- The compiled stack, calling conventions, C interoperability, and how assembly interacts with compiler-generated code.
- Reading linker map files, understanding placement decisions, generating HEX files, and programming the chip.
- Baseline and enhanced-baseline devices, including their reset and page-placement constraints.

### Reference material

The appendices provide an instruction-set quick reference, directive reference card, error and warning guide, MPLAB® X and `pic-as` option reference, MPASM™-to-XC8 migration notes, glossary, and a bridge from assembly concepts to C.

## Intended audience

This book is for beginners who want to learn PIC® assembly, C developers who need to understand what the compiler emits, and embedded engineers migrating older MPASM™ projects to the MPLAB® XC8 `pic-as` toolchain. It assumes basic digital logic and command-line familiarity, but introduces the assembly and linker concepts from the ground up.

## Main device and toolchain

- Main teaching device: **Microchip PIC16F17146**
- Toolchain: **MPLAB® X integrated development environment**, **MPLAB® XC8**, and the **`pic-as` assembler**
- Workflow: simulator-first, then build, inspect, flash, and debug on hardware

Always verify register definitions, configuration settings, electrical limits, programming procedures, and toolchain behavior against the current Microchip documentation for the exact device and compiler version in use.

## Supported environment

| Component | Book baseline | Notes |
|---|---|---|
| Main device | PIC16F17146 | Enhanced mid-range; Chapters 1–14 and 17–18 |
| Secondary devices | PIC18F57Q43, PIC16F570, PIC10F200 | Scoped explicitly in Chapters 15–16 and 19 |
| Assembler | MPLAB® XC8 `pic-as` 4.00 | Standalone builds require an external DFP path |
| DFPs | PIC16F1xxxx 1.31.465; PIC18F-Q 1.30.487; PIC16Fxxx 1.7.162 | See `SOURCE_INVENTORY.md` |
| GUI workflows | VS Code MPLAB® Extensions; MPLAB® X IDE | Procedures identify which path they use |
| Runtime validation | Source/build verified | Hardware and simulator results require a dated test log |

## Get the book

The latest rendered PDF is available from the repository's [Releases](https://github.com/garyPenhook/pic-assembly-from-scratch/releases) page.

## Build the PDF locally

The project uses Pandoc and XeLaTeX:

```sh
make pdf
```

The result is written to `output/pdf/pic-assembly-from-scratch.pdf`. The Markdown source files, Pandoc metadata, LaTeX styling, and cover are included in this repository so the book can be revised and rebuilt.

## Repository layout

- `manuscript/` — all book parts, chapters, appendices, navigation, and references
- `PERMISSIONS_INVENTORY.md` — third-party material and reuse review register
- `manuscript/NAVIGATION.md` — chapter, appendix, and maintenance reading map
- `VALIDATION_STATUS.md` — example and runtime-validation boundaries
- `PDF_REVIEW.md` — latest PDF structure and visual review record
- `RELEASE_BLOCKERS.md` — remaining accessibility and licensing gates
- `book/` — parts, metadata, cover, and styling
- `verify/` — small assembly examples and verification sources
- `output/pdf/` — the current rendered book PDF
- `Makefile` — reproducible PDF build command

## Reading and maintenance navigation

- Start with [Chapter 1](manuscript/CH01_what_is_a_microcontroller.md), then follow the numbered chapters through [Chapter 19](manuscript/CH19_baseline.md).
- Use [Appendix A](manuscript/APPENDIX_A_instruction_set.md) through [Appendix G](manuscript/APPENDIX_G_assembly_to_c.md) as the reference section.
- Check [References](manuscript/REFERENCES.md) for source keys and [Validation status](VALIDATION_STATUS.md) for what has actually been verified.
- Maintainers should follow the [documentation standard](DOCUMENTATION_STANDARD.md), run `make lint`, and use the [verification workflow](verify/README.md) before publishing.

## Trademark and independence notice

Microchip, the Microchip logo, PIC®, MPLAB®, PIC18®, and MPASM™ are trademarks or registered trademarks of Microchip Technology Incorporated in the U.S.A. and other countries. MPLAB® XC8, `pic-as`, and Hexmate are Microchip products or tools. All other marks are the property of their respective owners. This is an independent publication and is not affiliated with, authorized, sponsored, or otherwise approved by Microchip Technology Incorporated.

## License and references

See [LICENSE](LICENSE) for the project license. Microchip names and documentation remain the property of Microchip Technology Incorporated; consult the official device and toolchain documentation for authoritative details.
