# Chapter 18 — Utilities, Hex Files & Programming the Chip

> **What you'll build:** the finish line. You'll take the timer-blink from Chapter 14, understand
> the **HEX file** the build produces, meet the **Hexmate** utility, and then actually **program
> the PIC16F17146** so your assembly runs on real silicon and blinks a real LED. Everything so far
> has led here: code on a chip.

---

## 18.1 The idea: the HEX file is the deliverable

Every build you've run produced a `.hex` file. That file — not the `.o`, not the `.map` — is what
gets burned into the chip. It's the portable, tool-independent image of your program's memory.
Understanding it demystifies the last step from "it assembled" to "it runs."

The format is **Intel HEX** — plain ASCII text, a series of *records*, one per line, each beginning
with a colon (User's Guide §7.2.2). Open any `.hex` in a text editor and you'll see lines like:

```
:04000000FEEFFFF020
```

That's not random. Every record has a fixed structure (§7.2.2):

```
:  LL   OOOO   TT   DD…DD    CC
│  │     │      │     │       └ Checksum (1 byte)
│  │     │      │     └ Data / Argument (LL bytes)
│  │     │      └ Record Type
│  │     └ Address Offset (2 bytes)
│  └ Data Length (1 byte)
└ Record Mark (colon)
```

Decoding the example above: `04` bytes of data, at address offset `0000`, record type `00` (a data
record), the four data bytes `FE EF FF F0`, and checksum `20`. The **checksum** is the 8-bit two's
complement of the sum of every byte in the record — sum `0x04+00+00+00+FE+EF+FF+F0 = 0x3E0`, and
two's complement of the low byte gives `0x20` (§7.2.2). It exists so a programmer can catch a
corrupted line before writing it to your chip.

There are six record types; the two you'll always see are **`00` (Data)** and **`01` (End-of-file)**
(§7.2.2). Types `04`/`02` extend the address range for large devices. A HEX file using only types 0
and 1 is Microchip's **INHX8M** format; add type 4 records and it's **INHX32** (§7.2.2.1).

---

## 18.2 The gotcha: HEX addresses are byte addresses

Here's the fact that confuses everyone reading a mid-range HEX file (User's Guide §7.2.2):

> "HEX files always use byte addresses... Some devices use word addressing, where each unique
> device address might contain more than one byte of data."

The PIC16F17146 is **word-addressed** — like all baseline, mid-range, and enhanced mid-range PICs,
its program memory uses **2 bytes per address** (§7.2.2 table). But the HEX file addresses
*bytes*. So **a device program-memory address does not equal its HEX-file address** — the HEX
address is (roughly) *twice* the device word address. If you go hunting in a `.hex` for the code at
device address 0x0004 (the interrupt vector), you'll find it near HEX offset 0x0008. This is the
same delta/word-vs-byte theme from Chapter 10, now visible in the output file. (Hexmate's
`-addressing` option can do the mapping for you; §7.2.2.)

---

## 18.3 Hexmate: massaging the HEX file

