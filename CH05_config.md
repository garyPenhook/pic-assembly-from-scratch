# Chapter 5 — Configuration Bits & the Reset Vector

> **What you'll build:** `spin.S` from Chapter 4, upgraded with a proper **Configuration Word
> block** so it will start reliably on real PIC16F17146 silicon — not just on the simulator's
> forgiving defaults. You'll choose an oscillator, switch the watchdog off, and settle the
> MCLR/programming pins on purpose instead of by accident.

---

## 5.1 The idea: settings you burn in *before* your code runs

Your program isn't the first thing that decides how the chip behaves. Before a single
instruction executes, the PIC16F17146 reads a handful of **Configuration Words** out of a
special nonvolatile configuration region and uses them to wire itself up: which clock to run from, whether the
watchdog timer can reset you, what the MCLR pin does, whether the memory is code-protected.

Get these wrong and the failure is baffling for a beginner — the chip resets in a loop, or
runs at the wrong speed, or requires a different programming entry mode. Get them right once and
you rarely think about them again.

The PIC16F17146 has **five Configuration Words**, physically located at program addresses
**0x8007–0x800B**, and they "select the device oscillator, Reset and memory protection
options" (verified: data sheet DS40002343F §8.1). You set them from source with the
assembler's `CONFIG` directive; the assembler places the resulting bits at those addresses
and the programmer burns them in alongside your code.

> **The reset vector connection.** Chapter 4 relied on the fact that the chip begins executing
> at **0x0000** after a Reset (data sheet §9.1). Config bits decide *what kind of resets can
> happen* and *what clock is running when execution reaches 0x0000*. Reset behavior and the
> reset vector are two halves of the same story — that's why they share this chapter.

---

## 5.2 Get the tokens from the selected DFP (then understand them)

Here is the professional workflow, and it matters:

**The hardware meaning of each field comes from the data sheet. The accepted symbolic value
tokens (`ON`, `OFF`, `HFINTOSC_1MHz`, …) come from the exact Device Family Pack (DFP) selected
for the build.** Open that pack's `xc8/docs/pic_chipinfo.html`, follow the PIC16F17146 link, and use
the page's **PIC-AS config Usage** and field tables. The block in §5.4 was assembled with XC8 4.00
and PIC16F1xxxx_DFP **1.31.465**.

A **Configuration Bits** view (MPLAB X: *Window → Target Memory Views → Configuration Bits*; in
VS Code the MPLAB Code Configurator / project config UI serves the same role) is useful for
exploring the choices. Depending on the IDE/project, generated output can use C's `#pragma config`
syntax;
do not paste that syntax into a `.S` file and assume it is pic-as syntax. For assembly-only source,
copy the same setting/value decisions into quoted pic-as `CONFIG` directives using the selected
DFP's chipinfo page. In all cases, inspect the final map and HEX rather than treating a generated
block as self-validating.

---

## 5.3 The five decisions that matter for a first program

Everything in the config block is one of five kinds of decision. For a simple blink we make the
simplest safe choice for each; every meaning here is verified against DS40002343F §8.6.

### Decision 1 — What clock runs the chip? (CONFIG1)
We want zero external parts, so we run from the **internal oscillator (HFINTOSC)** and use no
external crystal.

| Field | Our choice | Why (data sheet §8.6.1) |
|---|---|---|
| `FEXTOSC` | **off / not enabled** | value `100` = "Oscillator not enabled" — we use no external crystal |
| `RSTOSC` | **HFINTOSC** | value `110` selects HFINTOSC at 1 MHz on power-up (value `000` would give 32 MHz) |
| `CLKOUTEN` | **off** | value `1` = CLKOUT disabled, so that pin stays a normal I/O |
| `CSWEN` | **on** | value `1` = software is allowed to switch clocks later if it wants |
| `FCMEN` | **on** | value `1` enables the monitor; it applies to external oscillator modes and is dormant while HFINTOSC is selected |
| `VDDAR` | **high range for the board's default 3.3 V** | value `1` = analog calibrated for VDD 2.3–5.5 V; value `0` = 1.8–3.6 V |

The internal oscillator is the beginner's best friend: nothing to wire, no crystal to get
wrong, and it's plenty accurate for blinking an LED.

