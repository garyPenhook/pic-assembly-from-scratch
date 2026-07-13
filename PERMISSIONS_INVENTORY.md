# Copyright and permissions inventory

Audit date: 2026-07-13. This register identifies material that may require attribution,
permission, license review, or replacement before publication. It is an editorial record, not
legal advice or a fair-use determination.

## Material categories

| Material | Locations | Treatment | Current status / action |
|---|---|---|---|
| Original explanatory prose | Chapters 1–19 and Appendices A–G | Project-authored; device facts cite official sources | No third-party permission identified; retain citations |
| Original assembly examples | `verify/*.S` and chapter listings | Project-authored and build-tested | No third-party permission identified; preserve source history |
| Vendor-derived syntax and behavior descriptions | All chapters; especially Chapters 3, 8, 10, 12, 16–19 and Appendices A–E | Paraphrase with source-key citations | Review for substantial similarity; rewrite any passage too close to source wording |
| Short quoted or near-quoted wording | Previously identified in `CH06_moving_data.md` and `CH16_compiled_stack.md` | Replaced with original paraphrases while retaining source keys | Recheck diffs; no direct quotation is intended to remain |
| Adapted vendor examples | `CH16_compiled_stack.md`, `CH19_baseline.md`, and related exercises | Concepts/structure adapted from `[EE]` | Confirm license/permission and document transformations; prefer independent rewrites |
| Vendor figures, screenshots, and diagrams | None identified in current source | Original Markdown tables and prose diagrams | Recheck before adding artwork; obtain permission or create original artwork |
| Microchip logos and product graphics | None | Text trademarks only; independence notice included | Do not add logos without written permission |
| External fonts and software | PDF fonts; Pandoc/XeLaTeX build | Toolchain dependencies, not book content | Record package/license versions in release environment |

## Required release decision

Before a commercial or otherwise public release, each flagged reproduction must be covered by
written permission/license, replaced with original material, or supported by a documented fair-use
or other legal basis after appropriate legal review. Attribution alone does not grant permission.

## Review protocol

For each changed chapter, compare new prose and code against the cited source, record the source
section and transformation, and update this register. Do not reproduce vendor screenshots, logos,
large tables, or long passages without a documented right to do so.
