# Ice40 config

# DEVICE := hx4k
# PACKAGE := tq144

DEVICE := hx8k
PACKAGE := ct256

VGA_MODE := "640_480_60"
# VGA_MODE := "800_600_60"
# VGA_MODE := "1024_768_60"

# Clock Frequency in MHZ
CLK_FREQ := 100

# These are files that we can't build with yosys/nextpnr and need icecube2.
# nextprn just can't meet timing.
TOP_IGNORE := adc/%.sv

# these require both sides of the IO
HX8K_ONLY := gfx/gfx_demo_dbuf_top.sv adc/%.sv

# Directories
TEST_DIR := test
LIB_DIR := lib
BUILD_DIR := .build
BITS_DIR := .build/$(DEVICE)-$(PACKAGE)

# Dirs
DIRS := $(filter-out $(TEST_DIR)/, $(wildcard */))
TOP_DIRS := $(filter-out $(TEST_DIR)/, $(DIRS))

# Top modules
TOP_MODULES_ALL := $(foreach dir,$(TOP_DIRS),$(wildcard $(dir)*_top.sv))
TOP_MODULES := $(filter-out $(TOP_IGNORE), $(TOP_MODULES_ALL))

ifneq ($(DEVICE),hx8k)
  TOP_MODULES := $(filter-out $(HX8K_ONLY), $(TOP_MODULES))
endif

SEED_LOCK := $(BUILD_DIR)/.seed_lock