`VDDAR = HI` matches the Curiosity Nano's factory-default 3.3 V target supply. If you change the
board supply below 2.3 V, select `VDDAR = LO` and recheck every peripheral's operating limits.

### Decision 2 — Can the watchdog reset me? (CONFIG3)
The **Windowed Watchdog Timer (WWDT)** resets the chip if your code doesn't periodically
"pet" it. That's a great safety feature for shipping firmware and a constant nuisance while
learning. Turn it **off** for now.

| Field | Our choice | Why (§8.6.3) |
|---|---|---|
| `WDTE` | **off** | value `00` = "WDT disabled, the SEN bit is ignored" |

(The other WDT fields — `WDTCPS`, `WDTCWS`, `WDTCCS` — set the period and window. They have no
run-time effect with `WDTE` off, but §5.4 still programs their erased/default selections explicitly
so the complete intent is visible.)

### Decision 3 — What does the MCLR pin do, and how do I program the chip? (CONFIG2 + CONFIG4)
This is the pairing that traps the most beginners, so read carefully. Two fields interact:

- **`LVP`** (CONFIG4, §8.6.4) — Low-Voltage Programming. Value `1` = "Low-Voltage Programming
  is enabled. MCLR/VPP pin function is MCLR. **The MCLRE bit is ignored.**"
- **`MCLRE`** (CONFIG2, §8.6.2) — Master Clear Enable. Only has an effect *when `LVP = 0`*.

Read that carefully: **if `LVP = 1`, the MCLR pin is forced to be MCLR and your `MCLRE` setting
does nothing.** For a beginner using the Curiosity Nano's on-board ICSP debugger, **keep
`LVP = 1`** — low-voltage programming keeps MCLR working as a reset pin automatically.

| Field | Our choice | Why |
|---|---|---|
| `LVP` | **on** | value `1` = low-voltage programming enabled; MCLR pin is MCLR; MCLRE ignored (§8.6.4) |
| `MCLRE` | **on** | value `1` = MCLR pin is MCLR — matters only if you ever set LVP off (§8.6.2) |

> **Programming-entry guardrail.** With `LVP = 0`, subsequent programming must enter with
> **high voltage** on MCLR (§8.6.4). A low-voltage-only debugger then cannot reconnect. The
> device is recoverable with suitable HV-capable hardware, but the Curiosity Nano guide warns
> that an external tool's high voltage can damage board resistor R110. A low-voltage session
> cannot itself clear `LVP` to zero (§8.6.4 note 1), which prevents accidentally dropping out of
> LVP while that session is active.

### Decision 4 — Should the chip protect itself from brown-outs and bad startups? (CONFIG2)
Reasonable safety defaults that won't get in your way:

| Field | Our choice | Why (§8.6.2) |
|---|---|---|
| `BOREN` | **on while running** | value `10`, DFP token `NSLEEP`, enables BOR while running and disables it in Sleep |
| `BORV` | **low trip point** | value `1` = VBOR nominally 1.9 V (value `0` is nominally 2.65 V; see electrical limits) |
| `PWRTS` | your call | Power-up Timer; e.g. value `10` = 64 ms startup delay for supply to settle |
| `STVREN` | **on** | value `1` = a stack overflow/underflow causes a Reset — catches runaway recursion |
| `LPBOREN` | off | value `1` = Low-Power BOR disabled (fine for a mains/USB-powered board) |
| `PPS1WAY` | on | value `1` = PPS can be locked once; safe default (we cover PPS in Chapter 7) |
| `DACAUTOEN` | off | value `1` leaves DAC buffer range under `REFRNG` software control; the DAC is unused here |

### Decision 5 — Lock the memory down? (CONFIG4 + CONFIG5)
While learning you want the memory **open** so you can reprogram and read back freely. Every one
of these is the "not protected / disabled" choice:

| Field | Our choice | Why (§8.6.4–8.6.5) |
|---|---|---|
| `CP` | **off** | value `1` = user program-flash code protection disabled (§8.6.5) |
| `CPD` | **off** | value `1` = Data EEPROM code protection disabled (§8.6.5) |
| `WRTAPP`,`WRTB`,`WRTC`,`WRTD`,`WRTSAF` | **off** | value `1` = the corresponding block is *not* write-protected (§8.6.4) |
| `BBEN` | **off** | value `1` = Boot Block disabled — we don't need a bootloader region (§8.6.4) |
| `SAFEN` | **off** | value `1` = Storage Area Flash disabled (§8.6.4) |
| `BBSIZE` | **512 words** | explicit but inactive while `BBEN` is off |

