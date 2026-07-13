---
name: technical-book-documentation
description: Develop, audit, and publish professional technical books and manuals. Use for chapter planning, source-backed technical claims, terminology and style consistency, citations, trademark/copyright notices, accessibility, PDF production, release review, or documentation-quality audits.
---

# Technical Book Documentation

Use this skill when creating or reviewing a technical book, hardware/software guide, reference manual, tutorial, or rendered PDF. It combines technical-source control, information architecture, editorial style, legal attribution hygiene, reproducible examples, and publication validation.

## Governing principles

1. Technical correctness comes from the narrowest authoritative source, not memory or a secondary tutorial.
2. Every important claim must be traceable to a source revision, section/table/figure, and applicable device or tool version.
3. Explain concepts progressively: purpose, model, worked example, failure mode, verification exercise, and reference bridge.
4. Treat the source Markdown, generated PDF, examples, and release asset as one versioned publication.
5. Never imply vendor affiliation, endorsement, certification, or sponsorship without written permission.
6. Validate rendered layout; text extraction and a successful build are not enough.

## Authority hierarchy

For hardware/toolchain books, use this order:

1. Exact device data sheet and silicon errata.
2. Exact device-family programming specification and hardware-board guide.
3. Exact compiler, assembler, linker, utility, IDE, and debugger user guides.
4. Exact Device Family Pack headers, chipinfo/configuration data, and release notes.
5. Official vendor developer help and product pages.
6. Standards, textbooks, application notes, and reputable secondary sources.
7. Personal inference, which must be labeled as inference and never presented as a vendor rule.

When sources conflict, prefer the newer source only when it covers the same device/tool/version; otherwise state the scope difference. Record the decision in a source inventory.

## Required project records

Maintain these artifacts when the project is large enough to need them:

- `SOURCE_INVENTORY.md`: source filename, revision/date, authority, URL, and claims supported.
- `DOCUMENTATION_STANDARD.md`: project-specific writing, terminology, citation, code, trademark, and release rules.
- A claims matrix or audit report for device-specific facts, configuration values, addresses, instruction behavior, and tool options.
- A reproducible build target such as `make pdf`, with pinned input order and visible tool versions.

For each high-risk claim, record:

```text
claim | device/core | tool/version | source | section/table/figure | verified date | notes
```

## Information architecture

Before writing, define the audience, prerequisites, learning outcomes, supported devices/tools, and completion criteria. Organize each chapter around a user task or concept rather than a source document's table of contents.

Use this chapter pattern where appropriate:

1. What the reader will build or understand.
2. Mental model and terminology.
3. Minimal working example.
4. Line-by-line or field-by-field explanation.
5. Build/run/simulate/program procedure.
6. What can fail and how to recognize it.
7. Verification exercise.
8. Common mistakes and recovery.
9. Reference bridge to authoritative documentation.

Separate conceptual rules from device-specific exceptions. State scope explicitly: core, exact part, toolchain release, DFP revision, operating system, and hardware board.

## Editorial style

