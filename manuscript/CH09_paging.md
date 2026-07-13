# Chapter 9 — Program Memory & Paging

> **Reference keys:** `[DS17146]` and `[UG]` in `REFERENCES.md`.

> **Scope and validation:** PIC16F17146, enhanced mid-range core; XC8 4.00 with PIC16F1xxxx DFP 1.31.465. Examples: source- and build/link-verified; runtime not hardware-verified.

> **What you'll build:** a program that deliberately puts a subroutine in a *different page* of
> program memory and calls it correctly across the boundary. You'll see the exact failure that
> happens when you ignore paging, and the two clean ways to fix it — `PAGESEL` and the `fcall`
> pseudo-instruction. Paging is banking's twin, one level up: same problem (an instruction can't
> reach far enough), same shape of solution.

---

## 9.1 The idea: `goto` and `call` can't reach the whole program

In Chapter 8 you learned a file-register instruction can only address 128 bytes, so RAM is split
into banks. Program memory has the identical problem. Look at the opcodes for `goto` and `call`
(data sheet §41, Table 41-3):

```
GOTO k   ->  10 1kkk kkkk kkkk     (11 address bits)
CALL k   ->  10 0kkk kkkk kkkk     (11 address bits)
```

Each carries an **11-bit** destination. Eleven bits reach 2^11 = **2048 words**. But the
PIC16F17146 has **16,384 words** of program memory (addresses 0x0000–0x3FFF; data sheet §9.1).
So a single `goto` or `call` can only reach one **2048-word page** — one eighth of the chip's
code space. Sixteen K words ÷ 2K per page = **8 pages**.

Where do the *missing* upper address bits come from? From **`PCLATH`**. When a `call` executes,
the data sheet is explicit (§9.4.3):

> "PCH[2:0] and PCL registers are loaded with the operand of the CALL instruction. PCH[6:3] is
> loaded with PCLATH[6:3]."

Decode that: the 11 bits from the instruction fill PC[10:0], and the top of the address —
**PC[14:11] — comes from `PCLATH`.** `PCLATH` is the *page register* for `goto`/`call`, exactly
as `BSR` is the bank register for RAM. If `PCLATH` points at the wrong page when you `call`, you
land in the wrong page. That's the whole story.

```
 15-bit program address:   pppp  kkkkkkkkkkk
                           └─┬─┘  └────┬────┘
                        PCLATH[6:3]  goto/call operand (11 bits, 0-2047)
```

---

## 9.2 Why you often don't notice paging