# Test benches
TEST_BENCHES := $(basename $(notdir $(wildcard $(TEST_DIR)/*_tb.sv)))

# Files that have feature not supported by verible
VERIBLE_EXCLUDE := vga/vga_top.sv

# Source files
SRC := $(filter-out $(VERIBLE_EXCLUDE), $(foreach dir,$(DIRS),$(wildcard $(dir)*.sv)))
TB_LIB_SRC = $(filter-out test/%_tb.sv, $(wildcard $(TEST_DIR)/*.sv))
ALL_SRC = $(SRC) $(TB_LIB_SRC)

# Compiler and simulator
IVERILOG := iverilog -Wall -Wno-portbind -Wno-timescale -DSYNTH_YOSYS -DVGA_MODE_$(VGA_MODE) -DSIMULATOR
VVP := vvp

# Linter
LINTER := verilator -DLINTING=1 -DSYNTH_YOSYS -DVGA_MODE_$(VGA_MODE) --lint-only --quiet -Wall --Wno-PINCONNECTEMPTY --timing

# Add top module names (without directory prefix and .sv suffix)
TOP_MODULE_NAMES := $(notdir $(basename $(TOP_MODULES)))
TOP_MODULE_NAMES_ALL := $(notdir $(basename $(TOP_MODULES_ALL)))

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
quick_unit: SKIP_SLOW_TESTS := 1
quick_unit: $(VCD_FILES)

# Ensure build directory exists
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
	touch $(SEED_LOCK)


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
read_verilog -sv -I$(LIB_DIR) -I$(dir $(1)) $1;\
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

define nextpnr_cmd
$(NEXTPNR) --$(DEVICE) --package $(PACKAGE) --freq $(CLK_FREQ) \
	--json $(BUILD_DIR)/$(notdir $(basename $(1))).json $(addprefix --pcf ,$(PCF_FILE)) \
	--top $(notdir $(basename $(1))) \
	--asc $(BITS_DIR)/$(notdir $(basename $(1))).asc
endef

# Find seed dependencies

define find_seed_rule
$(BITS_DIR)/$(notdir $(basename $(1))).seed: $(BUILD_DIR)/$(notdir $(basename $(1))).json $(PCF_FILE) | $(BUILD_DIR)
	@flock -w 30 $(SEED_LOCK) ../scripts/find_seed.py -o $(BITS_DIR)/$(notdir $(basename $(1))).seed $(call nextpnr_cmd,$(1))
endef

$(foreach top,$(TOP_MODULES),$(eval $(call find_seed_rule,$(top))))

# The seed finding script is already self-parallelized.
.PHONY: find_seeds
find_seeds: $(addprefix $(BUILD_DIR)/,$(addsuffix .seed,$(notdir $(basename $(TOP_MODULES)))))

# print the command on failure so that it's easy to copy/paste for a manual run
# PNR rule using found seeds
define pnr_rule
$(BITS_DIR)/$(notdir $(basename $(1))).asc: $(BUILD_DIR)/$(notdir $(basename $(1))).json $(PCF_FILE) $(BITS_DIR)/$(notdir $(basename $(1))).seed | $(BITS_DIR)
	$(eval PNR_CMD := $(call nextpnr_cmd,$(1)) --seed `cat $(BITS_DIR)/$(notdir $(basename $(1))).seed`)
	$(PNR_CMD) || { echo -e "FAILED:\n$(PNR_CMD)"; false; }
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
	@$(VVP) $^ +SKIP_SLOW_TESTS=$(SKIP_SLOW_TESTS)

define run_test
	@$(VVP) $1 +SKIP_SLOW_TESTS=$(SKIP_SLOW_TESTS) && echo "$1" >> $(BUILD_DIR)/tb_success.log || echo "make $(notdir $1)" >> $(BUILD_DIR)/tb_failure.log
endef

# General rule for running each test bench
.PHONY: $(TEST_BENCHES)
$(TEST_BENCHES): % : $(BUILD_DIR)/%
	@echo make $@
	$(call run_test,$<)

# Run all test benches sequentially and show summary
unit: SKIP_SLOW_TESTS := 1
unit: clean_logs $(TEST_BENCHES)
	@echo "=============================="
	@echo "Successful tests: $$(wc -l < $(BUILD_DIR)/tb_success.log)"
	@echo "Failed tests: $$(wc -l < $(BUILD_DIR)/tb_failure.log)"
	@sed 's/^/    /' $(BUILD_DIR)/tb_failure.log
	@echo "=============================="

unit_slow: SKIP_SLOW_TESTS := 0
unit_slow: clean_logs $(TEST_BENCHES)
	@echo "=============================="
	@echo "Successful tests: $$(wc -l < $(BUILD_DIR)/tb_success.log)"
	@echo "Failed tests: $$(wc -l < $(BUILD_DIR)/tb_failure.log)"
	@sed 's/^/    /' $(BUILD_DIR)/tb_failure.log
	@echo "=============================="

check: lint unit

check_slow: lint unit_slow

##############################################################################
#
# Linting
#
##############################################################################
.PHONY: lint lint_% $(addprefix lint_, $(TEST_BENCHES)) $(addprefix lint_, $(TOP_MODULE_NAMES_ALL))
lint: $(addprefix lint_, $(TEST_BENCHES)) $(addprefix lint_, $(TOP_MODULE_NAMES_ALL))

LINT_TB_CMD=$(LINTER) $(foreach dir,$(DIRS),-I$(dir)) -I$(TEST_DIR) $(TEST_DIR)/$(1).sv
define lint_tb_rule
lint_$(1):
	@echo "make lint_$1"
	@$(LINT_TB_CMD) || (echo $(LINT_TB_CMD); exit 1)
endef

$(foreach tb,$(TEST_BENCHES),$(eval $(call lint_tb_rule,$(tb))))

LINT_TOP_CMD=$(LINTER) $(foreach dir,$(DIRS),-I$(dir)) -I$(TEST_DIR) $(filter %/$(1).sv,$(TOP_MODULES_ALL))
define lint_top_rule
lint_$(1):
	@echo "make lint_$1"
	@$(LINT_TOP_CMD) || (echo $(LINT_TOP_CMD); exit 1)
endef

$(foreach top,$(TOP_MODULE_NAMES_ALL),$(eval $(call lint_top_rule,$(top))))

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
