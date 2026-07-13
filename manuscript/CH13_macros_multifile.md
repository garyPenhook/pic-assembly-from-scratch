# Chapter 13 — Macros & Multiple Source Files

> **Reference keys:** `[UG]`, `[EE]`, and `[DFP17146]` in `REFERENCES.md`.

> **Scope and validation:** PIC16F17146, enhanced mid-range core; XC8 4.00 with PIC16F1xxxx DFP 1.31.465. Examples: source- and build/link-verified; runtime not hardware-verified.

> **What you'll build:** the Chapter 7 blink again — but split across **two source files** with a
> **shared macro library**. A reusable `delay` routine lives in its own file and is linked in; a
> pin-setup macro lives in an include file any source module can share. You'll learn the two distinct
> ways code gets reused: **macros** (textual, compile-time) and **linked modules** (compiled,
> `GLOBAL`/`EXTRN`) — and why they're different.

---

## 13.1 The idea: two very different kinds of reuse

As a program grows, one giant file becomes painful. There are two tools for breaking it up, and
the single most important thing in this chapter is understanding that **they are not the same
thing**:

| | **Macro** | **Linked module** |
|---|---|---|
| What it is | a named block of source text | a separately-assembled `.o` object file |
| When it happens | **assembly time** — expanded at each invocation | **link time** — combined by the linker |
| How it's shared | `#include` the file holding it | `GLOBAL`/`EXTRN` + list both files at build |
| Cost | code is *duplicated* at each use | code exists *once*, called via `call` |
| Good for | short, repeated instruction patterns | real subroutines used from many places |

A macro is copy-paste the assembler does for you. A linked module is a real routine that lives at
one address and gets *called*. Use a macro for a two-line pattern you repeat; use a module for a
delay routine, a math helper, an LCD driver.

---

## 13.2 Macros: patterns the assembler pastes in

