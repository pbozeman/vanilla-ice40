# Ice40 config
DEVICE := hx4k
PACKAGE := tq144

# Directories
TEST_DIR := test
LIB_DIR := lib
BUILD_DIR := .build

# Dirs
DIRS := $(filter-out $(TEST_DIR)/, $(wildcard */))
TOP_DIRS := $(filter-out $(TEST_DIR)/, $(DIRS))

# Top modules
TOP_MODULES := $(foreach dir,$(TOP_DIRS),$(wildcard $(dir)*_top.v))

# Test benches
TEST_BENCHES := $(basename $(notdir $(wildcard $(TEST_DIR)/*_tb.v)))

# Files that have feature not supported by verible
VERIBLE_EXCLUDE := vga/vga_top.v

# Source files
SRC := $(filter-out $(VERIBLE_EXCLUDE), $(foreach dir,$(DIRS),$(wildcard $(dir)*.v)))
TB_LIB_SRC = $(filter-out test/%_tb.v, $(wildcard $(TEST_DIR)/*.v))
ALL_SRC = $(SRC) $(TB_LIB_SRC)

# Output executables
OUTS := $(patsubst %, $(BUILD_DIR)/%, $(TEST_BENCHES))

# Compiler and simulator
IVERILOG := iverilog -DSIMULATOR
VVP := vvp

# Linter
LINTER := verilator --lint-only --timing --Wno-WIDTHEXPAND --Wno-WIDTHTRUNC

# Formatter
FORMATTER := verible-verilog-format --inplace

# Synthesis
YOSYS := yosys

# PNR
NEXTPNR := nextpnr-ice40

# bin creation
ICEPACK := icepack

# programming
ICEPROG := iceprog

# All targets
all: check

# Ensure build directory exists
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

##############################################################################
#
# Synthesis
#
##############################################################################
define YOSYS_CMD
read_verilog $(dir $(1))*.v $(LIB_DIR)/*.v; \
synth_ice40 -top $(notdir $(basename $(1))); \
write_json $$@
endef

define synth_rule
$(BUILD_DIR)/$(notdir $(basename $(1))).json: $(1) $(LIB_DIR)/*.v | $(BUILD_DIR)
	$(YOSYS) -p '$(call YOSYS_CMD,$(1))'
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
PCF_FILES := $(wildcard $(PCF_DIR)/*.pcf)

define pnr_rule
$(BUILD_DIR)/$(notdir $(basename $(1))).asc: $(BUILD_DIR)/$(notdir $(basename $(1))).json $(PCF_FILES)
	$(NEXTPNR) --$(DEVICE) --package $(PACKAGE) --json $$< $(addprefix --pcf ,$(PCF_FILES)) --top $(notdir $(basename $(1))) --asc $$@
endef

$(foreach top,$(TOP_MODULES),$(eval $(call pnr_rule,$(top))))

.PHONY: pnr
pnr: $(addprefix $(BUILD_DIR)/,$(addsuffix .asc,$(notdir $(basename $(TOP_MODULES)))))

##############################################################################
#
# Bitstream
#
##############################################################################
define bitstream_rule
$(BUILD_DIR)/$(notdir $(basename $(1))).bin: $(BUILD_DIR)/$(notdir $(basename $(1))).asc
	$(ICEPACK) $$< $$@
endef

$(foreach top,$(TOP_MODULES),$(eval $(call bitstream_rule,$(top))))

.PHONY: bitstream
bitstream: $(addprefix $(BUILD_DIR)/,$(addsuffix .bin,$(notdir $(basename $(TOP_MODULES)))))

##############################################################################
#
# Programming
#
##############################################################################
# Rule to program a specific bitstream
define program_rule
.PHONY: program_$(notdir $(basename $(1)))
$(notdir $(basename $(1))): $(BUILD_DIR)/$(notdir $(basename $(1))).bin
	$(ICEPROG) $$<
endef

$(foreach top,$(TOP_MODULES),$(eval $(call program_rule,$(top))))

.PHONY: list
list:
	@echo "Available programming targets:"
	@$(foreach top,$(TOP_MODULES),echo " $(notdir $(basename $(top)))";)

##############################################################################
#
# Verification
#
##############################################################################
$(BUILD_DIR)/%: $(ALL_SRC) $(TEST_DIR)/%.v | $(BUILD_DIR)
	$(IVERILOG) -o $@ $^

SUCCESS_COUNT := 0
FAIL_COUNT := 0

# Function to run test bench and update counters
define run_test
	@$(VVP) $1 && echo "$1" >> $(BUILD_DIR)/tb_success.log || echo "$1" >> $(BUILD_DIR)/tb_failure.log
endef

# General rule for running each test bench
.PHONY: $(addprefix run_, $(TEST_BENCHES))
$(addprefix run_, $(TEST_BENCHES)): run_% : $(BUILD_DIR)/%
	@echo make $@
	$(call run_test,$<)

# Run all test benches sequentially and show summary
test: clean_logs $(addprefix run_, $(TEST_BENCHES))
	@echo "=============================="
	@echo "Successful tests: $$(wc -l < $(BUILD_DIR)/tb_success.log)"
	@echo "Failed tests: $$(wc -l < $(BUILD_DIR)/tb_failure.log)"
	@echo "=============================="

check: lint test

##############################################################################
#
# Linting
#
##############################################################################
.PHONY: lint lint_% $(addprefix lint_, $(TEST_BENCHES))
lint: $(addprefix lint_, $(TEST_BENCHES))

LINT_CMD=$(LINTER) $(foreach dir,$(DIRS),-I$(dir)) -I$(TEST_DIR) assert.v $(TEST_DIR)/$(1).v
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
	$(FORMATTER) $(ALL_SRC) $(TEST_DIR)/*.v

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