Here's the good news for beginners: **a program that fits inside one page never needs paging.**
Every blink and demo so far has been a few dozen words — comfortably inside page 0 — so every
`goto`/`call` reached its target with `PCLATH` already correct (it's 0 after Reset). You've been
paging-safe by accident.

You only have to think about pages when either:
- your program grows past **2048 words** and code spills into page 1 or beyond, or
- you deliberately place a routine in a specific high page (which we're about to do).

That's why paging feels invisible until a project gets big — and then, for someone who never
learned it, becomes a baffling "my working subroutine suddenly jumps to garbage" bug. Let's make
it happen on purpose so it never surprises you.

---

## 9.3 `PAGESEL` and `PAGEMASK`: the manual fix

The tools mirror Chapter 8's banking pair exactly (User's Guide §4.1.2–4.1.3):

- **`PAGESEL label`** sets the page bits for you. On this enhanced mid-range core it expands to a
  single **`MOVLP k`** ("Move literal to PCLATH," data sheet §41) that loads `PCLATH` with
  `label`'s page. It's the program-memory twin of `BANKSEL`.
- **`PAGEMASK(label)`** strips the page bits off the address so the remaining 11 bits fit the
  `goto`/`call` operand field — the twin of `BANKMASK`.

So a correct cross-page call, done by hand, is:

```asm
    PAGESEL myFarRoutine          ; PCLATH <- page of myFarRoutine  (movlp)
    call    PAGEMASK(myFarRoutine) ; 11-bit operand fits the opcode
    PAGESEL $                      ; restore PCLATH to THIS page for what follows
```

That last line matters and catches people: after the call returns, `PCLATH` still points at the
callee's page. Any *later* `goto`/`call` in the current routine would use that stale page. Use
the location counter `$` — "this page" — to put `PCLATH` back (User's Guide §4.1.2 shows exactly
this `PAGESEL $` idiom).

> **Trap — not right after a skip.** Like `BANKSEL`, `PAGESEL` can expand to more than one
> instruction on some cores, so never place it immediately after a `btfsc`/`btfss` (User's Guide
> §4.1.2).

---

## 9.4 `fcall` and `ljmp`: let the assembler do it

Tracking `PCLATH` by hand is exactly the kind of bookkeeping that invites bugs. The XC8 assembler
offers two pseudo-instructions that handle page selection **and** masking for you (User's Guide
§4.1.7):

| Pseudo-instruction | Expands to | Does for you |
|---|---|---|
| `fcall label` | page selection + `call` + caller-page reselection as needed | page-safe subroutine call and return |
| `ljmp label`  | page selection + `goto` as needed | page-safe jump |

With these you simply write:

```asm
    fcall   myFarRoutine     ; correct whether the target is near or far
    ljmp    someLabel        ; ditto for a jump
```

and the assembler emits a page-safe expansion. For an `fcall`, that expansion can include page
selection before the `call` and reselection of the caller's page after it returns. Do not depend on a
same-page `fcall` collapsing to a plain `call`: XC8 4.00 emits `movlp` + `call` + `movlp` for the
PIC16F17146 even when caller and callee ultimately share a page. The guide recommends these
mnemonics "where possible" because they make source independent of where routines finally land
(User's Guide §4.1.7). The operand is the *full* address (do **not** mask it — the pseudo-instruction
needs the whole address to select and mask the destination).

> **Two cautions from the guide (§4.1.7).** `fcall`/`ljmp` can expand to several instructions, so
> never put one right after a skip. And they assume the *containing* psect is smaller than a
> page — which the default linker enforces anyway (it won't let a code psect exceed one page).

---

## 9.5 The whole program — a genuine cross-page call

To demonstrate paging in a *small* program, we force a subroutine into **page 1** by giving it
its own psect and telling the linker to position that psect at address **0x0800** (the first
address of page 1). Main lives at the reset vector in page 0 and calls across the gap.

```asm
; ------------------------------------------------------------
;  paging.S  —  call a subroutine that lives in a different page
; ------------------------------------------------------------

    PROCESSOR 16F17146
#include <xc.inc>
;  --- paste your Chapter 5 CONFIG block here ---

    PSECT udata_shr
flag: DS  1

; --- reset entry (page 0) ------------------------------------
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main

; --- main code, page 0 ---------------------------------------
    PSECT code,delta=2
main:
    ; Correct cross-page call, the easy way:
    fcall   farRoutine        ; assembler adds PCLATH setup because
                              ; farRoutine is in page 1

    ; Correct cross-page call, the manual way (equivalent):
    PAGESEL farRoutine        ; movlp <page 1>
    call    PAGEMASK(farRoutine)
    PAGESEL $                 ; restore PCLATH to page 0

    goto    $                  ; done - spin

; --- a routine deliberately placed in PAGE 1 -----------------
; Linked to 0x0800 via:  -Wl,-pfarCode=0800h
    PSECT farCode,class=CODE,delta=2
farRoutine:
    BANKSEL flag
    bsf     flag,0            ; prove we got here: set a flag bit
    return

    END     resetVec
```

Build it, positioning `farCode` at the start of page 1:

```
pic-as -mcpu=16f17146 -mdfp=/path/to/PIC16F1xxxx_DFP/VERSION/xc8 \
       -Wl,-presetVec=0h -Wl,-pfarCode=0800h \
       -Wa,-a -Wl,-Map=paging.map paging.S
```

The `-Wl,-pfarCode=0800h` option pins the `farCode` psect at 0x0800, guaranteeing `farRoutine` is
in page 1 while `main` runs from page 0. In the simulator, single-step the `fcall` and watch:
you'll see the assembler-inserted `movlp 0x08` load `PCLATH` before the `call`, the PC jump into
0x08xx, `flag` bit 0 get set, and a second `movlp` reselect page 0 after `return`. The literal is
**0x08**, not the human page number 1: `CALL` takes its upper destination bits from
`PCLATH[6:3]`, so those bits must encode page 1.

---

## 9.6 See the failure (do this once)

Replace the whole `fcall`/`PAGESEL` sequence with a naive:

```asm
    call    farRoutine        ; WRONG: no page setup, unmasked 15-bit address
```

Rebuild. The linker raises a **fixup overflow** — `farRoutine`'s address (≥ 0x0800) doesn't fit
the 11-bit `call` field, and you never told `PCLATH` which page to use. That error is the linker
protecting you. Seeing it once, and knowing it means "you crossed a page without saying so," is
worth more than any amount of theory.

---

## 9.7 What just happened

Program memory is paged the same way data memory is banked: an instruction reaches only part of
the space (2048 words), and a page register (`PCLATH`) supplies the rest. You fixed a real cross
-page call two ways — the explicit `PAGESEL` + `PAGEMASK` + `PAGESEL $` sequence, and the
one-line `fcall` that hides all of it. And you saw the fixup-overflow error that flags a
forgotten page.

The symmetry is worth memorizing:

| | Data memory | Program memory |
|---|---|---|
| Reach of one instruction | 128 bytes (bank) | 2048 words (page) |
| Page/bank register | `BSR` | `PCLATH` |
| "Set it" directive | `BANKSEL` (→ `movlb`) | `PAGESEL` (→ `movlp`) |
| "Trim the operand" macro | `BANKMASK` | `PAGEMASK` |
| Auto-everything helper | — | `fcall` / `ljmp` |

---

## 9.8 Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| Linker "fixup overflow" on a `call`/`goto` | target in another page, address unmasked | use `fcall`/`ljmp`, or `PAGESEL` + `PAGEMASK` (§4.1.7) |
| Call reaches the wrong place, no error | `PAGEMASK` used but `PCLATH` never set | pair it with `PAGESEL` (or just use `fcall`) |
| A later jump misbehaves after a cross-page call | `PCLATH` left pointing at the callee's page | `PAGESEL $` to restore the current page (§4.1.2) |
| `fcall`/`ljmp` target won't link | you masked the operand | pass the **full** address; the pseudo-instruction masks it (§4.1.7) |
| Odd behavior when `PAGESEL` follows a `btfsc` | it can expand to multiple instructions | never place `PAGESEL`/`fcall` right after a skip (§4.1.2) |

(Appendix C decodes the exact message wording.)

---

## 9.9 Try it yourself

1. **Read the inserted `movlp`.** Build `paging.S`, open the `.lst`, and find where `fcall`
   expanded to page selection + `call` + caller-page reselection. Confirm the first `movlp` literal
   is 0x08 (selecting page 1) and the post-call instruction reselects page 0.
2. **Trigger and read the error.** Do the §9.6 experiment: swap in a plain `call farRoutine`,
   build, and read the linker's fixup-overflow message word for word. Then restore the fix.
3. **Move the routine home.** Delete the `-Wl,-pfarCode=0800h` option so `farCode` can link into
   page 0 alongside `main`. Rebuild and inspect the `.lst`: with XC8 4.00 the `fcall` remains a
   page-safe multi-instruction expansion even though both page literals now select page 0. This is
   why you inspect generated code rather than assuming pseudo-instructions are optimized away.
4. **Restore-page bug.** In the manual sequence, delete `PAGESEL $`, add another `goto` to a
   page-0 label afterward, and see whether it still lands correctly. Explain what `PCLATH` held.

---

## 9.10 Reference bridge

- **Data sheet §9.4 "PCL and PCLATH"** and **§9.4.3 "Computed Function Calls"** — how the PC is
  assembled from the opcode and `PCLATH`, now that you've used it.
- **Data sheet §41** — the `goto`, `call`, and `movlp` opcodes whose 11-bit field started this.
- **User's Guide §4.1.2, §4.1.3, §4.1.7** — `PAGESEL`, `PAGEMASK`, and the `fcall`/`ljmp`
  pseudo-instructions, formally.

**Next chapter:** you've now met psects a dozen times — `code`, `resetVec`, `udata_shr`,
`farCode` — and positioned them with linker options. Chapter 10 finally explains **psects
themselves** in full: classes, flags (`delta`, `space`, `reloc`), and how the linker turns your
named sections into real addresses. It's the concept the official guides assume you already know.
