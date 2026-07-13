# References and source keys

This book uses short keys in chapter reference bridges. Each key resolves to the exact source, revision, scope, and official location below. Device-specific claims always take precedence over family-general descriptions.

## Primary target and toolchain

**[DS17146]** Microchip Technology Inc., *PIC16F17126/46 Microcontrollers Data Sheet*, DS40002343F, June 2026. Exact PIC16F17146 architecture, memory, registers, configuration, instruction set, peripherals, and electrical limits. Official source: [DS40002343F](https://ww1.microchip.com/downloads/aemDocuments/documents/MCU08/ProductDocuments/DataSheets/PIC16F17126-46-Microcontrollers-Data-Sheet-DS40002343.pdf).

**[ER17146]** Microchip Technology Inc., *PIC16F17126/46 Silicon Errata*, DS80001009E, June 2026. Device-specific anomalies and data-sheet clarifications. Official source: [DS80001009E](https://ww1.microchip.com/downloads/aemDocuments/documents/MCU08/ProductDocuments/Errata/PIC16F17126-46-Silicon-Errata-Datasheet-Clarifications-DS80001009.pdf).

**[UG]** Microchip Technology Inc., *MPLAB® XC8 PIC Assembler User's Guide*, DS50002974E, October 2024. `pic-as` driver, syntax, instruction deviations, directives, psects, linker, options, utilities, and diagnostics. Official source: [DS50002974E](https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/UserGuides/MPLAB-XC8-PIC-Assembler-User-Guide-50002974.pdf).

**[EE]** Microchip Technology Inc., *MPLAB® XC8 PIC Assembler User's Guide for Embedded Engineers*, DS50002994C, June 2022. Worked baseline, mid-range, PIC18, interrupt, multi-file, and compiled-stack examples. This is instructional evidence; exact-device facts are checked against the applicable data sheet and DFP.

**[RN400]** Microchip Technology Inc., *MPLAB® XC8 v4.00 Release Notes for PIC*, XC8 4.00, June/July 2026. Version-specific behavior, known issues, and external DFP requirements. Official source: [XC8 v4.00 release notes](https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/UserGuides/xc8-v4.00-full-install-release-notes-PIC.pdf).

**[DFP17146]** Microchip *PIC16F1xxxx_DFP* 1.31.465, April 2026. Accepted device symbols, configuration tokens, headers, chip metadata, and pack-supported assembler data. Obtain the complete pack from the [Microchip Packs repository](https://packs.download.microchip.com/).

**[PROG171]** Microchip Technology Inc., *PIC16F171XX Family Programming Specification*, DS40002266B, August 2021. ICSP, configuration words, device IDs, programming algorithm, and HEX use. Official source: [DS40002266B](https://ww1.microchip.com/downloads/aemDocuments/documents/MCU08/ProductDocuments/ProgrammingSpecifications/PIC16F171XX-Family-Programming-Specification-40002266.pdf).

**[CNANO]** Microchip Technology Inc., *PIC16F17146 Curiosity Nano Hardware User Guide*, DS50003388B, March 2023. Board LED/switch/debugger wiring, power, clock footprint, and programming workflow. Official source: [DS50003388B](https://ww1.microchip.com/downloads/aemDocuments/documents/MCU08/ProductDocuments/UserGuides/PIC16F17146-CNANO-HW-UserGuide-DS50003388.pdf).

**[MPLABX]** Microchip Technology Inc., *MPLAB® X IDE User's Guide*, DS50002027F, January 2022. Project creation, Simulator, Watches, Configuration Bits, and pack management. Official source: [DS50002027F](https://ww1.microchip.com/downloads/en/DeviceDoc/MPLAB_X_IDE_Users_Guide_50002027.pdf).

## Secondary devices and utilities

**[DS18Q43]** Microchip Technology Inc., *PIC18F27/47/57Q43 Microcontroller Data Sheet*, DS40002147H, April 2024. PIC18F57Q43 architecture, Access Bank, IVT, Timer0, SFRs, and instruction behavior. Official source: [DS40002147H](https://ww1.microchip.com/downloads/aemDocuments/documents/MCU08/ProductDocuments/DataSheets/PIC18F27-47-57Q43-Microcontroller-Data-Sheet-XLP-DS40002147.pdf).

**[ER18Q43]** Microchip Technology Inc., *PIC18F27/47/57Q43 Silicon Errata*, DS80000870M, August 2024. Q43-specific silicon anomalies and clarifications. Official source: [DS80000870M](https://ww1.microchip.com/downloads/aemDocuments/documents/MCU08/ProductDocuments/Errata/PIC18F27-47-57Q43-Si-Errata-Data-Sheet-Clarifications-DS80000870.pdf).

**[DFP18Q]** Microchip *PIC18F-Q_DFP* 1.30.487, March 2026. PIC18F57Q43 symbols, configuration, IVT metadata, and assembler support. Obtain the complete pack from the [Microchip Packs repository](https://packs.download.microchip.com/).

**[DS570]** Microchip Technology Inc., *PIC16F570 Data Sheet*, DS40001684F, January 2016. Enhanced-baseline `PIC12IE` memory, reset, stack, interrupt, and instruction behavior. Official source: [DS40001684F](https://ww1.microchip.com/downloads/en/DeviceDoc/40001684F.pdf).

**[DS10]** Microchip Technology Inc., *PIC10F200/202/204/206 Data Sheet*, DS40001239F, September 2014. Plain-baseline `PIC12` instruction set, reset, call restriction, stack, and lack of interrupts. Official source: [DS40001239F](https://ww1.microchip.com/downloads/en/DeviceDoc/40001239F.pdf).

**[HEX]** Microchip Technology Inc., *Hexmate User's Guide*, DS50003033D, October 2024. Intel HEX formats, merging, filling, checksums, and address handling. The utility is shipped with MPLAB® XC8.

**[MIGRATE]** Microchip Technology Inc., *MPASM to MPLAB® XC8 PIC Assembler Migration Guide*, DS50002973B, 2022. MPASM™ syntax, directives, masking, psects, and linker migration. Official source: [DS50002973B](https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/UserGuides/MPASM-to-MPLAB-XC8-PIC-Assembler-Migration-Guide-50002973.pdf).

**[CUG]** Microchip Technology Inc., *MPLAB® XC8 C Compiler User's Guide for PIC MCU*, DS50002737L, April 2026. Assembly/C interface, inline assembly, calling conventions, and compiler-managed sections.

## Reading and release conventions

- A citation such as `[UG] §4.9.48` means the exact section in the source above.
- A citation such as `[DS17146] §9.4` means the exact section in the PIC16F17146 data sheet.
- If a chapter cites an older instructional source, it must still defer to the exact device data sheet, errata, DFP, and current release notes for claims that can change.
- The source inventory records local availability, hashes, retrieval notes, and supersession details.
