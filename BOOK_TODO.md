# Book improvement TODO

Audit date: 2026-07-13
Review method: `technical-book-documentation` skill, source inspection, existing technical audit, build metadata, PDF structure checks, outline inspection, and repository hygiene review.

The technical audit in [AUDIT_REPORT.md](AUDIT_REPORT.md) found no unresolved device-level error within its stated validation boundary. This list therefore focuses on the work needed to make the book maintainable, traceable, reproducible, legally clean, accessible, and publication-grade.

## Current pass status

Implemented locally in this pass: B2 source inventory, B3 documentation standard, B4 permissions inventory, M1 targeted first-use trademark corrections and exceptions, M2 chapter/appendix reference-key declarations, M3 reproducible verification, M4 validation-status labels, M6 generated-artifact hygiene, M7 terminology decision table, M8 device/version scope boxes, M9 expected-artifact documentation, M10 supported-environment matrix, N1 title harmonization, N2 reading/navigation map, N3 glossary navigation, N4 editorial lint, N5 PDF visual review record, and a repeatable `make pdf-check` release check. `make lint` and `make verify` pass with the documented XC8/DFP paths. The PDF was rebuilt and structurally checked with `qpdf`.

Still open: B1 tagged/accessibility PDF and legal/licensing review of adapted vendor-example structure. Direct quotation wording has been replaced with original paraphrases. `RELEASE_BLOCKERS.md` records the required completion paths; the current PDF is not being represented as PDF/UA-compliant.

## Priority definitions

- **Blocking:** do before calling the next edition professionally complete.
- **Major:** materially improves trust, reproducibility, legal safety, or reader success.
- **Minor:** consistency, navigation, polish, or maintainability improvement.
- **Enhancement:** worthwhile expansion after the publication baseline is complete.

## Blocking

### B1. Make the PDF accessible

- **Evidence:** `pdfinfo output/pdf/pic-assembly-from-scratch.pdf` reports `Tagged: no`.
- **Impact:** the PDF has no declared tagged reading structure for screen readers and assistive technology. The visual PDF review does not establish accessibility.
- **Work:** produce a tagged PDF with a correct document language, title, heading hierarchy, reading order, lists, tables, code blocks, link annotations, and meaningful alternative text for figures.
- **Verification:** run a PDF/UA checker, inspect the tag tree and reading order, test with a screen reader or accessibility viewer, and document the result. Do not claim PDF/UA or WCAG conformance without a real check.

### B2. Add a formal source-and-claims record to the repository — implemented locally

- **Evidence:** root `SOURCE_INVENTORY.md` now provides the maintained public inventory; the detailed retrieved source set remains local and is intentionally not part of the public source snapshot.
- **Impact:** readers and future maintainers cannot reproduce the evidence trail from a clean clone. Many chapter references say only `User's Guide §...` or `data sheet §...` without document number, revision, URL, or access date.
- **Work:** commit a maintained `SOURCE_INVENTORY.md` at a stable project path and add a claims matrix for high-risk facts: configuration words, register addresses, memory maps, instruction behavior, interrupt vectors, linker classes, tool options, and programming rules.
- **Verification:** every high-risk claim has `claim | target | version | source | section/table/figure | verified date | notes`; every chapter reference resolves to an inventory entry.

### B3. Establish and commit the project documentation standard — implemented locally

- **Evidence:** `DOCUMENTATION_STANDARD.md` now defines the project publication standard.
- **Impact:** future edits can reintroduce inconsistent terminology, citation scope, trademark usage, code assumptions, and release procedures.
- **Work:** create `DOCUMENTATION_STANDARD.md` covering audience, chapter template, terminology, device/version scope, citation format, code-example requirements, trademark/copyright rules, PDF checks, and release gates.
- **Verification:** review each chapter and appendix against the standard; record intentional exceptions.

### B4. Complete the third-party copyright and permissions inventory — inventory implemented locally

- **Evidence:** `PERMISSIONS_INVENTORY.md` now records original material, paraphrases, quotations, adapted examples, graphics, trademarks, and required release decisions. Legal clearance remains open for flagged material.
- **Impact:** attribution alone does not establish permission to reproduce text, tables, screenshots, diagrams, or substantial code.
- **Work:** inventory every copied or closely adapted passage, figure, table, screenshot, code fragment, and vendor product graphic. Record source, amount used, license/permission status, transformation, attribution, and removal/replacement plan.
- **Verification:** obtain permission where needed, replace risky material with original explanations/examples, or document a defensible license/fair-use decision reviewed by counsel when commercially important.

## Major

### M1. Apply trademark rules at the required first uses — targeted audit implemented locally

