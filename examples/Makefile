# Directories
TEST_DIR = test
BUILD_DIR = .build

# Test benches
TEST_BENCHES = $(basename $(notdir $(wildcard $(TEST_DIR)/*_tb.v)))

# Files that have feature not supported by verible
VERIBLE_EXCLUDE = vga/vga_top.v blinky_pmod/blinky_all_top.v

# Source files
DIRS := $(filter-out $(TEST_DIR)/, $(wildcard */))
SRC := $(filter-out $(VERIBLE_EXCLUDE), $(foreach dir,$(DIRS),$(wildcard $(dir)*.v)))
TB_LIB_SRC = $(filter-out test/%_tb.v, $(wildcard $(TEST_DIR)/*.v))
ALL_SRC = $(SRC) $(TB_LIB_SRC)

# Output executables
OUTS = $(patsubst %, $(BUILD_DIR)/%, $(TEST_BENCHES))

# Compiler and simulator
IVERILOG = iverilog -DSIMULATOR
VVP = vvp

# Linter
LINTER = verilator --lint-only --timing --Wno-WIDTHEXPAND --Wno-WIDTHTRUNC

# Formatter
FORMATTER = verible-verilog-format --inplace

# All targets
all: $(OUTS)

# Ensure build directory exists
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# General rule for building each test bench executable
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

# Linting rules
.PHONY: lint lint_% $(addprefix lint_, $(TEST_BENCHES))
lint: $(addprefix lint_, $(TEST_BENCHES))

LINT_CMD=$(LINTER) $(foreach dir,$(DIRS),-I$(dir)) -I$(TEST_DIR) assert.v $(TEST_DIR)/$(1).v
define lint_rule
lint_$(1):
	@echo "make lint $1"
	@$(LINT_CMD) || (echo $(LINT_CMD); exit 1)
endef

$(foreach tb,$(TEST_BENCHES),$(eval $(call lint_rule,$(tb))))

# Formatting rule
.PHONY: format
format:
	$(FORMATTER) $(ALL_SRC) $(TEST_DIR)/*.v

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)

clean_logs: $(BUILD_DIR)
	@rm -f $(BUILD_DIR)/tb_success.log $(BUILD_DIR)/tb_failure.log
	@touch $(BUILD_DIR)/tb_success.log $(BUILD_DIR)/tb_failure.log

.PHONY: all clean clean_logs check test $(addprefix run_, $(TEST_BENCHES))