Use one project style sheet and apply it consistently. A good baseline is the [Google Developer Documentation Style Guide](https://developers.google.com/style), supplemented by the [Microsoft Writing Style Guide](https://learn.microsoft.com/en-us/style-guide/welcome/) for technical terminology and procedures. Use Chicago or another declared general-prose style only for questions not covered by the project style sheet.

Default editorial rules:

- Write for the reader's task; put the result and prerequisite near the start.
- Prefer short, direct sentences and concrete verbs.
- Define a term at first use; use the same term thereafter.
- Distinguish instructions, observations, warnings, notes, and examples visually.
- Use imperative steps for procedures and present tense for system behavior.
- Identify units, address bases, word/byte widths, endianness, and indexing conventions.
- Use code formatting for identifiers, commands, filenames, registers, directives, and literal values.
- Keep examples complete enough to reproduce; show required includes, configuration, linker options, device selection, and expected output.
- Do not hide uncertainty. Mark assumptions, version dependence, incomplete coverage, and inferred behavior.

Maintain a terminology table with preferred spelling, forbidden variants, capitalization, pluralization, and first-use definition. Include product names, instruction mnemonics, register names, acronyms, units, and cross-core terms.

## Citations and references

Use [ISO 690:2021](https://www.iso.org/standard/72642.html) as the citation model unless a publisher or institution requires another style. Technical references should include:

- author or organization;
- exact title;
- document number and revision;
- publication or access date;
- section/table/figure/page;
- stable official URL or local source filename;
- the device/tool/version to which the evidence applies.

Do not cite a broad family guide for an exact-device claim when the exact data sheet or DFP is available. Do not silently retain stale links or revision letters. Re-audit volatile toolchain and web references before release.

## Trademarks, copyright, and independence

Follow the owner’s current rules. For Microchip material, use [Microchip’s Trademark Standards](https://ww1.microchip.com/downloads/aemDocuments/documents/legal/Microchip-Trademark-Standards.pdf) and its [trademark guidelines](https://www.microchip.com/en-us/about/legal-information/microchip-trademarks).

For each third-party mark used in a book:

- use the correct `®`, `™`, or service-mark symbol at the prominent first use required by the owner’s guide;
- use the mark as an adjective with a descriptor, not as a noun, verb, possessive, or plural;
- include an ownership attribution in the credit/legal notice;
- include an independent-publication/non-affiliation disclaimer when the work could be mistaken for vendor material;
- do not use vendor logos, trade dress, or marks in a title/product name in a way that suggests sponsorship.

For copied text, figures, screenshots, tables, and code, preserve license and attribution information. Do not assume that technical facts, a citation, or educational intent makes a copied graphic or manual page reusable. Use the [U.S. Copyright Office circulars](https://copyright.gov/circs/) and [Fair Use Index](https://copyright.gov/fair-use/) as starting points; obtain permission or legal review when the use is material, commercial, or uncertain.

## Technical-example quality

Every code example must identify its target and assumptions. Check:

- exact device/core and DFP;
- compiler/assembler/linker/utility version;
- required flags and paths;
- reset/configuration and clock assumptions;
- memory placement, bank/page behavior, and calling convention;
- expected map/list/HEX output where relevant;
- simulator or hardware setup;
- known electrical and safety limits.

Build examples independently where practical. Keep generated `.hex`, `.map`, `.lst`, object, and temporary files out of the source commit unless they are intentional teaching artifacts.

## PDF production and accessibility

Use the project-native build system. Before release:

1. Build from a clean or known source state.
2. Check metadata, page count, page size, bookmarks, links, and embedded fonts.
3. Run `qpdf --check` and extract text with `pdftotext` as structural checks.
4. Render the cover, contents, representative prose, code/table-heavy pages, and final pages.
5. Inspect for clipping, overlap, bad page breaks, broken tables, unreadable code, missing glyphs, and inconsistent headers/footers.
6. Check reading order, heading hierarchy, contrast, alt text, and tagged structure when accessibility is required.

Use [PDF/UA guidance](https://pdfa.org/accessibility) for accessible PDF structure and [WCAG 2.2](https://www.w3.org/TR/WCAG22/) for broader accessibility principles. Do not claim PDF/UA or WCAG conformance unless it has actually been tested.

## Release checklist

- [ ] Scope, audience, prerequisites, and supported versions are stated.
- [ ] Source inventory and claims audit are current.
- [ ] All examples build or their expected failure is documented.
- [ ] Device-specific claims are checked against the exact data sheet/errata/DFP.
- [ ] Volatile toolchain behavior is checked against current release notes.
- [ ] Terminology, headings, cross-references, units, and code formatting are consistent.
- [ ] Citations identify revisions and precise locations.
- [ ] Trademark symbols, descriptors, attribution, and independence disclaimer are correct.
- [ ] Third-party copyright/license status is recorded.
- [ ] PDF structure, metadata, fonts, links, and rendering pass review.
- [ ] The release PDF hash matches the locally validated artifact.
- [ ] Commit, tag, release notes, and source snapshot identify the same publication version.

## Review output

When auditing a book, report findings by severity:

- **Blocking:** technically wrong, unsafe, legally unlicensed, unreproducible, or materially misleading.
- **Major:** missing scope/version, unsupported claim, broken example, missing citation, or significant layout/accessibility defect.
- **Minor:** wording, consistency, typography, or navigation issue that does not change meaning.

Each finding should include location, evidence, impact, recommended correction, and verification method. Distinguish confirmed defects from suggestions and from issues requiring legal or vendor clarification.
