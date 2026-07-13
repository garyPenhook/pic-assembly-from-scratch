# Release blockers

Status date: 2026-07-13. These are the remaining gates before the book can be described as fully
publication-ready.

## Accessibility — open

The stable PDF is visually reviewed and structurally valid, but `pdfinfo` reports `Tagged: no`.
Attempts to enable TeX Live's `tagpdf` through a generated Pandoc template fail in Pandoc-
generated environments, including `Shaded` and plain code-block output, with an unbalanced
structure-stack error. The current build must not claim PDF/UA or WCAG conformance.

Tested alternatives include modern `tagpdf` with XeLaTeX/LuaLaTeX and the legacy `accessibility`
package with pdfLaTeX. They either produce `Tagged: no`, fail on Pandoc-generated environments, or
exhaust TeX's input stack. They are not integrated into the release artifact.

Required completion path:

1. Create a custom Pandoc LaTeX template that initializes `\DocumentMetadata` before
   `\documentclass`.
2. Add tested tag mappings for headings, paragraphs, lists, tables, links, code blocks, and the
   cover/front matter; add meaningful alternatives for any figures.
3. Build with tagging enabled and inspect the tag tree and reading order.
4. Run a real PDF/UA checker and an assistive-technology review, recording tool versions and
   findings.

## Copyright and licensing — legal review open

The project now contains a permissions inventory and direct vendor-style quotations identified in
the audit have been rewritten as original paraphrases. The remaining risk is the structure and
adaptation of examples informed by Microchip's instructional material, particularly the compiled-
stack and baseline examples.

Required completion path:

1. Compare each adapted example against its cited source and record the transformation in
   `PERMISSIONS_INVENTORY.md`.
2. Obtain written permission/license, replace the example with independently designed material,
   or obtain appropriate legal review of a fair-use/other legal basis.
3. Record the decision and reviewer/date before declaring the release cleared.

Attribution and Microchip trademark compliance do not by themselves grant copyright permission.
