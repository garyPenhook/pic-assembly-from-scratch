PANDOC ?= pandoc
PDF := output/pdf/pic-assembly-from-scratch.pdf

CHAPTERS := \
	book/part1.md CH01_what_is_a_microcontroller.md CH02_pic_cores.md CH03_toolchain.md \
	book/part2.md CH04_anatomy.md CH05_config.md CH06_moving_data.md CH07_first_blink.md \
	book/part3.md CH08_banking.md CH09_paging.md CH10_psects.md CH11_linear_memory.md \
	book/part4.md CH12_directives.md CH13_macros_multifile.md CH14_interrupts.md \
	CH15_pic18_interrupts.md CH16_compiled_stack.md \
	book/part5.md CH17_linker_map.md CH18_hex_programming.md CH19_baseline.md

APPENDICES := \
	APPENDIX_A_instruction_set.md APPENDIX_B_directive_reference.md \
	APPENDIX_C_error_messages.md APPENDIX_D_options.md \
	APPENDIX_E_mpasm_migration.md APPENDIX_F_glossary.md \
	APPENDIX_G_assembly_to_c.md

SOURCES := $(CHAPTERS) $(APPENDICES)

.PHONY: all pdf clean
all: pdf

pdf: $(PDF)

$(PDF): $(SOURCES) book/metadata.yaml book/style.tex book/cover.tex
	mkdir -p output/pdf tmp/pdfs
	$(PANDOC) --metadata-file=book/metadata.yaml --from=markdown+smart \
		--pdf-engine=xelatex --toc --syntax-highlighting=tango \
		--top-level-division=chapter --output=$@ $(SOURCES)

clean:
	rm -rf tmp/pdfs
	rm -f $(PDF)