> **Note the polarity.** For most protection bits, **`1` means "unlocked/disabled protection."**
> This is deliberate: an erased flash cell reads as `1`, so a blank device powers up wide open,
> and you opt *into* protection by writing `0`. Once you write a protection bit to `0`, the data
> sheet warns it can typically only be undone with a **Bulk Erase** (§8.6.4 note 2, §8.6.5 note
> 2) — so don't enable protection casually while learning.

---

## 5.4 The upgraded program

Below is `spin.S` with a config block added. **These tokens are verified against
PIC16F1xxxx_DFP 1.31.465 and assemble cleanly with XC8 4.00.** If you select another DFP, check
its `pic_chipinfo.html` before building. Every implemented field is stated explicitly except
`DEBUG`, which the development tools own.

```asm
; ------------------------------------------------------------
;  spin.S  —  minimal PIC16F17146 program, now board-ready
; ------------------------------------------------------------

    PROCESSOR 16F17146
#include <xc.inc>

; --- Configuration Words (0x8007-0x800B, data sheet §8.1) ----
; These tokens are verified against PIC16F1xxxx_DFP 1.31.465.
; If your selected DFP differs, check xc8/docs/pic_chipinfo.html.
; The *intent* of each line is explained in §5.3.

; CONFIG1 — clock: run from internal HFINTOSC, no external crystal
    CONFIG "FEXTOSC = OFF"           // no external oscillator
    CONFIG "RSTOSC = HFINTOSC_1MHz"  // start on HFINTOSC, 1 MHz
    CONFIG "CLKOUTEN = OFF"          // CLKOUT pin is normal I/O
    CONFIG "CSWEN = ON"              // allow software clock switching
    CONFIG "VDDAR = HI"              // board-default 3.3 V range
    CONFIG "FCMEN = ON"              // fail-safe monitor enabled

; CONFIG2 — resets & MCLR
    CONFIG "MCLRE = EXTMCLR"         // MCLR pin is MCLR (ignored when LVP=ON)
    CONFIG "PWRTS = PWRT_64"         // 64 ms power-up timer
    CONFIG "LPBOREN = OFF"           // low-power BOR off
    CONFIG "BOREN = NSLEEP"          // BOR on while running, off in Sleep
    CONFIG "DACAUTOEN = OFF"         // REFRNG controls range; DAC unused
    CONFIG "BORV = LO"               // VBOR = 1.9 V
    CONFIG "ZCD = OFF"               // zero-cross detect off by default
    CONFIG "PPS1WAY = ON"            // PPS one-way lock
    CONFIG "STVREN = ON"             // stack over/underflow -> reset

; CONFIG3 — watchdog OFF while learning; inactive fields explicit
    CONFIG "WDTCPS = WDTCPS_31"  // erased/default period selection
    CONFIG "WDTE = OFF"          // watchdog disabled
    CONFIG "WDTCWS = WDTCWS_7"   // erased/default window selection
    CONFIG "WDTCCS = SC"         // erased/default clock selection

; CONFIG4 — programming & write protection
    CONFIG "BBSIZE = BB512"      // inactive because BBEN=OFF
    CONFIG "LVP = ON"            // low-voltage programming (keep ON)
    CONFIG "BBEN = OFF"          // no boot block
    CONFIG "SAFEN = OFF"         // no Storage Area Flash
    CONFIG "WRTAPP = OFF"        // application not write-protected
    CONFIG "WRTB = OFF"          // boot block not write-protected
    CONFIG "WRTC = OFF"          // config not write-protected
    CONFIG "WRTD = OFF"          // data EEPROM not write-protected
    CONFIG "WRTSAF = OFF"        // SAF not write-protected

; CONFIG5 — code protection OFF while learning
    CONFIG "CP = OFF"            // program flash readable
    CONFIG "CPD = OFF"           // data EEPROM readable

; --- Reset entry point (chip starts at 0x0000, §9.1) ---------
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main

; --- Main program --------------------------------------------
    PSECT code
main:
    goto    $                    ; endless loop

    END     resetVec
```

