# Ice40 config

# DEVICE := hx4k
# PACKAGE := tq144

DEVICE := hx8k
PACKAGE := ct256

# nextpnr can't manage to place and route the 800x600 and make timing.
# use icecube2 instead :( Running tb's at higher resolutions is fine,
# just not real bitstream generation.
VGA_MODE := "640_480_60"
# VGA_MODE := "800_600_60"

# VGA_MODE 1024_768 won't currently work because the pixel clock is too fast
# for the sram.
#VGA_MODE := "1024_768_60"

# Clock Frequency in MHZ
CLK_FREQ := 100

# Directories
TEST_DIR := test
LIB_DIR := lib
BUILD_DIR := .build
BITS_DIR := .build/$(DEVICE)-$(PACKAGE)

# Dirs
DIRS := $(filter-out $(TEST_DIR)/, $(wildcard */))
TOP_DIRS := $(filter-out $(TEST_DIR)/, $(DIRS))

# Top modules
TOP_MODULES := $(foreach dir,$(TOP_DIRS),$(wildcard $(dir)*_top.sv))

ifneq ($(DEVICE),hx8k)
  TOP_MODULES := $(filter-out %left_top.sv %both_top.sv, $(TOP_MODULES))
endif

# Test benches
TEST_BENCHES := $(basename $(notdir $(wildcard $(TEST_DIR)/*_tb.sv)))

# Files that have feature not supported by verible
VERIBLE_EXCLUDE := vga/vga_top.sv

# Source files
SRC := $(filter-out $(VERIBLE_EXCLUDE), $(foreach dir,$(DIRS),$(wildcard $(dir)*.sv)))
TB_LIB_SRC = $(filter-out test/%_tb.sv, $(wildcard $(TEST_DIR)/*.sv))
ALL_SRC = $(SRC) $(TB_LIB_SRC)

# Compiler and simulator
IVERILOG := iverilog -Wall -Wno-portbind -Wno-timescale -DSYNTH_YOSYS -DVGA_MODE_$(VGA_MODE) -DSIMULATOR -DTB_EXCLUDE_SLOW
VVP := vvp

# Linter
LINTER := verilator -DLINTING=1 -DSYNTH_YOSYS -DVGA_MODE_$(VGA_MODE) --lint-only --quiet -Wall --timing --Wno-WIDTHEXPAND --Wno-WIDTHTRUNC

# Formatter
#
# TODO: these config vars are loaded from .envrc, but we should load
# them from a common file here too.
FORMATTER := verible-verilog-format --inplace --tryfromenv="indentation_spaces,column_limit,wrap_spaces,try_wrap_long_lines,assignment_statement_alignment,case_items_alignment,class_member_variable_alignment,distribution_items_alignment,enum_assignment_statement_alignment,formal_parameters_alignment,formal_parameters_indentation,module_net_variable_alignment,named_parameter_alignment,named_port_alignment,port_declarations_alignment,port_declarations_indentation,struct_union_members_alignment,wrap_end_else_clauses"

# Synthesis
YOSYS := yosys
CELLS_SIM := $(shell yosys-config --datdir/ice40/cells_sim.v)

# PNR
NEXTPNR := nextpnr-ice40

# bin creation
ICEPACK := icepack

# programming
ICEPROG := iceprog

VCD_FILES := $(addprefix $(BUILD_DIR)/,$(addsuffix .vcd,$(TEST_BENCHES)))
.PHONY: quick_unit
quick_unit: $(VCD_FILES)

# Ensure build directory exists
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BITS_DIR):
	mkdir -p $(BITS_DIR)

$(PCF_DIR):
	mkdir -p $(PCF_DIR)

# Load previous deps
-include $(wildcard $(BUILD_DIR)/*.d)

##############################################################################
#
# Synthesis
#
##############################################################################
define YOSYS_CMD
read_verilog -I$(LIB_DIR) -I$(dir $(1)) $1;\
synth_ice40 -top $(notdir $(basename $(1))); \
write_json $$@
endef

define synth_rule
$(BUILD_DIR)/$(notdir $(basename $(1))).json: $(1) Makefile | $(BUILD_DIR)
	$(YOSYS) -DSYNTH_YOSYS -DVGA_MODE_$(VGA_MODE) -E $(BUILD_DIR)/$(notdir $(basename $(1))).dep -p '$(call YOSYS_CMD,$(1))'
	cat $(BUILD_DIR)/$(notdir $(basename $(1))).dep | tr ' ' '\n' | grep -v '^/' | tr '\n' ' ' | awk '{$$$$1=$$$$1":"; print}' > $(BUILD_DIR)/$(notdir $(basename $(1))).d
endef

$(foreach top,$(TOP_MODULES),$(eval $(call synth_rule,$(top))))

.PHONY: synth
synth: $(addprefix $(BUILD_DIR)/,$(addsuffix .json,$(notdir $(basename $(TOP_MODULES)))))

##############################################################################
#
# P&R
#
##############################################################################
PCF_DIR := ../constraints
PCF_FILE := $(PCF_DIR)/vanilla-ice40-$(DEVICE)-$(PACKAGE).pcf

$(PCF_FILE): ../scripts/pins.py | $(PCF_DIR)
	../scripts/pins.py $(DEVICE) > $(PCF_FILE)

define pnr_rule
$(BITS_DIR)/$(notdir $(basename $(1))).asc: $(BUILD_DIR)/$(notdir $(basename $(1))).json $(PCF_FILE) | $(BITS_DIR)
	$(NEXTPNR) --$(DEVICE) --package $(PACKAGE) --freq $(CLK_FREQ) --json $$< $(addprefix --pcf ,$(PCF_FILE)) --top $(notdir $(basename $(1))) --asc $$@ || (mv $$@ $$@.sav && echo failed: $$@)
endef

$(foreach top,$(TOP_MODULES),$(eval $(call pnr_rule,$(top))))

.PHONY: pnr
pnr: $(addprefix $(BITS_DIR)/,$(addsuffix .asc,$(notdir $(basename $(TOP_MODULES)))))

##############################################################################
#
# Bitstream
#
##############################################################################
define bitstream_rule
$(BITS_DIR)/$(notdir $(basename $(1))).bin: $(BITS_DIR)/$(notdir $(basename $(1))).asc
	$(ICEPACK) $$< $$@
endef

$(foreach top,$(TOP_MODULES),$(eval $(call bitstream_rule,$(top))))

.PHONY: bitstream
bitstream: $(addprefix $(BITS_DIR)/,$(addsuffix .bin,$(notdir $(basename $(TOP_MODULES)))))

.PHONY: bits
bits: bitstream

##############################################################################
#
# Programming
#
##############################################################################
# Rule to program a specific bitstream
define program_rule
.PHONY: program_$(notdir $(basename $(1)))
$(notdir $(basename $(1))): $(BITS_DIR)/$(notdir $(basename $(1))).bin
	$(ICEPROG) $$<
endef

$(foreach top,$(TOP_MODULES),$(eval $(call program_rule,$(top))))

.PHONY: list
list:
	@echo "Available unit test targets:"
	@$(foreach t,$(TEST_BENCHES),echo " $t";)
	@echo
	@echo "Available programming targets:"
	@$(foreach top,$(TOP_MODULES),echo " $(notdir $(basename $(top)))";)

##############################################################################
#
# Verification
#
##############################################################################
.PRECIOUS: $(BUILD_DIR)/%
$(BUILD_DIR)/%: $(TEST_DIR)/%.sv $(CELLS_SIM) Makefile | $(BUILD_DIR)
	$(IVERILOG) -g2012 -M $(@).dep $(foreach dir,$(DIRS), -I$(dir)) -I$(TEST_DIR)/ -o $@ $(filter-out Makefile,$^)
	@echo "$@: $$(tr '\n' ' ' < $(@).dep)" > $(@).d

$(BUILD_DIR)/%.vcd: $(BUILD_DIR)/%
	@$(VVP) $^ +SKIP_SLOW_TESTS=1

define run_test
	@$(VVP) $1 +SKIP_SLOW_TESTS=1 && echo "$1" >> $(BUILD_DIR)/tb_success.log || echo "make $(notdir $1)" >> $(BUILD_DIR)/tb_failure.log
endef

# General rule for running each test bench
.PHONY: $(TEST_BENCHES)
$(TEST_BENCHES): % : $(BUILD_DIR)/%
	@echo make $@
	$(call run_test,$<)

# Run all test benches sequentially and show summary
unit: clean_logs $(TEST_BENCHES)
	@echo "=============================="
	@echo "Successful tests: $$(wc -l < $(BUILD_DIR)/tb_success.log)"
	@echo "Failed tests: $$(wc -l < $(BUILD_DIR)/tb_failure.log)"
	@sed 's/^/    /' $(BUILD_DIR)/tb_failure.log
	@echo "=============================="

check: lint unit

##############################################################################
#
# Linting
#
##############################################################################
.PHONY: lint lint_% $(addprefix lint_, $(TEST_BENCHES))
lint: $(addprefix lint_, $(TEST_BENCHES))

LINT_CMD=$(LINTER) $(foreach dir,$(DIRS),-I$(dir)) -I$(TEST_DIR) $(TEST_DIR)/$(1).sv
define lint_rule
lint_$(1):
	@echo "make lint $1"
	@$(LINT_CMD) || (echo $(LINT_CMD); exit 1)
endef

$(foreach tb,$(TEST_BENCHES),$(eval $(call lint_rule,$(tb))))

##############################################################################
#
# Formatting
#
##############################################################################
.PHONY: format
format:
	$(FORMATTER) $(ALL_SRC) $(TEST_DIR)/*.sv

##############################################################################
#
# Cleaning
#
##############################################################################
clean:
	rm -rf $(BUILD_DIR)

clean_logs: $(BUILD_DIR)
	@rm -f $(BUILD_DIR)/tb_success.log $(BUILD_DIR)/tb_failure.log
	@touch $(BUILD_DIR)/tb_success.log $(BUILD_DIR)/tb_failure.log

.PHONY: all clean clean_logs check test $(addprefix run_, $(TEST_BENCHES))