A macro defines a sequence of source lines, optionally with arguments, that expand wherever you
invoke it (User's Guide §4.9.37). Here's a genuinely useful one — configure any port pin as a
digital output — saved in a shared include file:

```asm
; ============================================================
;  macros.inc  —  shared macro library
; ============================================================

; CONFIG_OUTPUT port, bit, initial : set the latch, then make the pin a digital output
CONFIG_OUTPUT MACRO port, bit, initial
    BANKSEL ANSEL&port                 ; & concatenates: ANSEL + C -> ANSELC
    bcf     BANKMASK(ANSEL&port), bit  ; pin -> digital
    BANKSEL LAT&port                   ; set latch BEFORE changing direction (no output glitch)
    IF initial
        bsf BANKMASK(LAT&port), bit
    ELSE
        bcf BANKMASK(LAT&port), bit
    ENDIF
    BANKSEL TRIS&port
    bcf     BANKMASK(TRIS&port), bit   ; pin -> output; macro leaves BSR here
    ENDM
```

Two macro features on display:

- **Arguments.** `port`, `bit`, and `initial` are substituted at each use. `CONFIG_OUTPUT C, 1, 1`
  sets up RC1 with an initial high latch value (LED off on the active-low Curiosity Nano). Loading
  the latch before clearing `TRIS` avoids a startup glitch.
- **`&` token concatenation.** Inside a macro body, `&` glues tokens together, then vanishes from
  the expansion (User's Guide §4.9.37). So `ANSEL&port` with `port = C` becomes the real register
  name `ANSELC`. (Because `&` has this special meaning in macros, use the word `and` for a bitwise
  AND inside one — the `&` operator is unavailable there.)

> **`LOCAL` — unique labels per expansion.** If a macro contains a label and you use the macro
> twice, you'd get "duplicate symbol" errors — the label would be defined twice. The `LOCAL`
> directive fixes this by generating a unique label for each expansion (User's Guide §4.9.36):
> ```asm
> SHORT_WAIT MACRO reg
>     LOCAL again            ; 'again' becomes a unique symbol each time
>     BANKSEL reg
> again:
>     decfsz BANKMASK(reg),f
>     goto   again
>     ENDM
> ```
> Always `LOCAL` any label inside a macro.

Because a macro is **pasted in every time you invoke it**, its instructions are *duplicated* in
your program. That's fine for a few lines; it's the wrong tool for a big routine — which is what
modules are for.

---

## 13.3 Splitting code across files: `GLOBAL` and `EXTRN`

Put the reusable `delay` routine in its own file. To let another file call it, the *defining* file
must **export** the symbol, and the *using* file must **import** it. The two directives
(User's Guide §4.9.30, §4.9.20):

- **`GLOBAL name`** — makes a locally defined symbol public, or references an external one when
  there is no local definition. The definition needs `GLOBAL`; a consumer may use `GLOBAL` again
  or the stricter `EXTRN` form below.
- **`EXTRN name`** — import-only; declares a symbol defined *elsewhere*. It's an error to use
  `EXTRN` on a symbol defined in the same file (§4.9.20) — which makes your intent explicit.

Here's the delay routine as a standalone module:

```asm
; ============================================================
;  delay.S  —  a reusable ~0.75 s busy-wait, its own module
; ============================================================
    PROCESSOR 16F17146
#include <xc.inc>

    GLOBAL  delay            ; EXPORT: make 'delay' callable from other files

    PSECT   udata_shr
d1: DS  1
d2: DS  1

    PSECT   code,delta=2
delay:
    movlw   0xFF
    movwf   d1
douter:
    movlw   0xFF
    movwf   d2
dinner:
    decfsz  d2,f
    goto    dinner
    decfsz  d1,f
    goto    douter
    return
```

Notice `delay`'s private counters `d1`/`d2` live *with it*, in its own file — `main.S` never sees
them. That encapsulation is the whole point of splitting into modules.

---

## 13.4 The main file — using both

```asm
; ============================================================
;  main.S  —  blinks RC1 using a shared macro + external delay
; ============================================================
    PROCESSOR 16F17146
#include <xc.inc>
#include "macros.inc"        // pull in the macro library (textual)
;  --- paste your Chapter 5 CONFIG block here ---

    EXTRN   delay            ; IMPORT: 'delay' is defined in delay.S

    PSECT   resetVec,class=CODE,delta=2
resetVec:
    goto    main

    PSECT   code,delta=2
main:
    CONFIG_OUTPUT C, 1, 1    ; RC1 digital output, latch high (LED initially off)
    BANKSEL LATC
loop:
    bcf     LATC,1           ; LED on (active-low)
    fcall   delay            ; call the EXTERNAL routine (page-safe - Ch 9)
    bsf     LATC,1           ; LED off
    fcall   delay
    goto    loop

    END     resetVec
```

Two things to note:

- **`#include "macros.inc"`** makes the macro definition part of this preprocessed source module;
  the assembler then expands `CONFIG_OUTPUT` at its invocation. The include file is **not** a
  separate compiled module; macros aren't linked.
- **`fcall delay`** (not plain `call`) because `delay` is in another module and could land in a
  different program-memory page — `fcall` handles the paging for you (Chapter 9).

---

## 13.5 Building a multi-file project

### Single-step — list all the source files
The `pic-as` driver assembles and links in one go; just name every source file (User's Guide
§3.1):

```
pic-as -mcpu=16f17146 -mdfp=/path/to/PIC16F1xxxx_DFP/VERSION/xc8 \
       -Wl,-presetVec=0h -Wl,-Map=blink2.map main.S delay.S
```

The driver assembles `main.S` and `delay.S`, then links them — resolving `main`'s `EXTRN delay`
to the `delay` exported by `delay.S`. (Note `macros.inc` is **not** on the command line — it's
pulled in by `#include`, not linked.)

### Multi-step — assemble once, link once (incremental builds)
For bigger projects you assemble each file to an object (`.o`) with `-c`, then link the objects
(User's Guide §3.2). A make utility (or MPLAB® X) then only re-assembles files that changed:

```
pic-as -mcpu=16f17146 -mdfp=/path/to/PIC16F1xxxx_DFP/VERSION/xc8 -c main.S   # -> main.o
pic-as -mcpu=16f17146 -mdfp=/path/to/PIC16F1xxxx_DFP/VERSION/xc8 -c delay.S  # -> delay.o
pic-as -mcpu=16f17146 -mdfp=/path/to/PIC16F1xxxx_DFP/VERSION/xc8 \
       -Wl,-presetVec=0h main.o delay.o   # link
```

Either way the LED blinks exactly as in Chapter 7 — but now `delay` is a reusable module and the
pin setup is a one-line macro you can drop into any project.

---

## 13.6 Bundling modules into a library: the archiver

Once you have a handful of reusable `.o` modules, you can package them into a single **library
archive** (`.a`) with the librarian, `xc8-ar` (User's Guide §7.1). The linker pulls only the
modules it actually needs out of the archive.

```
xc8-ar -r mylib.a delay.o          # create mylib.a containing delay.o (-r = replace/add)
```

Then link your program against the library instead of the loose object:

```
pic-as -mcpu=16f17146 -mdfp=/path/to/PIC16F1xxxx_DFP/VERSION/xc8 \
       -Wl,-presetVec=0h main.o mylib.a
```

The common `xc8-ar` options (§7.1, Table 7-1): `-r` add/replace a module, `-d` delete, `-p` list
modules, `-t` list with symbols, `-x` extract. One rule that bites people: **module order
matters** — if module A calls a symbol defined in module B, A must come *before* B in the archive,
because the linker searches in order (§7.1). For a beginner, one library of independent helper
routines is plenty; the ordering rule matters once modules call each other.

---

## 13.7 What just happened

You reused code two fundamentally different ways. A **macro** (`CONFIG_OUTPUT`) is source text the
assembler pastes in at each call — shared by `#include`, duplicated at every use, perfect for
short patterns. A **module** (`delay.S`) is a separately-assembled routine that exists once and is
`fcall`-ed — shared by `GLOBAL`/`EXTRN` and combined by the linker, perfect for real subroutines.
You built the project both single-step and incrementally, and packaged a module into a `.a`
library. That's the organizational backbone of every non-trivial assembly project.

---

## 13.8 Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| Linker: "undefined symbol `delay`" | forgot to list `delay.S`/`delay.o` at link, or no `GLOBAL` | export with `GLOBAL delay` in delay.S; include it in the build (§4.9.30) |
| "duplicate symbol" from a macro used twice | a label inside the macro isn't `LOCAL` | wrap internal labels with `LOCAL` (§4.9.36) |
| `EXTRN delay` errors "defined in this module" | you `EXTRN`'d a symbol you also define here | use `EXTRN` only for symbols from *other* files (§4.9.20) |
| Macro won't expand / `&` appears in output | `&` misuse, or invoked a macro that wasn't `#include`d | check the `#include`; `&` only concatenates inside a macro body (§4.9.37) |
| Cross-file `call` gives fixup overflow | callee in another page, plain `call` used | use `fcall` for cross-module calls (Chapter 9) |
| Library link can't resolve a symbol | archive module order wrong | put referencing modules before defining ones (§7.1) |

(Appendix C decodes the exact message wording.)

---

## 13.9 Try it yourself

1. **Reuse the macro.** Add a second `CONFIG_OUTPUT C, 2, 0` and blink RC2 as well (external LED +
   resistor). One macro, two pins.
2. **Prove duplication.** Build the single-step version with `-Wa,-a`, open `main.lst`, and find
   where `CONFIG_OUTPUT` expanded into real instructions — see the macro become code.
3. **Break the link.** Remove `delay.S` from the build command and read the linker's "undefined
   symbol" error. Restore it.
4. **Grow the library.** Write a second module `blinkio.S` exporting a `led_on`/`led_off` pair,
   archive both it and `delay.o` into `mylib.a`, and link `main.o mylib.a`. Confirm with
   `xc8-ar -t mylib.a` that both modules are inside.

---

## 13.10 Reference bridge

- **User's Guide §4.9.37 / §4.9.36** — `MACRO`/`ENDM`, arguments, `&` concatenation, and `LOCAL`.
- **User's Guide §4.9.30 / §4.9.20** — `GLOBAL` and `EXTRN` for cross-file symbols.
- **User's Guide §3.1–3.2** — single-step vs. multi-step (incremental) builds with `pic-as`.
- **User's Guide §7.1** — the archiver/librarian `xc8-ar` and its options.

**Next chapter:** every program so far has run top-to-bottom, polling in loops. Chapter 14
introduces **interrupts** on the PIC16F17146 — letting a hardware event (a timer overflow) stop
your main code, run a service routine, and resume — including the crucial matter of saving and
restoring context so the interruption is invisible to the code it interrupts.
