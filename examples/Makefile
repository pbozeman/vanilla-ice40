# Directories
TEST_DIR = test
BUILD_DIR = .build

# Lib sources
LIB_SRC = $(wildcard lib/*.v)

# VGA sources
VGA_SRC = $(filter-out %_top.v, $(wildcard vga/*.v))

# UART sources
UART_SRC = $(wildcard uart/*.v)

# All sources
SRC = $(LIB_SRC) $(VGA_SRC) $(UART_SRC)
TB_LIB_SRC = $(filter-out %_tb.v, $(wildcard $(TEST_DIR)/*.v))
ALL_SRC = $(SRC) $(TB_LIB_SRC)

# Test benches
TEST_BENCHES = counter_tb pixel_addr_tb vga_tb vga_test_01_tb uart_hello_tb fifo_tb

# Output executables
OUTS = $(patsubst %, $(BUILD_DIR)/%, $(TEST_BENCHES))

# Compiler and simulator
IVERILOG = iverilog -DSIMULATOR
VVP = vvp

# Linter
LINTER = verilator --lint-only --timing --Wno-WIDTHEXPAND

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
	@echo "Running $1..."
	@$(VVP) $1 && echo "$1" >> $(BUILD_DIR)/tb_success.log || echo "$1" >> $(BUILD_DIR)/tb_failure.log
endef

# General rule for running each test bench
.PHONY: $(addprefix run_, $(TEST_BENCHES))
$(addprefix run_, $(TEST_BENCHES)): run_% : $(BUILD_DIR)/%
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

define lint_rule
lint_$(1):
	$(LINTER) -Ilib -Ivga/src -Iuart -Itest assert.v $(TEST_DIR)/$(1).v
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
