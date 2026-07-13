# Source inventory

Audit baseline: 2026-07-13. The revision printed in each official document is authoritative; filenames and web-page dates are not sufficient.

The complete local audit inventory is retained at `docs/microchip/SOURCE_INVENTORY.md` when reference material is available locally. Large vendor PDFs and DFP archives are intentionally not part of the source publication commit; use the official URLs below to obtain them.

## Primary target and toolchain

| Authority | Revision/baseline | Used for |
|---|---|---|
| PIC16F17126/46 Microcontrollers Data Sheet, DS40002343 | Rev. F, June 2026 | PIC16F17146 architecture, memory, registers, configuration, instruction set, peripherals |
| PIC16F17126/46 Silicon Errata, DS80001009 | Rev. E, June 2026 | Device-specific anomalies and clarifications |
| MPLAB XC8 PIC Assembler User's Guide, DS50002974 | Rev. E, October 2024 | `pic-as` syntax, directives, psects, linker, options, diagnostics, utilities |
| MPLAB XC8 v4.00 PIC Release Notes | build June 2026 | Current tool behavior, known issues, DFP requirements |
| PIC16F171XX Family Programming Specification, DS40002266 | Rev. B, August 2021 | ICSP, configuration words, programming algorithm, HEX use |
| PIC16F17146 Curiosity Nano Hardware User Guide, DS50003388 | Rev. B, March 2023 | Board wiring, LED, debugger, power, and programming setup |
| PIC16F1xxxx DFP | 1.31.465 | Device symbols, configuration tokens, headers, chip metadata |

Official URLs:

- [PIC16F17126/46 data sheet](https://ww1.microchip.com/downloads/aemDocuments/documents/MCU08/ProductDocuments/DataSheets/PIC16F17126-46-Microcontrollers-Data-Sheet-DS40002343.pdf)
- [PIC16F17126/46 errata](https://ww1.microchip.com/downloads/aemDocuments/documents/MCU08/ProductDocuments/Errata/PIC16F17126-46-Silicon-Errata-Datasheet-Clarifications-DS80001009.pdf)
- [XC8 PIC assembler guide](https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/UserGuides/MPLAB-XC8-PIC-Assembler-User-Guide-50002974.pdf)
- [XC8 4.00 release notes](https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/UserGuides/xc8-v4.00-full-install-release-notes-PIC.pdf)
- [PIC16F171XX programming specification](https://ww1.microchip.com/downloads/aemDocuments/documents/MCU08/ProductDocuments/ProgrammingSpecifications/PIC16F171XX-Family-Programming-Specification-40002266.pdf)
- [Curiosity Nano hardware guide](https://ww1.microchip.com/downloads/aemDocuments/documents/MCU08/ProductDocuments/UserGuides/PIC16F17146-CNANO-HW-UserGuide-DS50003388.pdf)
- [DFP download portal](https://packs.download.microchip.com/)

## Secondary devices

| Device | Required authority | Used for |
|---|---|---|
| PIC18F57Q43 | DS40002147H, DS80000870M, PIC18F-Q DFP 1.30.487 | Chapter 15–16 PIC18 interrupts, Access Bank, vectors, compiled-stack examples |
| PIC16F570 | DS40001684F, DS80000624B, PIC16Fxxx DFP 1.7.162 | Chapter 19 interrupt-capable enhanced-baseline behavior |
| PIC10F200 | DS40001239F, DS80194G, PIC10-12Fxxx DFP 1.8.184 | Chapter 19 plain-baseline behavior and call restrictions |

## Claims requiring explicit traceability

Maintain claim-level evidence for:

- configuration words and accepted token values;
- reset vectors, factory calibration words, and entry placement;
- bank/page reach, BSR/PCLATH behavior, linear-memory windows, and psect flags;
- instruction count, instruction width, addressing, and pseudo-instruction expansion;
- interrupt vectors, context save/restore, IVT layout, and peripheral register addresses;
- compiled-stack placement and C/assembly ABI assumptions;
- HEX format, programming, voltage, clock, pin, LED, and board behavior;
- XC8/DFP version-specific diagnostics and known issues.

Each claim must name the exact source section/table/figure and whether it was source-, build-, simulator-, or hardware-verified.
