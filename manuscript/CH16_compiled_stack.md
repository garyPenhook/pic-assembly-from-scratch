# Chapter 16 — The Compiled Stack

> **Reference keys:** `[UG]`, `[EE]`, `[DS17146]`, `[DS18Q43]`, and `[CUG]` in `REFERENCES.md`.

> **Scope and validation:** PIC16F17146 and PIC18F57Q43 examples; XC8 4.00 with PIC16F1xxxx DFP 1.31.465 and PIC18F-Q DFP 1.30.487. Examples: source- and build/link-verified; runtime not hardware-verified.

> **What you'll learn:** how assembly routines get **local variables** — the assembly equivalent
> of a C function's `auto` and parameter variables — even though a PIC® microcontroller has no hardware data stack.
> You'll meet the **compiled stack**: memory the *linker* hands out and cleverly **reuses** across
> routines that never run at the same time. This is how large assembly programs keep their RAM
> footprint small without dangerous manual sharing.

---

## 16.1 The idea: locals without a data stack

In C, every function gets private locals for free — `int x;` inside a function exists only while
that function runs, and its memory is recycled for the next call. Under the hood, C on a big CPU
uses a **hardware data stack**: push locals on entry, pop on exit.

The PIC has a stack, but it's a *return-address* stack only — it holds PC values for `CALL`/
`RETURN` (Chapter 9's §9.5), not your variables. There's no push/pop for data. So how does an
assembly routine get recyclable locals?

The answer is the **compiled stack** — and the name is slightly misleading, so read carefully
(User's Guide §5.5; Embedded Engineers guide §6):

> "Not to be confused with a software stack... a compiled stack is a memory area designated for
> the **static** allocation of local objects that should only consume memory for the duration of
> the routine with which they are associated."

There's **no stack pointer and no push/pop.** Each routine's locals get *fixed* addresses,
assigned by the **linker**. The magic is that the linker can give **two routines the same
addresses** for their locals — *provided they're never active at the same time.* Memory that a
helper routine uses is quietly reused by another helper that never overlaps with it.

**Why bother?** Big programs have dozens of routines each needing a few local bytes. Give each its
own permanent RAM and you run out fast. The compiled stack lets non-overlapping routines share the
same bytes — big RAM savings, and because it's static there's **no speed or code-size penalty**
(no pointer math) (Emb Eng §6).

> **The one hard rule: not reentrant.** Because the addresses are static, a routine using
> compiled-stack locals **cannot be recursive**. As a safe assembly convention, do not place the
> same compiled-stack routine in both a main-line and interrupt call graph: an interrupt could
> preempt an active instance and corrupt its fixed locals. Use a separate root and separate
> routines/state for each asynchronous call graph (Emb Eng §6; User's Guide §5.5).

---

## 16.2 The tools: the `FN` directives

The linker can only reuse memory safely if it knows **who calls whom** — the program's *call
graph*. You describe that graph with four directives, all starting `FN` (Emb Eng §6.1;
User's Guide §5.5):

| Directive | Used | Says |
|---|---|---|
| `FNCONF psect,?au_,?pa_` | **once** per program | put the stack in this psect; prefix auto symbols with `?au_`, parameters with `?pa_` |
| `FNROOT routine` | once per call-graph root | this routine is the top of a call tree (typically `main`, and one per ISR) |
| `FNSIZE routine,autos,params` | per routine with locals | this routine needs *autos* bytes of locals and *params* bytes of parameters |
| `FNCALL caller,callee` | per unique call | *caller* calls *callee* (an edge in the graph) |

From these, the linker builds the call graph, creates a symbol for each routine's local block
(`?au_<routine>` for autos, `?pa_<routine>` for parameters), assigns addresses, and **overlaps
blocks wherever the graph proves it's safe** (Emb Eng §6.2).

---

## 16.3 A worked example

The following is an independently written adaptation of the compiled-stack pattern described in
the reference (Emb Eng §6) — a `main` that repeatedly
calls `add(a,b)` and `incr(val,amount)`. It's PIC18 (note `movff`, `,c` access operands from
Chapter 15) — built and verified here on a **PIC18F57Q43** — but the *stack concepts* are identical
on every core.

```asm
;--- configure the stack: hold it in udata_acs; prefixes for autos/params
FNCONF udata_acs,?au_,?pa_

;--- add: needs 4 bytes of parameters, no autos --------------
FNSIZE  add,0,4              ; two 2-byte 'int' parameters
GLOBAL  ?pa_add             ; linker-made symbol for add's parameter block
add:
    movf   BANKMASK(?pa_add+2),w,c
    addwf  BANKMASK(?pa_add+0),f,c
    movf   BANKMASK(?pa_add+3),w,c
    addwfc BANKMASK(?pa_add+1),f,c
    return                  ; result left in the parameter memory

;--- main: the call-graph root, needs 4 bytes of autos -------
GLOBAL  ?au_main
result  EQU ?au_main+0       ; readable aliases for main's autos
incval  EQU ?au_main+2
FNROOT  main                 ; main is the top of a call graph
FNSIZE  main,4,0             ; 4 bytes of autos (result + incval), no params
FNCALL  main,add             ; main calls add
FNCALL  main,incr            ; main calls incr
main:
    clrf   BANKMASK(result+0),c
    clrf   BANKMASK(result+1),c
    ...
    call   add               ; (parameters loaded into ?pa_add first)
    ...
```

Read the pattern:

- **`FNSIZE add,0,4`** reserves 4 bytes for `add`'s parameters; the linker names that block
  **`?pa_add`**, and you reach each byte as `?pa_add+0`, `?pa_add+1`, … (Emb Eng §6.1).
- **`FNSIZE main,4,0`** gives `main` 4 bytes of autos, block **`?au_main`**. The `EQU` lines just
  make `result`/`incval` friendlier names for `?au_main+0` and `?au_main+2`.
- **`FNCALL main,add`** / **`FNCALL main,incr`** tell the linker main's call edges — *the*
  information that lets it decide what can overlap.
- **Return values** live in the parameter memory: a routine writes its result where its parameters
  were. So size a routine's params as the *larger* of its parameters and its return value
  (Emb Eng §6.1).

You invent the calling convention yourself — here, the first `int` parameter is `?pa_add+0/+1`
(low/high byte), the second is `?pa_add+2/+3`. Nothing enforces this but your own consistency.
The linker-defined symbols contain full physical addresses (for this Q43 example, in
`0x500–0x55F`), so byte-oriented instructions use `BANKMASK(...),c`. In contrast, `movff`
operands use the full addresses and must not be masked (User's Guide §4.1.1/§4.1.5).

Build the verified Q43 source with the matching pack and explicitly place the stack psect:

```
pic-as -mcpu=18F57Q43 -mdfp=/path/to/Microchip.PIC18F-Q_DFP/1.30.487/xc8 \
  -Wl,-presetVec=0h -Wl,-pudata_acs=COMRAM -mcallgraph=full \
  -Wa,-a -Wl,-Map=cstack.map cstack.S
```

---

## 16.4 Seeing the overlap in the map file

Build with a call graph (`-mcallgraph=full`) and the map file shows the linker's work (Emb Eng
§6.2):

```
Call graph: (fully expanded)
*main size 0,4 offset 0
*    add size 4,0 offset 4
     incr size 2,0 offset 4
```

This tiny listing is the whole point of the chapter:

- **Indentation = call depth**: `main` calls `add` and `incr`.
- **The `offset` for `add` and `incr` is the same (4).** That means **they share the same memory** —
  the linker proved it's safe because `add` and `incr` never call each other, so they're never
  active simultaneously.
- **A `*`** marks a *critical-path* node — memory at a unique location that adds to total RAM.
  Un-starred routines' blocks fully overlap others and cost **zero** extra RAM.

The measured payoff in this example (compare Emb Eng §6.2) is **10 bytes** of logical locals with
only **8** bytes allocated — 2 bytes reused. That reuse is linker-proven from the call graph, not
manual sharing between routines. In the verified Q43 map, the call-graph
offsets are 0 and 4, while the corresponding physical
symbols are `?au_main = 0x500` and `?pa_add = ?pa_incr = 0x504` because `udata_acs` was placed in
the Q43 `COMRAM` class. No special build option is required when the linker detects the `FN`-type
directives (Emb Eng §6.3).

---

## 16.5 On the PIC16F17146

The example above is PIC18, which conveniently has a roomy Access bank for the stack. Our
mid-range target differs in two ways (Emb Eng §6.1):

- **Where the stack lives.** Mid-range parts have only 16 bytes of common RAM, usually needed
  elsewhere, so you put the compiled stack in **banked GPR** — e.g. `FNCONF udata,?au_,?pa_` — and
  access its objects with the `BANKSEL`/`BANKMASK` you learned in Chapter 8.
- **How you touch it.** No `movff` on mid-range (Chapter 8), so you move locals through `W` with
  `movf`/`movwf`, selecting the stack's bank first.

Everything else — `FNCONF`/`FNROOT`/`FNSIZE`/`FNCALL`, the `?au_`/`?pa_` symbols, the call-graph
overlap — works identically. And remember the reentrancy rule from §16.1: give each **interrupt**
routine its **own `FNROOT`**, so its locals never share bytes with main-line routines that an
interrupt could preempt (User's Guide §5.5).

---

## 16.6 What just happened

You gave assembly routines proper local variables. The **compiled stack** is a linker-managed,
statically-addressed region where each routine's locals live only "logically" for its duration —
and the linker **overlaps the locals of routines that never run together**, cutting RAM use with
no runtime cost. You drive it with four `FN` directives that describe your call graph, read the
`?au_`/`?pa_` symbols the linker creates, and verify the overlap in the map file's call graph. The
price of admission is discipline: keep the `FN` directives accurate, and never share a
compiled-stack routine between main and an interrupt.

---

## 16.7 Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| Locals of two routines corrupt each other | a missing `FNCALL` hid a real call, so the linker wrongly overlapped them | add an `FNCALL` for **every** unique call (Emb Eng §6.2) |
| "undefined symbol `?pa_add`" | forgot to `GLOBAL` the linker-created stack symbol | `GLOBAL ?pa_add` in each module that uses it (Emb Eng §6.1) |
| Data corrupted only when an interrupt fires | a routine is called from both main and the ISR | give the ISR its own `FNROOT`; don't share compiled-stack routines (§5.5) |
| Return value clobbered | params sized smaller than the return value | size params as the larger of parameters and return value (Emb Eng §6.1) |
| No overlap happening / RAM higher than expected | `FNROOT`/`FNSIZE`/`FNCALL` missing or wrong | check the call graph in the map file against your real call structure |
| Warning about the `FNCONF` psect | stack psect not placed | add `-Wl,-p<psect>=<class>` (e.g. `-Wl,-pudata_acs=COMRAM`) (Emb Eng §6.3) |

(Appendix C decodes the exact message wording.)

---

## 16.8 Try it yourself

1. **Find the overlap.** Build Microchip's example with the exact command in §16.3,
   open the map, and confirm `add` and `incr` share `offset 4` while `main` sits at `offset 0`.
2. **Break the graph.** Delete `FNCALL main,incr`, rebuild, and study how the call graph and the
   overlap change — then explain why that omission would be dangerous in real code.
3. **Add a third helper.** Write a `dbl` routine (needs 2 param bytes) that `main` also calls, add
   its `FNSIZE`/`FNCALL`, and check whether the linker overlaps it with `add`/`incr` or gives it
   its own slot. Explain the result from the call graph.
4. **Port the idea to mid-range.** Sketch (on paper) the `FNCONF udata,...` version for the
   PIC16F17146: which directive changes, and where would `BANKSEL`/`BANKMASK` appear when reading
   `?pa_add`?

---

## 16.9 Reference bridge

- **Embedded Engineers guide §6** — the full compiled-stack example, the `FN` directives, and the
  annotated call graph in the map file.
- **User's Guide §5.5** — a summary of compiled stacks and the `FN` directives.
- **User's Guide §4.9.24–4.9.29** — the individual `FNCALL`/`FNCONF`/`FNROOT`/`FNSIZE` directive
  references (plus `FNARG`, `FNINDIR` for advanced call graphs).

**Next chapter (Part V):** you've now generated map files a dozen times and peeked at call graphs
and symbol tables. Chapter 17 finally reads the **map file** properly — memory ranges, psect
placement, linker classes, and the linker-defined symbols — so you can see exactly where every
byte of your program landed and diagnose placement problems yourself.
