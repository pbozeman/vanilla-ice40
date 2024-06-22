# Directories
TEST_DIR = test
BUILD_DIR = .build

# Common sources
COMMON_SRC = $(wildcard common/*.v))

# VGA sources
VGA_SRC = vga/src/pixel_addr.v

# Common sources
SRC = $(COMMON_SRC) $(VGA_SRC)
TB_COMMON_SRC = $(filter-out %_tb.v, $(wildcard $(TEST_DIR)/*.v))
ALL_SRC = $(SRC) $(TB_COMMON_SRC)

# Test benches
TEST_BENCHES = counter_tb pixel_addr_tb

# Output executables
OUTS = $(patsubst %, $(BUILD_DIR)/%, $(TEST_BENCHES))

# Compiler and simulator
IVERILOG = iverilog -DSIMULATOR
VVP = vvp

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
	touch $(BUILD_DIR)/tb_success.log
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

check: test

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)

clean_logs: $(BUILD_DIR)
	@rm -f $(BUILD_DIR)/tb_success.log $(BUILD_DIR)/tb_failure.log
	@touch $(BUILD_DIR)/tb_failure.log

.PHONY: all clean clean_logs check test $(addprefix run_, $(TEST_BENCHES))
