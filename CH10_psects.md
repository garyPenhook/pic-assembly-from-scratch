# Chapter 10 — Psects: Organizing Code & Data

> **What you'll build:** nothing new *runs* — instead you'll finally *understand* the line
> you've typed in every program. You'll define your own custom psects for code and data, build,
> then open the **map file** and watch the linker turn your named sections into real addresses.
> This is the concept the official guides assume you already know. After this chapter, you do.

---

## 10.1 The idea: you write sections, the linker places them

You never told the assembler "put this instruction at address 0x0123." You wrote a **psect** — a
named container — dropped code or data into it, and let the **linker** decide the final address.
That indirection is the heart of how PIC assembly is organized, and it's why your programs are
*relocatable*: you name where things belong *categorically* ("this is code," "this is a bank-0
variable"), and the linker resolves the actual numbers.

A **psect** ("program section") is **a named block of code or data, normally relocatable.** (The
advanced `abs` flag makes one non-relocatable.) The `PSECT` directive "declares or resumes a
program section" (User's Guide §4.9.48). Everything emitted or reserved between one `PSECT` line
and the next goes into that section. At link time, the linker:

1. gathers every **global** psect of the same name (even across multiple files),
2. finds a memory range appropriate for it (its **class**),
3. assigns it a concrete start address, and
4. resolves every label inside it to a real number.

You've been doing all four, on faith, since Chapter 4. Now let's see the machinery.

---

## 10.2 A psect declaration, dissected

Recall the reset-vector line you've written five times:

```asm
    PSECT resetVec,class=CODE,delta=2
```

The syntax is `PSECT name, flag, flag, …` (User's Guide §4.9.48). Here `resetVec` is the name and
`class=CODE`, `delta=2` are two **flags**. The full flag list is Table 4-10 in the guide; for
beginner work you need exactly four of them. Here they are, each verified against §4.9.48:

| Flag | What it controls | The rule for the PIC16F17146 |
|---|---|---|
| `class=` | which **linker class** (memory range) the psect goes in | e.g. `CODE` for program memory, `COMMON` for common RAM (§4.9.48.3) |
| `delta=` | **bytes per address** | program memory is word-addressable → **`delta=2`**; data memory is byte-addressable → `delta=1` (the default) (§4.9.48.4) |
| `space=` | which **memory space** when addresses overlap | **0 = program** memory, 1 = data memory (§4.9.48.18) |
| `reloc=` | **alignment** boundary | default `1` on mid-range (no alignment needed); PIC18 code needs `2` (§4.9.48.16) |

### `class=` — *which* memory
A **class** is a named range of addresses the linker can place a psect into. `class=CODE` means
"this belongs in program memory"; `class=COMMON` means "put it in common RAM." Associating a psect
with a class is usually all you need — the linker then finds room for it anywhere in that range,
and you don't have to name a specific address (§4.9.48.3). The classes themselves (`CODE`, `RAM`,
`COMMON`, `BANK0`…) are predefined for your device once you `#include <xc.inc>` (User's Guide §5.3,
covered in Chapter 8).

### `delta=` — how wide is an address
This is the one that feels strange until it clicks. On the PIC16F17146, **program memory stores 14
bits at each address, which takes 2 bytes in the HEX file** — so a code psect uses `delta=2`. The
guide states the consequence bluntly: "addresses in the HEX file will not match addresses in the
program memory" (§4.9.48.4). Data memory is plain bytes, so data psects use `delta=1` (the
default — that's why your `udata_shr` variables never needed it). **Rule of thumb: `delta=2` on
every code psect, nothing on data psects.**

### `space=` — resolving the great address collision
Program address 0 and data address 0 are *different physical places* (Harvard architecture,
Chapter 1). The `space` flag tells the linker which one you mean: **space 0 is program memory,
space 1 is data memory** (§4.9.48.18). The assembler-provided data psects already set `space=1`
for you; you'll only write it explicitly when you roll your own data psect (as we do below).

### `reloc=` — alignment (you rarely touch it on mid-range)
`reloc=n` forces a psect to start on an address that's a multiple of `n`. Mid-range code has no
alignment requirement, so the default `reloc=1` is fine — which is why our `resetVec` never
needed it. (PIC18 code *must* be word-aligned with `reloc=2`; a difference worth knowing when you
reach Chapter 15.) (§4.9.48.16.)

> **Two more flags worth naming now.** `global` (the default) concatenates same-named psects
> across files; `local` keeps a psect private to its module (§4.9.48.5, §4.9.48.9). You'll use
> `global` implicitly the moment you split a project in Chapter 13.

---

## 10.3 Predefined vs. your own psects

You've used both kinds without noticing:

- **Assembler-provided psects** — `code`, `udata`, `udata_shr`, `data` (User's Guide §5.2, from
  Chapter 6). Each comes pre-wired to the right class, so `PSECT code` just works.
- **User-defined psects** — `resetVec`, `farCode` (Chapter 9). You invent the name and supply the
  flags yourself. You do this when a section needs to be placed at a *specific* address, because a
  uniquely-named psect can be positioned with a linker `-P` option — which is exactly how we put
  `resetVec` at 0 and `farCode` at 0x0800.

That's the division: use a provided psect when you just need "some code" or "some RAM"; make your
own when *where it lands* matters.

---

## 10.4 Placing a psect: class vs. `-P`

There are two ways a psect gets an address (User's Guide §4.9.48.3, and the `-P` option):

1. **By class** — "put this anywhere in the `CODE` range." You just give `class=CODE` and the
   linker finds room. This is the normal case.
2. **By position (`-P`)** — "put this psect at exactly address X." You pass a linker option like
   `-Wl,-presetVec=0h` (reset vector at 0) or `-Wl,-pfarCode=0800h` (Chapter 9). Every build
   command you've run used the first form for `resetVec`.

> **`ORG` is not what you think.** Newcomers from other assemblers reach for `ORG` to set an
> absolute address. On this assembler, "the much-abused `ORG` directive moves the location counter
> to an offset *relative to the base of the current psect*, not to an absolute address" (User's
> Guide §4.9.42). To place something at a fixed address, give it its own psect and use `-P` — not
> `ORG`. You will almost never need `ORG`.

---

## 10.5 The program — roll your own psects

Let's define a custom code psect and a custom data psect, so you can find *your* names in the map
file rather than the library's.

```asm
; ------------------------------------------------------------
;  psects.S  —  define custom code and data psects, then read
;               the map file to see where the linker put them.
; ------------------------------------------------------------

    PROCESSOR 16F17146
#include <xc.inc>
;  --- paste your Chapter 5 CONFIG block here ---

; --- a user-defined DATA psect in bank 0 GPR -----------------
; space=1 -> data memory; class BANK0 -> general RAM of bank 0.
    PSECT myVars,class=BANK0,space=1
counter:
    DS      1                   ; reserve 1 byte
scratch:
    DS      1                   ; reserve another

; --- reset vector (positioned at 0 by the linker option) -----
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main

; --- a user-defined CODE psect -------------------------------
    PSECT myCode,class=CODE,delta=2
main:
    BANKSEL counter
    clrf    BANKMASK(counter)
    incf    BANKMASK(counter),f
    goto    $

    END     resetVec
```

Notice the two custom psects: `myVars` (data, `space=1`, class `BANK0`, no `delta` because data is
byte-addressable) and `myCode` (code, `class=CODE`, `delta=2`). Everything you learned in §10.2 is
on display in four lines.

---

## 10.6 Build it and read the map file

```
pic-as -mcpu=16f17146 -mdfp=/path/to/PIC16F1xxxx_DFP/VERSION/xc8 \
       -Wl,-presetVec=0h -Wa,-a -Wl,-Map=psects.map psects.S
```

The `-Wl,-Map=psects.map` option produces the **map file** — the linker's report of where
everything ended up. Open `psects.map` and look for a section listing your psects. You'll find
entries for `resetVec`, `myCode`, and `myVars`, each with a **start address**, a **length**, and
the **class** it was drawn from. That is the linker showing its work: your named sections, turned
into concrete addresses.

Things to confirm in the map:
- `resetVec` starts at **0x0000** (because of `-presetVec=0h`).
- `myCode` sits somewhere in the `CODE` range (program memory), placed automatically by class.
- `myVars` sits in bank-0 general RAM (the `BANK0` class), and `counter`/`scratch` occupy two
  consecutive addresses there.

> **Symbols in the map.** By default only `GLOBAL` symbols appear in the map/symbol files (User's
> Guide §4.6.5, Chapter 4). Don't be surprised if a plain local label is absent — that's expected,
> not a bug. Chapter 17 reads the map file in full detail.

---

## 10.7 What just happened

You saw the whole pipeline stop being magic. A **psect** is a named container; its **flags**
(`class`, `delta`, `space`, `reloc`) tell the linker what *kind* of memory it needs; the **linker**
gathers same-named psects, drops each into its class's address range (or a specific address via
`-P`), and resolves every label. The **map file** is the receipt. Every `PSECT`, `class=CODE`,
`delta=2`, and `-Wl,-p…` line from the previous six chapters now has a reason you can articulate.

