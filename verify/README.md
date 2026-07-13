# Verification examples

The `.S` files in this directory are the canonical assembly examples referenced by the book. The generated `.map`, `.lst`, `.hex`, `.elf`, and intermediate files are local verification output and are ignored by Git.

## Run the verification target

Install MPLAB® XC8 and the exact DFP revisions listed in `SOURCE_INVENTORY.md`, then set the assembler and DFP `xc8` directories:

```sh
PIC_AS=/path/to/xc8/v4.00/pic-as/bin/pic-as \
DFP_PIC16F17146=/path/to/PIC16F1xxxx_DFP/1.31.465/xc8 \
DFP_PIC18F57Q43=/path/to/PIC18F-Q_DFP/1.30.487/xc8 \
DFP_PIC16F570=/path/to/PIC16Fxxx_DFP/1.7.162/xc8 \
make verify
```

The target performs standalone assembly/link checks for the canonical examples. It does not claim simulator or physical-board execution. Those validations require a configured simulator or hardware test log.

Each successful run also writes `verify/verify-summary.tsv`, an ignored tab-separated manifest listing the source, target, status, and expected `.map`, `.lst`, `.hex`, and `.elf` artifacts. The manifest is deliberately generated rather than committed because these files depend on the local XC8 installation.

## Expected artifacts

| Artifact | What to inspect | Typical evidence |
|---|---|---|
| `.map` | psect/class placement, symbol addresses, memory usage | linker placement and memory-model claims |
| `.lst` | source-to-opcode listing and diagnostics | instruction expansion and address calculations |
| `.hex` | emitted program/configuration records | programming image; not proof of runtime behavior |
| `.elf` | symbols and debug metadata | debugger/simulator input and symbol lookup |

The presence of an artifact proves only that the build produced it. A runtime claim requires a separate simulator or hardware record.
