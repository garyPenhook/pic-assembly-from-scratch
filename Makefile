PANDOC ?= pandoc
PDF := output/pdf/pic-assembly-from-scratch.pdf

CHAPTERS := \
	manuscript/part1.md manuscript/CH01_what_is_a_microcontroller.md manuscript/CH02_pic_cores.md manuscript/CH03_toolchain.md \
	manuscript/part2.md manuscript/CH04_anatomy.md manuscript/CH05_config.md manuscript/CH06_moving_data.md manuscript/CH07_first_blink.md \
	manuscript/part3.md manuscript/CH08_banking.md manuscript/CH09_paging.md manuscript/CH10_psects.md manuscript/CH11_linear_memory.md \
	manuscript/part4.md manuscript/CH12_directives.md manuscript/CH13_macros_multifile.md manuscript/CH14_interrupts.md \
	manuscript/CH15_pic18_interrupts.md manuscript/CH16_compiled_stack.md \
	manuscript/part5.md manuscript/CH17_linker_map.md manuscript/CH18_hex_programming.md manuscript/CH19_baseline.md


APPENDICES := \
	manuscript/NAVIGATION.md \
	manuscript/APPENDIX_A_instruction_set.md manuscript/APPENDIX_B_directive_reference.md \
	manuscript/APPENDIX_C_error_messages.md manuscript/APPENDIX_D_options.md \
	manuscript/APPENDIX_E_mpasm_migration.md manuscript/APPENDIX_F_glossary.md \
	manuscript/APPENDIX_G_assembly_to_c.md manuscript/REFERENCES.md

SOURCES := $(CHAPTERS) $(APPENDICES)

.PHONY: all pdf pdf-check lint verify clean
all: pdf

pdf: $(PDF)

pdf-check: $(PDF)
	bash tools/check_pdf.sh

$(PDF): $(SOURCES) book/metadata.yaml book/style.tex book/cover.tex
	mkdir -p output/pdf tmp/pdfs
	$(PANDOC) --metadata-file=book/metadata.yaml --from=markdown+smart \
		--pdf-engine=xelatex --toc --syntax-highlighting=tango \
		--top-level-division=chapter --output=$@ $(SOURCES)

lint:
	bash tools/lint_book.sh

verify:
	bash tools/verify_examples.sh

clean:
	rm -rf tmp/pdfs
	rm -f $(PDF)
