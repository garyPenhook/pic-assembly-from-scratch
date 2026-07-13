# Documentation standard

This standard governs `Assembly from Scratch for PIC® Microcontrollers` and its source, examples, PDF, and releases.

## Publication scope

- Primary audience: beginners with basic programming knowledge and embedded engineers learning PIC assembly.
- Primary device: Microchip PIC16F17146, enhanced mid-range core.
- Secondary devices: PIC18F57Q43, PIC16F570, and PIC10F200 where a chapter explicitly says so.
- Primary toolchain: MPLAB® XC8 4.00, `pic-as`, and the stated Device Family Pack revision.
- Validation status must distinguish source review, assembly/link review, simulator testing, and hardware testing.

## Source authority

Use the narrowest authoritative source available: exact device data sheet and errata; programming and board guides; exact assembler/compiler/linker/utility guides; exact DFP metadata; release notes; official developer help; then secondary references. Record every high-risk claim in `SOURCE_INVENTORY.md` or the claims audit with:

```text
claim | target/core | tool/version | source | section/table/figure | verified date | notes
```

Never present an inference or a family-generalization as an exact-device rule. When sources disagree, state the scope and revision difference.

## Chapter contract

Technical chapters should contain, as appropriate:

1. What the reader will build or understand.
2. A plain-language mental model and defined terms.
3. A complete minimal example.
4. Line-by-line or field-by-field explanation.
5. Exact build, simulator, or hardware procedure.
6. Expected artifacts or observations.
7. Common failures and recovery.
8. Exercises.
9. A reference bridge with resolvable citations.

Every device-specific chapter begins with target/core, DFP/tool version, board assumptions, and validation status. Concept chapters may replace the build target with learning outcomes.

## Editorial rules

- Use direct, task-focused prose and short sentences.
- Define terms at first use and use one preferred spelling afterward.
- Use imperative language for procedures and present tense for system behavior.
- Use code formatting for commands, identifiers, registers, directives, filenames, and literal values.
- State address base, word/byte width, endianness, indexing, clock, voltage, and reset assumptions.
- Keep examples complete and reproducible; include device selection, required flags, configuration, linker options, and expected output.
- Separate generic core behavior from exact part behavior.
- Mark uncertainty, version dependence, untested runtime claims, and intentional exceptions.

Preferred terminology includes `PIC® microcontroller`, `MPLAB® XC8 toolchain`, `MPLAB® X integrated development environment`, `pic-as` assembler driver, `PSECT` directive, psect, bank, page, BSR, PCLATH, FSR, and compiled stack. Do not use product marks as ordinary plural or possessive nouns.

### Canonical terminology table

| Preferred form | Meaning and use | Avoid or reserve for code |
|---|---|---|
| `PIC® microcontroller` | Generic product-family descriptor in prose | Bare `PIC` as a count noun or possessive |
| PIC16F17146 / PIC18F57Q43 / PIC16F570 | Exact device part numbers; preserve datasheet spelling | Adding trademark symbols inside part numbers |
| PIC core / enhanced mid-range / PIC18® core | CPU architecture or family-level scope | Treating a part number as proof of its core |
| `MPLAB® XC8` toolchain | Microchip's XC8 package and associated tools | `MPLAB XC8's` as a possessive product name |
| `pic-as` | The XC8 PIC assembler driver/executable | `PIC-AS`, `pic-as assembler` when the executable is meant |
| `MPLAB® X` integrated development environment | The IDE product | `MPLAB X IDE` in new prose, except quoted UI/product text |
| `PSECT` directive / psect | Uppercase for the directive; lowercase for a section concept/name | Mixing `psect` and `PSECT` without a code/prose distinction |
| Device Family Pack (DFP) | Device metadata package used by tools | Treating a DFP as a datasheet or silicon specification |
| data memory / program memory | The two Harvard address spaces | Calling all storage “RAM” or “memory” without scope |
| bank / page | Data-memory bank or program-memory page | Using them interchangeably |
| compiled stack | Linker-allocated overlapping local storage | Calling it a hardware data stack or stack pointer |

Part numbers, assembler identifiers, command output, and quoted source text retain their original
spelling. The glossary in Appendix F is the reader-facing definition list; this table is the
editorial decision record used during review.

## Citations

Use ISO 690:2021 as the reference model. A chapter citation must identify the organization, exact document title, document number/revision, section/table/figure, date, and official URL or inventory key. Abbreviations such as `User's Guide`, `data sheet`, and `Emb Eng` are allowed only after a reference key has been declared.

## Trademarks and third-party material

Follow the current owner guidance. Microchip marks must use the appropriate `®`, `™`, or service-mark symbol at the prominent and required first uses, with an adjective and descriptor. Include Microchip ownership attribution and state that this is an independent publication not affiliated with, authorized, sponsored, or approved by Microchip Technology Incorporated.

Track copied or adapted text, code, tables, screenshots, diagrams, and logos in a permissions inventory. Attribution does not automatically grant reuse permission. Replace uncertain vendor material with original explanations or obtain permission/legal review.

## Example and verification requirements

Each canonical example records:

- source filename and target device;
- core, compiler/assembler, linker, utility, and DFP versions;
- required paths and flags;
- reset/configuration/clock assumptions;
- bank/page/memory-placement and calling-convention assumptions;
- expected map/listing/disassembly/HEX/simulator result;
- hardware or simulator validation status.

`make pdf` must build the book. `make lint` must check source consistency. `make verify` should run the available canonical assembly/link checks when the required XC8 and DFP paths are configured.

## PDF and release gate

Before a release, build from a known source state; check metadata, page count, links, bookmarks, fonts, and PDF syntax; render the cover, contents, prose, code/table pages, appendices, and final pages; inspect clipping, overflow, bad breaks, glyphs, contrast, and reading order; and record the PDF SHA-256.

Accessibility work must be tested against PDF/UA guidance and WCAG 2.2. Do not claim conformance without a checker and assistive-technology review.

Release notes must identify the exact commit, tag, PDF hash, toolchain/DFP versions, source-inventory date, validation date, and known limits such as untested hardware or unavailable simulator sessions.