**Hexmate** is a post-link utility that manipulates Intel HEX files. The driver runs it
automatically at the end of every build, but you can also call it standalone (`xc8-ar`'s sibling)
for jobs like (User's Guide §7.2.1):

- **Merging** several HEX files into one — e.g. dropping a bootloader in with your application.
- **Checksums / CRC** — computing a hash over your code so the running program can verify it
  hasn't been corrupted.
- **Filling unused memory** — putting a known value (or a "trap" instruction) in every empty
  location, so a crashed program that wanders into blank flash does something predictable.
- **Format conversion** — INHX8M ↔ INHX32, standardizing record lengths.
- **Finding/validating** — checking record checksums, mapping addresses.

You rarely need Hexmate by hand as a beginner — but knowing it exists explains how bootloaders,
serial numbers, and code-integrity checksums get *into* a HEX file after the linker is done.

---

## 18.4 Programming the PIC16F17146 Curiosity Nano

Now the moment. The Curiosity Nano has an **on-board debugger** that programs the target over USB —
no separate programmer needed (CNANO guide §3.1). There are two ways to flash your `.hex`.

### Method 1 — from your IDE (the normal way)
1. Plug the board in over USB; the on-board debugger enumerates automatically.
2. **VS Code:** run **`Debug: Add Configuration` → MPLAB Debugger** (Chapter 3), select the
   connected Curiosity Nano as the tool, and start a session — programming happens as the session
   launches. *(MPLAB X IDE: press **Make and Program Device**.)*
3. The tool assembles, links, and writes the HEX to the chip.

During programming, the board's **Power/Status (PS) LED** "blinks slowly during
programming/debugging" (CNANO §3.1). When it settles, your code is running.

### Method 2 — Drag-and-drop (no IDE needed)
The on-board debugger also appears as a **USB mass-storage drive** (CNANO §3.1). To program:

1. Build your project to a `.hex` (command line or IDE).
2. **Drag the `.hex` file onto the Curiosity Nano drive.**
3. Watch the PS LED: it **"blinks slowly for 2 sec"** on success, or **"blinks rapidly for 2 sec"**
   on failure (CNANO §3.1, Table 3-1).

Drag-and-drop is a delightfully simple way to flash a board from any machine, no toolchain
installed — great for demos and sharing.

---

## 18.5 Run your blink on real silicon

Let's ship the Chapter 14 timer-blink. Build it to a HEX:

```
pic-as -mcpu=16f17146 -mdfp=/path/to/Microchip.PIC16F1xxxx_DFP/1.31.465/xc8 \
  -Wl,-presetVec=0h -Wl,-pintVec=0004h -Wl,-Map=tmr0blink.map tmr0blink.S
```

This produces `tmr0blink.hex`. Program it by either method above. On success, the **yellow user
LED (RC1)** blinks at ~2 Hz — driven entirely by the TMR0 interrupt, on a physical chip, from
assembly *you* wrote and now fully understand, byte by byte from the reset vector up.

Take a moment. That blink is the whole book working at once: config bits bring the chip up, the
reset vector at 0x0000 jumps to your code, psects placed everything in memory, banking reached the
port registers, the timer and interrupt controller run the show, the linker produced the HEX, and
the on-board debugger burned it in. You built all of it from first principles.

> **A note on config bits and LVP.** Keep **`LVP = ON`** for the Curiosity Nano's normal
> low-voltage ICSP path. The low-voltage programming interface cannot itself clear the LVP
> configuration bit; disabling LVP requires high-voltage entry. Do not apply an external
> high-voltage programmer to the assembled board without following the board guide's isolation
> precautions: high voltage on MCLR can damage the on-board debugger connection.

---

## 18.6 What just happened

You closed the loop from source to silicon. The **HEX file** is your program as Intel-HEX records —
data records, an end record, and a checksum per line — and you learned the mid-range trap that its
**byte addresses aren't the chip's word addresses**. **Hexmate** is the utility that merges, fills,
and checksums HEX files after linking. And the **Curiosity Nano's on-board debugger** flashed your
code two ways — MPLAB X or drag-and-drop — with the PS LED reporting success. Your assembly runs on
hardware.

---

## 18.7 Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| Data in the HEX is at "the wrong address" | HEX is byte-addressed; mid-range is word-addressed | HEX addr ≈ 2× device addr; use `-addressing` to map (§7.2.2) |
| Board won't accept a new program | wrong device/HEX, cabling, or programming state; LVP may have been disabled by external HV programming | keep `LVP = ON`; verify the exact HEX/device and board status before considering external tools |
| Drag-and-drop: PS LED blinks *rapidly* | programming failed | rebuild; check the HEX is valid and for the right device (CNANO §3.1) |
| No `.hex` produced | build stopped before Hexmate/linker ran | fix earlier assembly/link errors first |
| Programmed OK but nothing happens | config bits wrong (oscillator/MCLR), or LED polarity | revisit Chapter 5 config and Chapter 7's active-low LED |
| Merged bootloader + app overlap | overlapping regions in the two HEX files | use Hexmate merging and check the address map (§7.2) |

(Appendix C decodes the exact message wording.)

---

## 18.8 Try it yourself

1. **Read your HEX.** Open `tmr0blink.hex` in a text editor. Find the first `:...00...` data record
   and the final `:00000001FF` end record. Verify one record's data length byte matches its data.
2. **Flash both ways.** Program the board from your IDE (VS Code MPLAB Debugger, or MPLAB X), then rebuild and program the *same* HEX by
   drag-and-drop. Watch the PS LED confirm each.
3. **Map an address.** Pick the device address of your ISR (near 0x0004) and predict its HEX-file
   byte offset (roughly double). Find it in the HEX.
4. **Fill the blanks (stretch).** Read Hexmate's fill option in User's Guide §7.2 and describe how
   you'd fill unused flash with a `goto reset` so a crashed program restarts instead of running
   blank memory.

---

## 18.9 Reference bridge

- **User's Guide §7.2 "Hexmate"** — the HEX file specification, record types, formats, and every
  Hexmate option (merge, CRC, fill, find/replace).
- **Curiosity Nano guide §3.1** — the on-board debugger, drag-and-drop programming, and the PS LED
  status table.
- **Chapter 5** — the config bits (especially `LVP`) that keep programming reliable.

**Next chapter:** you've mastered the enhanced mid-range PIC16F17146 top to bottom. Chapter 19 (the
optional finale) looks *down* the range to the **baseline** 12-bit cores — including a plain
PIC10 without interrupts and the interrupt-capable enhanced-baseline PIC16F570 — where memory is
scarce and every instruction counts.
