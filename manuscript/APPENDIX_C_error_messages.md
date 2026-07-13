# Appendix C — Decoding Error & Warning Messages

> **Reference keys:** `[UG]` and `[RN400]` in `REFERENCES.md`.

Every chapter's "common mistakes" table points here. This appendix teaches you to **read** the
assembler's messages, **look them up**, and fix the fifteen problems that trip up beginners most.
Learning to decode errors is not a side skill — it's half of writing assembly.

---

## C.1 How to read a message

The MPLAB® XC8 assembler prints each message in a fixed shape (User's Guide §8):

```
(1507) asmopt state popped when there was no pushed state (Assembler)
```

- **`(1507)`** — a **unique message number**. It's printed with the message and is your lookup key.
- **The text** — the description; where you see a `*` in the guide, the tool substitutes a
  specific string (a filename, symbol, etc.) (§8).
- **`(Assembler)`** — the **application** that produced it. This tells you *which stage* failed.

That last part matters more than beginners expect. The message set is shared across the whole
toolchain — it's "the complete and historical message set covering all former HI-TECH C compilers"
(§8), so **most messages in the guide are about C, not assembly.** Filter by the application tag:

| Tag | Stage | Relevant to assembly? |
|---|---|---|
| `(Preprocessor)` | `#include`/`#define` handling | yes |
| `(Assembler)` | assembling your `.S` | **yes — your main concern** |
| `(Linker)` | placing psects, resolving symbols | **yes** |
| `(Hexmate)` | building the HEX | sometimes |
| `(Driver)` | coordinating options, device packs, and build stages | **yes** |
| `(Code Generator)`, `(Parser)` | the C compiler | usually ignore for pure assembly |

If a message is tagged `(Code Generator)` or `(Parser)`, it is almost certainly about C and not
your pure-assembly source. Driver messages still matter—for example, a missing external DFP is a
driver failure before assembly begins.

---

## C.2 How to look one up

1. Note the **number** the tool printed, e.g. `(107)`.
2. Open the User's Guide **§8 "Error and Warning Messages"** — messages are sorted numerically
   across §8.1–8.5.
3. Read the description and its example. The guide often shows the exact code that triggers it.

Two strategy notes straight from the guide (§8):

- **Fix errors in the order shown.** "You should attempt to resolve errors or warnings in the order
  in which they are displayed."
- **One mistake can spawn several messages.** "One problem in your... source code can trigger more
  than one error message." Fix the first, rebuild, and watch the rest often vanish.

You can also silence *advisory/warning* numbers with the `ERRORLEVEL` directive (Chapter 12) — but
**you cannot disable an error**: attempting `ERRORLEVEL -2070` on an error itself produces message
`(1607)` (§8.4).

---

## C.3 The fifteen most common beginner problems

Symptom → what it means → fix. Cross-references point to the chapter that explains the concept.
Where a message number is shown, it's from the guide's §8; where none is shown, identify the error
by its text and the producing application.

### Build won't even start

**1. `#include` treated as an illegal directive / SFR names undefined** *(Assembler/Preprocessor)*
A lowercase `.s` file normally skips preprocessing, so `#include <xc.inc>` never supplies the
selected device definitions. → Rename it to uppercase **`.S`**, and confirm `-mdfp` points to a
complete installed/unpacked pack's `xc8` directory. (Chapters 3–4)

**2. `(103) #error: *`** *(Preprocessor)*
Your own `#error` directive fired deliberately — often a config guard. → Find the `#error` and
satisfy the condition it's checking. (Chapter 12)

**3. `(111) redefining preprocessor macro "*"`** *(Preprocessor)*
A `#define`d name was redefined to something different. → `#undef` it first, or use a new name.
(Chapter 12)

### Assembler errors (your `.S`)

**4. A hex constant like `FFh` reported as an unknown symbol** *(Assembler)*
Hex numbers must start with a digit, or the assembler reads them as identifiers. → Write **`0FFh`**
or `0xFF`. (Chapter 4 §4.5)

**5. "duplicate symbol" / "symbol already defined"** *(Assembler)*
Either you named something after a keyword (`and`, `goto`, `mod`), or a label inside a macro isn't
`LOCAL` so it's defined on every expansion. → Rename the identifier, or wrap macro-internal labels
with **`LOCAL`**. (Chapters 4, 13)

**6. `(113) unterminated string in preprocessor macro body`** *(Preprocessor)*
A string in a macro is missing its closing quote. → Add the quote. (Chapter 13)

**7. `EQU`-defined symbol won't redefine** *(Assembler)*
`EQU` is define-once. → Use **`SET`** for a value you intend to reassign. (Chapter 12 §12.2)

**8. `movfw` unknown instruction** *(Assembler)*
That MPASM pseudo-instruction doesn't exist in XC8. → Write **`movf f,w`**. (Chapter 6 §6.4)

**9. "contradictory flags" on a `PSECT`** *(Assembler)*
You re-declared a psect with different flags than its first declaration. → Flags propagate from the
first `PSECT`; don't restate them differently. (Chapter 10)

### Linker errors (placement & symbols)

**10. "fixup overflow"** *(Linker)*
An operand's full address (with bank or page bits) is too big for the instruction's narrow address
field. → For data: `BANKSEL` **and** `BANKMASK()` the operand. For calls/jumps across a page:
`PAGESEL` + `PAGEMASK()`, or `fcall`/`ljmp`. The linker option
`-Wl,--fixupoverflow=warn:lstwarn` deliberately truncates the value and is useful for locating
legacy cases; it does **not** select the correct bank/page and is not the fix. (Chapters 8, 9)

**11. "undefined symbol *"** *(Linker)*
A symbol you referenced isn't defined in any linked module. → Make sure the defining file is in the
build, and that the symbol is exported with **`GLOBAL`** (or imported with `EXTRN`). (Chapter 13)

**12. "can't find space for psect *"** *(Linker)*
A psect won't fit its class. → Open the map file's **`UNUSED ADDRESS RANGES`** and check the
**`Largest block`** — the free space may be fragmented into pieces all smaller than your psect.
(Chapter 17 §17.7)

**13. Code psect misbehaves / wrong bytes in HEX** *(Linker/Assembler)*
A `class=CODE` psect on our mid-range chip is missing **`delta=2`** (program memory is word
-addressable). → Add `delta=2` to every code psect. (Chapters 4, 10)

### Config & runtime (builds, but doesn't run right)

**14. `CONFIG` setting rejected: "invalid/unknown setting or value"** *(Assembler)*
A `CONFIG` token doesn't match your Device Family Pack's spelling. → Generate the exact tokens from
MPLAB X's **Configuration Bits** window for the PIC16F17146. (Chapter 5 §5.2)

**15. Builds fine but the chip does nothing / hangs** *(no message — a runtime symptom)*
The most common non-error "error." Usual causes: an interrupt source not acknowledged as its
peripheral requires, so the ISR re-fires (Chapter 14); a pin left analog because `ANSELx` wasn't cleared (Chapter 7); or the
reset vector not placed at 0 (`-Wl,-presetVec=0h`, Chapter 4). → Work the symptom back to its
chapter; the simulator's Watch window is your friend here.

---

## C.4 A worked lookup

Say the build stops with:

```
main.S: (107) illegal # directive "indef" (Preprocessor)
```

Decode it: number **107**, producing app **Preprocessor**, and the substituted text `indef`. Look up
`(107)` in §8.1 — it means the preprocessor doesn't recognize a `#` directive, "probably a
misspelling" (§8.1). And there it is: `#indef` should be `#undef`. Fix the typo, rebuild. That's the
whole loop: **read the number → find it in §8 → apply the fix.**

---

## C.5 Reference

- **User's Guide §8 "Error and Warning Messages"** — the full numbered catalog (§8.1 messages
  0–499 through §8.5 messages 2000–2499). Your lookup table.
- **User's Guide §4.9.18 "Errorlevel Directive"** — enabling/disabling advisory and warning numbers
  (Chapter 12).
- The **"Common mistakes" table** at the end of every chapter — the fastest route from a symptom to
  the concept behind it.
