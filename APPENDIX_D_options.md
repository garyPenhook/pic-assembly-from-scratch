# Appendix D — MPLAB X & `pic-as` Option Reference

The command-line driver is **`pic-as`**, and MPLAB X issues these same options for you based on
Project Properties (User's Guide §3, §3.4). Options are **case-sensitive** and start with a dash
(§3.4). This card covers the ones a beginner meets; the full list is User's Guide §3.4, Table 3-1.

Basic form (User's Guide §3):
```
pic-as [options] files [libraries]
```

---

## D.1 Options this book actually uses

| Option | What it does | Seen in |
|---|---|---|
| `-mcpu=16f17146` | target device (must match `PROCESSOR`) | every build |
| `-mdfp=<DFP>/xc8` | **required on modern standalone XC8** — path to the device pack (MPLAB X adds it automatically; without it you get "no device-support files", err 2103/2104) | Ch 3 |
| `-Wl,-presetVec=0h` | **position** the `resetVec` psect at address 0 | Ch 4 |
| `-Wl,-pintVec=0004h` | position the interrupt-vector psect at 0x0004 | Ch 14 |
| `-Wl,-pfarCode=0800h` | position a psect at a chosen address (page 1) | Ch 9 |
| `-Wl,-Map=file.map` | produce a map file | Ch 17 |
| `-Wa,-a` | produce an assembly **list** file (`.lst`) | Ch 4+ |
| `-Wl,--fixupoverflow=warn:lstwarn` | truncate overflowing fixups and report them in console/list output for migration diagnosis; does not select a bank/page | Ch 7, 8 |
| `-mcallgraph=full` | print the compiled-stack call graph in the map | Ch 16 |
| `-Wl,-pudata_acs=COMRAM` | place the compiled-stack psect | Ch 16 |
| `-c` | assemble to an object (`.o`) without linking | Ch 13 |

> **The three "pass-through" prefixes** (User's Guide §3.4, Table 3-1) — remember which stage each
> targets:
> - **`-Wl,`** → to the **linker** (map, psect positioning, fixupoverflow)
> - **`-Wa,`** → to the **assembler** (list file)
> - **`-Wp,`** → to the **preprocessor**
>
> **In MPLAB X**, put these in the *Custom linker/assembler options* fields **without** the leading
> `-Wl,`/`-Wa,` — the IDE adds that prefix (Embedded Engineers guide §4.4).

---

## D.2 The broader option set (from Table 3-1)

| Option | Controls |
|---|---|
| `-o file` | output file name |
| `-Dmacro=text` | define a preprocessor symbol (e.g. `-DDEBUG=1`) |
| `-Umacro` | undefine a preprocessor symbol |
| `-Idir` | directory searched for `#include` headers |
| `-llibrary` / `-Ldir` | libraries to scan / where to find them |
| `-mdfp=path` | which Device Family Pack to use |
| `--fill=options` | fill unused memory (same as Hexmate `-fill`) |
| `-mchecksum=specs` | generate/place a checksum or hash |
| `-mram=` / `-mrom=` / `-mreserve=` | limit/reserve data or program memory ranges |
| `-mserial=options` | insert a serial number into the output |
| `-fmax-errors=n` | how many errors before the build aborts |
| `-mwarn=level` / `-w` | warning threshold / suppress all warnings |
| `-Werror`, `-Werror=num`, `-Wno-error` | promote all warnings, one numbered warning, or undo promotion |
| `-save-temps` | keep intermediate files after the build |
| `-v` / `--version` / `--help` | verbose output / version / help |
| `-mprint-devices` | list supported devices |

---

## D.3 Long command lines (`@file`)

To store options and file names in a file (a simple alternative to a makefile), use `@` immediately
followed by the filename (User's Guide §3.3):

```
# xyz.xc8
-mcpu=16f17146 -Wl,-Map=proj.map -Wa,-a \
main.S isr.S
```
```
pic-as @xyz.xc8
```

Arguments are space-separated, may span lines with a trailing `\`, and blank lines are ignored
(§3.3). MPLAB X supports these via **XC8 Linker → Additional options → Use response file to link**.

### Reproducible pack-specific examples

Current standalone XC8 4.00 builds need a complete unpacked/installed pack path, not merely a
chip-specific header subset:

```
pic-as -mcpu=16f17146 -mdfp=/packs/Microchip.PIC16F1xxxx_DFP/1.31.465/xc8 main.S
pic-as -mcpu=18f57q43 -mdfp=/packs/Microchip.PIC18F-Q_DFP/1.30.487/xc8 main.S
pic-as -mcpu=16f570 -mdfp=/packs/Microchip.PIC16Fxxx_DFP/1.7.162/xc8 main.S
```

The `xc8` directory must contain generic files such as `pic/include/pic.inc` and device-selection
metadata as well as the device header. MPLAB X normally supplies this path from its pack manager.

---

## D.4 Reference

- **User's Guide §3.4 "Assembler Option Descriptions"** — Table 3-1 and every option's detail.
- **User's Guide §3.1–3.3** — single-step vs. multi-step builds and command files.
- **User's Guide §3.5** — how each Project Properties control maps to a `pic-as` option.