---

## 10.8 Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| Code psect won't fit / wrong bytes in HEX | forgot `delta=2` on a code psect | mid-range code is word-addressable — always `delta=2` (§4.9.48.4) |
| Data psect placed in program memory (or vice versa) | wrong or missing `space` flag | data psects need `space=1`; code uses `space=0` (default) (§4.9.48.18) |
| Linker "can't place psect" / class error | `class=` names a class that doesn't exist for the device | use a predefined class (`CODE`, `BANK0`, `COMMON`, `RAM`) (§5.3) |
| `ORG 0x100` didn't put code at 0x100 | `ORG` is psect-relative, not absolute | give it its own psect + `-P` linker option (§4.9.42) |
| Two `PSECT` lines, "contradictory flags" error | re-declared a psect with different flags | flags propagate from the first declaration; don't restate them differently (§4.9.48) |
| Your label isn't in the map file | it isn't `GLOBAL` | that's normal; declare it `GLOBAL` if you need it listed (§4.6.5) |

(Appendix C decodes the exact message wording.)

---

## 10.9 Try it yourself

1. **Find your names.** Build `psects.S`, open `psects.map`, and locate `myCode` and `myVars`.
   Write down each one's start address and length.
2. **Force a location.** Add `-Wl,-pmyCode=0100h` to the build, rebuild, and confirm in the map
   that `myCode` now starts at 0x0100. You just positioned a psect by hand.
3. **Break the delta.** Change `myCode`'s `delta=2` to `delta=1`, rebuild, and read the error or
   the mangled addresses. Restore it — and remember why mid-range code is always `delta=2`.
4. **Same name, two blocks.** Add a second `PSECT myCode,class=CODE,delta=2` later in the file
   with another instruction, and confirm from the map that the linker concatenated both into one
   `myCode` section.

---

## 10.10 Reference bridge

- **User's Guide §4.9.48 "Psect Directive"** — the complete flag table (Table 4-10) and every
  flag's detailed description; you can now read all of it.
- **User's Guide §5.2–5.3** — the assembler-provided psects and the predefined linker classes
  they map to.
- **User's Guide §4.9.42 "Org Directive"** — why `ORG` is relative, and what to use instead.

**Next chapter:** your variables have so far been single bytes. Chapter 11 uses psects and the
enhanced mid-range **linear memory** view to build variables *bigger* than one byte — a 16-bit
counter you can increment across its full range — and shows how the FSRs reach contiguous data
that spills past a single bank.
