# Chapter 3 — Installing the Toolchain

> **Reference keys:** `[UG]`, `[EE]`, `[RN400]`, `[DFP17146]`, `[MPLABX]`, and `[CUG]` in `REFERENCES.md`.

> **What you'll build:** a working development setup — **VS Code** with the **MPLAB® Extension
> Pack**, the **MPLAB® XC8** assembler, and the **Device Family Pack** for the PIC16F17146 — and an
> empty project that *builds cleanly*. No hardware required: you'll run it on the **simulator** via
> the MPLAB® Debugger. By the end you have a green build and are ready to write real code in Part II.

> **Which tools?** Microchip now delivers its 8-bit workflow as **MPLAB® Extensions for Visual
> Studio Code** (its modern, recommended path), alongside the older **MPLAB® X IDE**. This book uses
> the **VS Code** workflow for the GUI steps and a **command-line `pic-as`** invocation for every
> code listing (so each example is exactly reproducible in any terminal). If you prefer MPLAB X IDE,
> a short mapping is in §3.8 — the concepts are identical.

---

## 3.1 The pieces you need

Four things turn your typing into a program on a chip:

1. **Visual Studio Code** — the editor. Free from
   [code.visualstudio.com/download](https://code.visualstudio.com/download).
2. **The MPLAB Extension Pack** — Microchip's suite of VS Code extensions (project wizard, CMake
   build, the **MPLAB Debugger** debug adapter, toolchain manager, Hexmate, MCC). Install it from
   the VS Code **Marketplace**: open Extensions (**Ctrl+Shift+X**), search *MPLAB Extension Pack*,
   and install (verified: Microchip developerhelp, "Get Started for MPLAB X IDE Users New to VS
   Code").
3. **MPLAB® XC8** — the compiler package that includes the **PIC® assembler**, whose command-line
   driver is **`pic-as`** (User's Guide §3). This is the tool that turns your `.S` files into a HEX
   file; the extensions call it for you.
4. **The Device Family Pack (DFP)** — a package that teaches the tools your specific chip's
   registers, config bits, and memory. The assembler's device info "typically comes from your
   selected Device Family Pack" (User's Guide §2.1). You need the pack covering the PIC16F17146
   (the `PIC16F1xxxx_DFP`).

The commands and UI names here were verified with the **MPLAB Extension Pack** (extensions
`mplab-core-da`, `runcmake`, `toolchains`), **MPLAB XC8 4.00**, and **PIC16F1xxxx_DFP 1.31.465**.
Record the XC8 and DFP versions you actually select — later versions can move a control or change a
config-token spelling (Chapter 5).

---

## 3.2 The tool you *don't* need yet: hardware

You can write, build, and run this book's early chapters **without buying any hardware**, because
the MPLAB Debugger includes a **simulator** — a software model of the chip. It lets you single-step
instructions, watch registers change, and confirm your logic, all on your PC (User's Guide §2.2
lists the simulator among the compatible tools).

The simulator proves CPU state and the peripherals it models; it does **not** prove board wiring,
voltage levels, oscillator tolerance, or LED current. Treat a simulator pass as a *logic* check and
do a hardware check before making electrical or timing claims.

When you *are* ready for real silicon, the tools work with all Microchip programmers and boards —
including the **PIC16F17146 Curiosity Nano**, whose on-board debugger programs the chip over USB
with no separate programmer (Curiosity Nano guide §3.1).

**This book's approach: simulator-first.** Every example runs on the simulator; the Curiosity Nano
is an optional "run it on hardware" step (Chapter 18).

---

## 3.3 Creating your first project

VS Code drives everything through the **Command Palette** — press **Ctrl+Shift+P** (a fast shortcut
is typing **`>`** in the search bar). Every MPLAB command starts with `MPLAB:`. To make a project
(verified: developerhelp "Workflow for MPLAB Extensions for VS Code"):

1. Run **`MPLAB: Create New Project`** and follow the wizard.
2. **Device:** enter `PIC16F17146` and select it. (If it's not offered, install its DFP — the
   extension's pack manager fetches it.)
3. **Toolchain:** choose the **XC8 (pic-as)** assembler toolchain — we're writing assembly, not C.
4. Name the project and finish.

You now have a project folder targeting the PIC16F17146, ready for source files. (Already have an
MPLAB X IDE project? Just **File → Open Folder** on it and accept the import suggestion.)

---

## 3.4 A minimal source file that builds

Add a source file named with an uppercase **`.S`** (the uppercase matters — Chapter 4 explains why)
and put in the smallest thing that assembles — the idle loop you'll dissect next chapter:

```asm
    PROCESSOR 16F17146
#include <xc.inc>

    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    $               ; loop here forever

    END     resetVec
```

---

## 3.5 Build it

In VS Code, build with **Ctrl+Shift+B**, or run **`MPLAB CMake: Full Build`** from the Command
Palette, or click the **Hammer** in the status bar (verified: developerhelp workflow page — the
extensions drive the build through CMake). A successful build produces the object, ELF, and HEX
files in the project's build output.

> **Command-line equivalent (used for every listing in this book).** So each example is
> reproducible in any terminal, the book gives the raw `pic-as` command:
> ```
> DFP=/path/to/Microchip/PIC16F1xxxx_DFP/1.31.465/xc8
> pic-as -mcpu=16f17146 -mdfp="$DFP" -Wl,-presetVec=0h spin.S
> ```
> **XC8 4.00 note:** a command-line build needs **`-mdfp=<DFP-xc8-directory>`** — point it at the
> pack's `xc8` subdirectory (not the pack root), or the driver reports "no device-support files"
> (errors 2103/2104). **VS Code and MPLAB X supply this automatically.** The `pic-as` binary lives
> under your XC8 install (e.g. `…/xc8/vN.NN/pic-as/bin/pic-as`); the DFP lives under the MPLAB
> `packs` directory or your `~/.mchp_packs`. Later chapters assume the `DFP` variable above is set.

---

## 3.6 Run it on the simulator

Now step it in the simulator via the **MPLAB Debugger** (verified: developerhelp workflow page):

1. Run **`Debug: Add Configuration`** and choose **MPLAB Debugger** — this creates a debug
   configuration (a `launch.json`) that defaults to the simulator when no board is connected.
2. Press **F5** (or use the **Run and Debug** view) to start the session. Execution stops at the
   program's start.
3. **Step** one instruction (**F10**): you land on `goto $`. Step again — the Program Counter
   doesn't move. That frozen PC is your idle loop working.

Use the **Run and Debug** view's **Variables**/**Watch** panels to watch `W` (as `WREG`),
registers, and memory change as you step. These are the panels you'll live in for the next several
chapters. You've closed the loop: **write → build → simulate**, no hardware, no risk.

---

## 3.7 What just happened

You installed the modern toolchain — **VS Code + the MPLAB Extension Pack**, the **XC8/`pic-as`
assembler**, and the **PIC16F17146 DFP** — created an assembly project, built a minimal source file,
and stepped it on the **simulator** with the MPLAB Debugger. You confirmed the whole pipeline works
before writing a single "real" line. That's the professional order of operations: get a trivial
thing building and running first, *then* add complexity.

---

## 3.8 If you use MPLAB X IDE instead

The older MPLAB X IDE does the same jobs; the command names differ (both paths are supported by
Microchip):

| Task | VS Code + MPLAB Extensions | MPLAB X IDE |
|---|---|---|
| New project | `MPLAB: Create New Project` (Ctrl+Shift+P) | **File → New Project → Standalone** |
| Pick device | in the wizard: `PIC16F17146` | wizard: device `PIC16F17146` |
| Toolchain | XC8 (pic-as) | pic-as toolchain (not the C compiler) |
| Build | **Ctrl+Shift+B** / `MPLAB CMake: Full Build` | the **Hammer** (Build) button |
| Simulate/debug | `Debug: Add Configuration` → MPLAB Debugger, **F5** | set Tool = **Simulator**, press **Debug** |
| Watch registers | Run and Debug → Variables/Watch | Window → Debugging → Watches |

Everything else in this book — the assembly, the `pic-as` command lines, the map/HEX files — is
identical either way.

---

## 3.9 Common problems

| Symptom | Cause | Fix |
|---|---|---|
| No `MPLAB:` commands in the palette | Extension Pack not installed/enabled | install *MPLAB Extension Pack* (Ctrl+Shift+X) and reload VS Code |
| `PIC16F17146` not offered | its DFP isn't installed | let the extension's pack manager fetch the `PIC16F1xxxx_DFP` |
| Build produces C, not assembly | picked the C toolchain | choose the **XC8 (pic-as)** assembler toolchain |
| `#include <xc.inc>` not found | file saved as lowercase `.s` (no preprocessing) | use an uppercase **`.S`** extension (Chapter 4) |
| Terminal build: error 2103/2104 | XC8 4.00 not given its DFP | pass `-mdfp="$DFP"` pointing at the pack's `xc8` directory |
| Debug session won't start | no debug configuration, or backend not ready | run `Debug: Add Configuration` → **MPLAB Debugger** first; ensure the MPLAB platform backend finished installing |

---

## 3.10 Try it yourself

1. **Green light.** Get §3.4's file to build successfully — in VS Code (**Ctrl+Shift+B**) *and* from
   the terminal with the `pic-as` command. This working toolchain is the milestone everything else
   builds on.
2. **Step the loop.** Start the MPLAB Debugger (**F5**), step three times, and watch the Program
   Counter freeze on `goto $`. Explain what you're seeing.
3. **Find the versions.** Note your XC8 version and DFP version (the Command Palette's `MPLAB: Edit
   Project Properties` shows them). You'll need the DFP version in Chapter 5.

---

## 3.11 Reference bridge

- **Microchip developerhelp — "Workflow for MPLAB Extensions for VS Code"** and **"Get Started for
  MPLAB X IDE Users New to VS Code"** — the authoritative command list (create/build/debug) this
  chapter follows.
- **User's Guide §2.2 / §3.5** — compatible tools, and how project properties map to `pic-as`
  options.
- **XC8 4.00 Release Notes** — the installed tool version and the command-line DFP requirement.
- **Curiosity Nano guide §3.1** — the on-board debugger, for when you move to hardware (Chapter 18).

**Next chapter — and Part II:** your tools work. Chapter 4 dissects that minimal source file line by
line — statements, labels, directives, the reset vector, and the `goto $` idle loop — so every
character means something. From here on, you write real code.
