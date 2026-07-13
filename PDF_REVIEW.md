# PDF visual review record

Review date: 2026-07-13
Artifact: `output/pdf/pic-assembly-from-scratch.pdf`
Build: Pandoc + XeLaTeX, XC8 4.00 documentation baseline

## Structural checks

- `qpdf --check` passed.
- `pdfinfo` reports embedded metadata, 198 pages, and `Tagged: no`.
- PDF outline/bookmarks were inspected after the rebuild.
- `git diff --check` passed for the source changes.

## Rendered review set

| Area | Pages inspected | Result |
|---|---:|---|
| Cover and front matter | 1–3 | Title, subtitle, ownership notice, and contents are readable; no clipping observed |
| Chapter scope box | 33 | Scope text fits below the chapter heading; no overflow or collision |
| Code/table-heavy material | 44–46, 160 | Code remains legible; tables stay within margins |
| Glossary navigation | 184–185 | Quick index and letter headings render cleanly; entries remain readable |
| References | 191–198 | Source keys, links, and continuation pages render without clipping |
| Final page | 198 | No cutoff or orphaned heading observed |

## Open accessibility finding

The PDF is visually reviewable and structurally valid, but it is not tagged. No PDF/UA or WCAG
conformance claim is made. A future accessibility pass must add document language, tag structure,
reading order, link semantics, code-block treatment, and figure alternatives, then verify them with
an accessibility checker and assistive technology.

## Toolchain investigation

The installed TeX Live 2026 environment includes `tagpdf.sty` and
`pdfmanagement-testphase.sty`, but Pandoc's current generated template places the style include
after `\documentclass`. A test with `\DocumentMetadata{lang=en-US,pdfversion=2.0}` therefore fails
with the TeX requirement that `\DocumentMetadata` precede `\documentclass`. Producing a tagged
edition requires a custom Pandoc template or an equivalent pre-document integration, followed by
real tag-tree and assistive-technology checks. The current stable PDF was restored after this
negative test.

Enabling `tagging=on` in the generated template was also tested. The build fails at a Pandoc
`Shaded` code block with `Package tagpdf Error: there is no open structure on the stack`; this
confirms that code-block and other generated-environment handling must be designed as part of the
custom template/filter, not enabled by a single metadata switch.

No local PDF/UA post-processor or validator (`veraPDF`, `pdfcpu`, or equivalent) is installed;
available tools can check syntax and render pages but cannot create or certify a tag tree. The
remaining accessibility work therefore requires the custom-template route plus an external or
newly provisioned accessibility checker.

An isolated hook test that wrapped Pandoc's `Shaded` environment in a `Code` structure produced
the same unbalanced-structure error. This is not safe to integrate into the release build without
mapping all generated environments and validating the resulting tag tree.