---

## 5.5 Build & run it

Same command as Chapter 4 (with `DFP` set as in Chapter 3):
```
pic-as -mcpu=16f17146 -mdfp="$DFP" -Wl,-presetVec=0h \
       -Wa,-a -Wl,-Map=spin.map spin.S
```
The build now also programs the five Configuration Words. If you flash this to a real
PIC16F17146 (Chapter 18 covers the mechanics), it comes up running from the internal 1 MHz
oscillator, watchdog off, MCLR working, memory open for reprogramming — a clean, predictable
starting state.

> **DEBUG bit — leave it alone.** You won't see a `DEBUG` line in generated code, and that's
> correct: the data sheet says the `DEBUG` bit "is managed automatically by device development
> tools" and must stay `1` for normal operation (§8.1, §8.6.2 note 1). MPLAB X flips it for you
> when you launch a debug session. Never set it by hand.

> **Errata check.** Exact-device errata DS80001009E §1.3.1 reports unexpected wake-from-Sleep
> behavior only for B0 silicon. This example never executes `SLEEP`; check the revision ID and
> current errata before adding low-power behavior. The current B4 column does not mark that issue.

---

## 5.6 What just happened

You told the chip, in permanent-until-reprogrammed flash, *how to be itself* before your code
gets a vote: internal clock, no watchdog surprises, MCLR as reset, low-voltage programming so
your tool can always reconnect, and no memory locks to trip over. That's the boring, essential
groundwork every PIC program stands on.

---

## 5.7 Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| A low-voltage debugger cannot enter programming after an image was written with another tool | that image set `LVP = OFF` | recovery requires suitable HV entry; consider board limits and keep `LVP = ON` (§8.6.4) |
| Chip resets periodically on its own | watchdog left enabled and never serviced | set `WDTE = OFF` (§8.6.3) |
| `CONFIG` token rejected: "unknown/invalid setting" | value token doesn't match your DFP's spelling | consult the selected DFP's chipinfo page; MPLAB X can help identify the same setting/value pair |
| MCLR pin won't reset the chip / behaves oddly | assumed `MCLRE` controls it, but `LVP = 1` overrides it | with `LVP = ON`, MCLR is MCLR automatically; `MCLRE` is ignored (§8.6.2, §8.6.4) |
| Can't read program back after flashing | accidentally set `CP = 0` (protection *on*) | remember `1` = disabled; recover with a Bulk Erase (§8.6.5) |

(Appendix C decodes the exact assembler message wording.)

---

## 5.8 Try it yourself

1. **Audit the block yourself.** Open your selected DFP's `xc8/docs/pic_chipinfo.html`, follow the
   PIC16F17146 link, and compare every token with §5.4. If MPLAB X generates `#pragma config`
   output, compare the setting/value pairs but retain pic-as `CONFIG` syntax in the `.S` file.
2. **Predict a failure.** Without building, write down what you'd expect if you set
   `WDTE = ON` with a period of ~2 s and never petted the watchdog. Then try it on the
   simulator and confirm.
3. **Trace the polarity.** Look up `CP` in the data sheet (§8.6.5) and confirm from the bit
   table that a blank (all-ones) device is *not* code-protected. Explain in one sentence why
   erased-means-unlocked is a sensible design.

---

## 5.9 Reference bridge

- **Data sheet DS40002343F §8 "Device Configuration"** — the authoritative field-by-field
  reference for all five Configuration Words. You can now read every register table in it.
- **Embedded Engineers guide §3.2 / §4** — shows `CONFIG` blocks in context for other devices;
  compare their choices to ours.
- **User's Guide** — search for the `CONFIG` directive for its exact syntax and the
  `"NAME = VALUE"` string form.
- **Selected DFP `xc8/docs/pic_chipinfo.html`** — accepted PIC16F17146 setting/value tokens and
  PIC-AS examples; the data sheet remains authoritative for hardware meaning.
- **Exact-device errata DS80001009E** — revision-specific exceptions, including B0 Sleep wake-up.

**Next chapter:** with the chip configured and starting cleanly, we finally make it *do*
something. Chapter 6 introduces the working register `W`, literals, and file registers — how
data actually moves inside a PIC — building toward the first blink in Chapter 7.