- **Evidence:** targeted first visible uses in chapter/appendix headings and introductions now carry appropriate symbols; code identifiers, exact part numbers, and quoted source text remain intentional exceptions. A legal/publication review should still compare the result with current Microchip standards.
- **Impact:** Microchip’s publication guidance calls for trademark identification at first occurrence in the table of contents, headlines, and text of bound documents.
- **Work:** mark first occurrences of `PIC®`, `MPLAB®`, `MPASM™`, and other applicable marks in the contents/headlines/text where required; use descriptors and avoid possessive/plural noun usage. Do not add symbols to assembler identifiers or device part-number syntax mechanically.
- **Verification:** run a first-use audit per chapter/appendix and compare against the current [Microchip Trademark Standards](https://ww1.microchip.com/downloads/aemDocuments/documents/legal/Microchip-Trademark-Standards.pdf).

### M2. Make every chapter reference bibliographically resolvable — implemented locally

- **Evidence:** every chapter and appendix now declares its applicable keys from `REFERENCES.md`; abbreviated section citations therefore resolve to exact document titles, revisions, and official locations.
- **Impact:** a reader cannot reliably determine which revision or exact device/tool version supports the claim.
- **Work:** add a compact “Sources used in this chapter” block or stable reference keys. Include organization, exact title, document number/revision, section/table/figure, publication/access date, and official URL or inventory key.
- **Verification:** no unresolved abbreviations such as `User's Guide`, `data sheet`, or `Emb Eng` remain without a declared reference key.

### M3. Add a reproducible verification target — implemented locally

- **Evidence:** `make verify` now assembles and links the documented canonical examples using explicit XC8 and DFP environment variables; generated outputs are ignored.
- **Impact:** a clean clone cannot reproduce the claimed assembly, link, map, listing, disassembly, or HEX checks through one documented command.
- **Work:** add `make verify` or an equivalent script that records XC8, DFP, target, flags, expected outputs, and pass/fail checks. Include a version manifest and clear instructions for obtaining proprietary/vendor dependencies.
- **Verification:** run the target from a clean checkout or controlled fixture and produce a concise machine-readable summary of all canonical examples.

### M4. Separate verified runtime claims from static validation — implemented locally

- **Evidence:** `VALIDATION_STATUS.md` now defines and applies source-, build-, simulator-, and hardware-validation labels, including the current no-hardware boundary.
- **Impact:** readers may interpret “blinks,” “runs in the simulator,” or timing statements as bench-verified when they were only source/build/artifact checked.
- **Work:** label each runtime claim as `hardware-tested`, `simulator-tested`, `build/link-tested`, or `source-verified`. Add a hardware test log and simulator session record when available.
- **Verification:** scan chapters 3, 7, 14, 15, 18, and 19 for runtime language and ensure every claim has a validation status.

### M5. Make the release snapshot and source snapshot one explicit version

- **Evidence:** the PDF is distributed through releases while the repository also contains the generated PDF; the release was created from the publishing branch before `main` was fast-forwarded.
- **Impact:** future readers may not know whether the release asset, tag, source tree, and PDF hash are identical.
- **Work:** establish a release procedure that tags the exact commit on `main`, records the PDF SHA-256 in release notes, and verifies that the release asset hash equals `output/pdf/pic-assembly-from-scratch.pdf` from that commit.
- **Verification:** for each release, record `commit`, `tag`, `PDF hash`, toolchain version, source inventory revision, and validation date.

### M6. Add generated-artifact and temporary-file hygiene — implemented locally

- **Evidence:** `.gitignore` now covers verification intermediates, `tmp/`, local tool caches, DFP packs, and downloaded Microchip reference PDFs.
- **Impact:** accidental `git add -A` can commit large binaries, stale verification output, or proprietary/reference material and make clean-state review unreliable.
- **Work:** expand `.gitignore` for verification outputs, `tmp/`, local tool caches, downloaded manuals, DFP packs, and generated intermediates. Keep only intentional source examples and explicitly documented reference inventories under version control.
- **Verification:** a clean source checkout has no generated artifacts after clone; `git status` is clean after the documented build/verify workflow or clearly shows only ignored output.

### M7. Add a terminology and notation reference — implemented locally

- **Evidence:** `DOCUMENTATION_STANDARD.md` now contains a preferred-form table, scope distinctions, and intentional code/prose exceptions; Appendix F remains the reader-facing glossary.
- **Impact:** beginners may not know which terms are product marks, core families, tools, directives, or generic concepts.
- **Work:** add a terminology table defining preferred spelling, capitalization, descriptor, pluralization, code formatting, and scope. Explicitly distinguish `PIC® microcontroller`, PIC core/family, `MPLAB® XC8` package, `pic-as` driver, assembler language, and `PSECT` directive.
- **Verification:** run a terminology search and resolve each non-code variant or document it as intentional.

### M8. Add a scope/version box to every device-specific chapter — implemented locally

- **Evidence:** technical chapters now carry a top-of-chapter scope and validation block naming device/core, XC8, DFP, and current validation boundary.
- **Impact:** readers can mistake PIC16F17146-specific rules for universal mid-range or PIC rules.
- **Work:** add a short metadata block to each technical chapter: target device/core, DFP, compiler/tool version, board, and whether examples are source/build/simulator/hardware validated.
- **Verification:** every chapter containing addresses, configuration values, register names, memory limits, interrupt behavior, or tool output has an explicit scope block.

### M9. Add expected artifacts to code procedures — implemented locally

- **Evidence:** `verify/README.md` now defines the expected `.map`, `.lst`, `.hex`, and `.elf` artifacts and `make verify` emits an ignored TSV manifest for each canonical example.
- **Impact:** readers can build an example without knowing whether the important memory-model or linker behavior actually occurred.
- **Work:** for each canonical example, document expected key addresses, symbols, map rows, instruction expansions, error messages, or watch values. Link each to the verification source/output.
- **Verification:** every runnable example has a command, expected result, and a way to inspect the result.

### M10. Add a supported-environment matrix — implemented locally

- **Evidence:** `README.md` now contains the supported environment matrix and validation boundary.
- **Impact:** readers cannot quickly tell what is current, optional, unsupported, or known to differ by operating system.
- **Work:** add a matrix for OS, IDE/editor, XC8 version, DFP revision, simulator, programmer/debugger, board, and validation status. Include the XC8 4.00 external-DFP requirement and simulator limitation.
- **Verification:** every procedure names the supported path and the expected variation for alternatives.

## Minor

### N1. Harmonize the title across project records — implemented locally

- **Evidence:** `README.md`, `BOOK_PLAN.md`, cover metadata, and PDF metadata now use the canonical title and subtitle.
- **Work:** choose the canonical title and update `BOOK_PLAN.md`, metadata, release notes, source inventory references, and any generated front matter.
- **Verification:** search the repository for the old title and classify every remaining occurrence as historical or update it.

### N2. Add navigation links between chapters and appendices — map implemented locally

- **Evidence:** `NAVIGATION.md` now provides stable repository links for the full reading order, appendices, and maintenance records; the PDF contents/bookmarks provide in-document navigation.
- **Work:** add stable Markdown/PDF links to the next chapter, previous chapter, relevant appendix, canonical source, and verification example where useful.
- **Verification:** check all links after PDF generation and test them in a PDF viewer.

### N3. Improve glossary navigation — implemented locally

- **Evidence:** Appendix F now has an alphabetical quick index and letter-level PDF/Markdown navigation while retaining the compact glossary entries.
- **Work:** sort entries consistently, add an alphabetical mini-TOC or index, expand ambiguous acronyms on first use, and link important entries to chapters.
- **Verification:** a reader can locate a term from the PDF contents or glossary navigation in one or two actions.

### N4. Add a project-level editorial lint pass — implemented locally

- **Evidence:** `tools/lint_book.sh` now checks balanced fences, unresolved work markers, Makefile source coverage, required publication records, and broken relative Markdown links.
- **Work:** add a lightweight lint script or Makefile target for these checks. Keep rules explicit and allow documented exceptions.
- **Verification:** `make lint` returns actionable errors and passes on the current source.

### N5. Review long prose and typography after semantic edits — implemented locally

- **Evidence:** `PDF_REVIEW.md` records structural checks and representative rendered pages after the latest semantic edits. Accessibility remains a separate open blocking item.
- **Work:** rerender the cover, contents, long code pages, table-heavy pages, chapter transitions, appendices, and final pages after every major content or style change.
- **Verification:** visual review records the page set and finds no clipping, bad hyphenation, overflow, unreadable code, or orphaned headings.

## Enhancements

### E1. Add a dedicated memory-model diagram set

Create original diagrams for Harvard program/data memory, bank selection, page selection, psects/classes, linear memory, PIC18 Access Bank, and the compiled stack. Each diagram should have a caption, scope, source citation, and alt text.

### E2. Add a troubleshooting decision tree

Build a one-page path from symptom to artifact: compile error → assembler diagnostic → linker fixup → map/listing → HEX/programming → hardware/simulator behavior. Cross-link it to Appendix C and Chapter 17.

### E3. Add solutions or instructor material

Provide checked solutions for the chapter exercises, expected map/listing snippets, and a lab/instructor guide without hiding answers in the learner-facing chapters.

### E4. Add a revision and errata process

Define how readers report issues, how device/tool updates are evaluated, how errata are versioned, and how a corrected PDF receives a new release and hash.

### E5. Add a physical hardware validation appendix

Record board revision, power supply, programmer/debugger, pin wiring, measured clock/timing, LED polarity, programming result, and test date for each hardware example.

## Recommended implementation order

1. B2–B4: evidence, standard, copyright/permissions.
2. B1: accessible PDF production path.
3. M1, M7, M8: legal terminology and scope consistency.
4. M3–M6: reproducible verification and clean repository workflow.
5. M9–M10: reader-facing verification and support boundaries.
6. N1–N5: editorial and navigation polish.
7. E1–E5: teaching and publication enhancements.
