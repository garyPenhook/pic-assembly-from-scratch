# Chapter 17 — The Linker & Map Files

> **What you'll build:** nothing new to run — instead you'll finally *read* the **map file** the
> linker has been quietly producing since Chapter 4. You'll open your blink's map, find where
> every psect and symbol landed, spot the free memory that's left, and learn to diagnose "won't
> fit / can't place" errors yourself. The map file is the linker showing its work; this chapter
> teaches you to read it.

---

## 17.1 The idea: the linker places, the map reports

Recall the pipeline (Chapter 10): the assembler turns each source file into an object file full of
**relocatable psects**; the **linker** then gathers all the psects, drops each into a memory range
(its **class**), assigns concrete addresses, resolves every symbol, and emits the final HEX. The
**map file** is the linker's report of exactly where everything ended up — "information relating to
the memory allocation of psects and the addresses assigned to symbols within those psects"
(User's Guide §6.3).

When a build succeeds, the map tells you how much memory you used and where. When it *fails* with a
placement error, the map is the first place you look. Either way, it's the ground truth about your
program's memory — and after this chapter it won't be mysterious.

---

## 17.2 Getting a map file

You've been generating one all along with `-Wl,-Map`:

```
pic-as -mcpu=16f17146 -mdfp=/path/to/Microchip.PIC16F1xxxx_DFP/1.31.465/xc8 \
  -Wl,-presetVec=0h -Wl,-Map=blink.map blink.S
```

In MPLAB X a map file is produced **by default** (User's Guide §6.3.1). Two useful facts from that
section:

- The map is written **by the linker**, so if the build stops before linking (e.g. an assembly
  error), you get no map.
- A map **is** produced even when the linker reports errors — a partial map that often points
  straight at the cause of a "can't place" failure. (Only a *fatal* linker abort suppresses it.)

---

## 17.3 What's in a map file

The sections appear in this order (User's Guide §6.3.2):

1. Assembler name & version
2. The linker command line
3. Object-code version and **machine type**
4. **Psect summary by module** (which file contributed which psect)
5. **Psect summary by class** ← *where each psect landed*
6. Segment summary *(ignore this one)*
7. **Unused address ranges** ← *free memory*
8. **Symbol table** ← *where each global symbol is*
9. Per-function and per-module info

We'll focus on the four that matter to a beginner (4, 5, 7, 8). First, a sanity habit: **check the
version and machine type at the top.** "Always confirm the assembler version number... to ensure
you are using the assembler you intended," and that `Machine type` reads `16F17146` (§6.3.2.1). A
surprising number of "impossible" bugs are really "built for the wrong chip."

---

## 17.4 The psect listing — and the columns that matter

The heart of the map is the psect listing, under this header (User's Guide §6.3.2.2):

```
Name   Link  Load  Length  Selector  Space  Scale
```

Here's Microchip's example (§6.3.2.2), which teaches every column at once:

```
Name     Link  Load  Length Selector  Space  Scale
ext.o    text    3A    3A      22       30      0
         bss     4B    4B      10       4B      1
         rbit    50     A       2        0      1      8
```

Decoding the columns:

- **Link** — the address the psect is *accessed at* at run time. This is the one you usually care
  about. `text` is linked at 0x3A.
- **Load** — where it sits in the output HEX; usually equal to Link (§6.3.2.2).
- **Length** — size, in the psect's own units.
- **Space** — the memory space: **`0` = program memory, `1` = data memory** (§6.3.2.2). *This is
  the column that resolves apparent overlaps.*
- **Scale** — address units per byte; blank when 1, **`8` for bit psects** (§6.3.2.2).
- **Selector** — ignore it on PIC devices.

> **The "overlap" that isn't — why `Space` matters.** In the example, `text` is at 0x3A and `bss`
> at 0x4B — but glance again: `text` has **Space 0** (program memory) and `bss` has **Space 1**
> (data memory). They're in *different memory spaces* (Harvard architecture, Chapter 1), so
> program address 0x3A and data address 0x4B have nothing to do with each other. **Never compare
> two addresses without checking their Space.** This single habit prevents a whole category of
> map-reading mistakes. (The `rbit` psect's Scale of 8 means its addresses are in *bit* units —
> another reason two numbers might look like a clash when they aren't.)

The same psects are then re-listed **grouped by class** (`TOTAL Name Link Load Length`,
§6.3.2.3) — same data, sorted by `CODE`, `BANK0`, `COMMON`, etc. This is often the easiest view for
"where did my code psect go?"

---

## 17.5 Unused ranges and the symbol table

### Free memory (§6.3.2.5)
After the psect listings comes **`UNUSED ADDRESS RANGES`** — the memory still available in each
class. When you hit a "can't find space" / "won't fit" error, **this is the section to study**. Pay
attention to the **`Largest block`** column: it shows the biggest *contiguous* free chunk (taking
paging boundaries into account), which is what actually determines whether a psect fits (§6.3.2.5).
A class can show plenty of total free bytes yet still fail to place a psect if that free space is
fragmented into pieces all smaller than the psect.

### Where your symbols went (§6.3.2.6)
The **`Symbol Table`** alphabetically lists the program's **global** symbols — global labels,
global `EQU`/`SET` values, and linker-defined symbols — each with the psect it's in and its value
(usually an address). Two things to remember (§6.3.2.6):

- **Only `GLOBAL` symbols appear.** A plain local label won't be here (Chapter 4). If you want to
  find a symbol in the map, declare it `GLOBAL`.
- A psect shown as **`(abs)`** means the symbol isn't tied to a psect — typical of `EQU`-defined
  constants (they're just values, not memory).

(The assembler *list* file, by contrast, shows *local* symbols too, but only for its own module —
a useful complement, §6.3.2.6.)

---

## 17.6 Hands-on: read your blink's map

Rebuild Chapter 7's blink asking for a map, then open `blink.map`:

```
pic-as -mcpu=16f17146 -mdfp=/path/to/Microchip.PIC16F1xxxx_DFP/1.31.465/xc8 \
  -Wl,-presetVec=0h -Wl,-Map=blink.map blink.S
```

Walk it top to bottom and find:

1. **Header** — confirm `Machine type is 16F17146` and the version is the toolchain you meant.
2. **`resetVec`** — in the psect-by-class listing, under class `CODE`, confirm its **Link address
   is 0x0000** (that's what `-Wl,-presetVec=0h` forced). This is the reset vector the chip jumps to.
3. **The `code` psect** — find where the linker placed your `main`/`loop` instructions in the
   `CODE` class (an address it chose automatically). Note its **Length** — that's your program size
   in words.
4. **Your variables** — if you used `udata_shr` counters (from other chapters), find them in a data
   class with **Space 1**. Confirm they're in data memory, not program.
5. **`UNUSED ADDRESS RANGES`** — see how much program flash and RAM you have left. For a blink,
   almost all of it.
6. **Symbol table** — remember most of the blink's labels are local, so they *won't* appear. Add
   `GLOBAL main` to the source, rebuild, and watch `main` show up with its address. That's the
   direct way to make a symbol visible in the map.

Everything the linker did to your program is right there, in plain text.

---

## 17.7 Diagnosing placement problems

The map turns cryptic linker errors into findable facts:

- **"can't find space for psect X"** → open `UNUSED ADDRESS RANGES`, look at the `Largest block`
  for X's class. If the largest free block is smaller than X, X won't fit even if total free looks
  ample — the space is fragmented (§6.3.2.5).
- **"a symbol is at the wrong address"** → find it in the Symbol Table and check its psect; then
  check where that psect was placed in the psect-by-class listing.
- **"two things seem to collide"** → compare their **Space** first. Different Space = no collision
  (§6.3.2.2).
- **"built, but behaves like the wrong chip"** → check `Machine type` at the top (§6.3.2.1).

---

## 17.8 What just happened

The map file stopped being noise. You know its running order, you can read the psect listing's
**Link/Load/Length/Space/Scale** columns — especially **Space (0 = program, 1 = data)**, which
keeps you from mistaking cross-space addresses for overlaps — and you can find free memory in
**Unused Address Ranges** and any global symbol in the **Symbol Table**. Most importantly, when the
linker complains it "can't place" something, you now know exactly where to look.

---

## 17.9 Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| No map file produced | build failed before the linker ran (assembly error) | fix the assembly error; the map is a *linker* product (§6.3.1) |
| Two addresses look like they overlap | compared them without checking `Space` | different Space = different memory; compare within a space (§6.3.2.2) |
| A symbol you expected isn't in the map | it's a local label | declare it `GLOBAL` to list it (§6.3.2.6) |
| "can't find space" despite free memory | the free space is fragmented | check `Largest block`, not total free (§6.3.2.5) |
| A bit-object address looks wrong/huge | its Scale is 8 (bit units) | read the Load column (byte-converted) for bit psects (§6.3.2.2) |
| Wrong-chip behavior | built for the wrong device | verify `Machine type` at the map's top (§6.3.2.1) |

(Appendix C decodes the exact message wording.)

---

## 17.10 Try it yourself

1. **Map the blink.** Build `blink.S` with `-Wl,-Map=blink.map`, and write down `resetVec`'s Link
   address, the `code` psect's address and Length, and the largest free block of program memory.
2. **Make a symbol appear.** Add `GLOBAL main`, rebuild, and find `main` in the Symbol Table. Note
   its address and confirm it matches the `code` psect's placement.
3. **Force a fit failure.** Add a `DS`-reserved buffer far larger than a bank in a `udata` psect,
   build, and read the "can't find space" error — then find in `UNUSED ADDRESS RANGES` why the
   largest block was too small.
4. **Prove the Space rule.** Find a program-memory psect (Space 0) and a data psect (Space 1) with
   numerically close addresses, and explain in one sentence why they don't conflict.

---

## 17.11 Reference bridge

- **User's Guide §6.3 "Map Files"** — every section of the map, in order, with the column
  definitions.
- **User's Guide §6.1–6.2** — what the linker does: operation, psects, and relocation.
- **User's Guide §5.3–5.4** — the linker classes psects are placed into, and linker-defined
  symbols (the `__L`/`__H` names you saw in Chapter 15's `IVTBASE` code).

**Next chapter:** you can see where your program lives in memory; now let's get it *onto the chip*.
Chapter 18 covers the **HEX file** and the **Hexmate** utility — merging, checksums, filling unused
memory — and then actually programming the PIC16F17146 so your blink runs on real silicon.
