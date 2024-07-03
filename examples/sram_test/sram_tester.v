// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module sram_tester #(
    parameter integer ADDR_BITS = 20,
    parameter integer DATA_BITS = 16
) (
    input  wire clk,
    input  wire reset,
    output wire test_done,
    output wire test_pass,

    // debug signals
    output wire [2:0] pattern_state,
    output wire [2:0] test_state,
    output wire [DATA_BITS-1:0] prev_read_data,
    output wire [DATA_BITS-1:0] prev_expected_data,

    // sram pins
    output wire read_only,
    output wire [ADDR_BITS-1:0] addr,
    output wire [DATA_BITS-1:0] data_write,
    output wire [DATA_BITS-1:0] data_read,
    output wire [ADDR_BITS-1:0] addr_bus,
    inout wire [DATA_BITS-1:0] data_bus,
    output wire we_n,
    output wire oe_n,
    output wire ce_n
);

  // address generator signals
  wire addr_reset;
  wire addr_next;
  wire addr_done;
  wire [ADDR_BITS-1:0] addr_read;

  // pattern generator signals
  wire pattern_reset;
  wire pattern_next;
  wire pattern_done;
  wire [DATA_BITS-1:0] pattern;
  reg [DATA_BITS-1:0] pattern_custom;

  // result checker signals
  wire enable_checker;
  wire test_fail;

  // Address generation
  iter #(
      .MAX_VALUE((1 << ADDR_BITS) - 1)
  ) addr_gen (
      .clk  (clk),
      .reset(addr_reset),
      .next (addr_next),
      .val  (addr),
      .done (addr_done)
  );

  // Pattern generation
  always @* begin
    if (read_only) begin
      pattern_custom = addr_read;
    end else begin
      pattern_custom = addr;
    end
  end

  pattern_generator #(
      .DATA_BITS(DATA_BITS)
  ) pattern_gen (
      .clk(clk),
      .reset(pattern_reset),
      .next(pattern_next),
      .pattern(pattern),
      .done(pattern_done),
      .custom(pattern_custom),
      .state(pattern_state)
  );

  test_controller test_ctrl (
      .clk(clk),
      .reset(reset),
      .test_done(test_done),
      .test_state(test_state),
      .addr_reset(addr_reset),
      .addr_next(addr_next),
      .addr_done(addr_done),
      .pattern_reset(pattern_reset),
      .pattern_next(pattern_next),
      .pattern_done(pattern_done),
      .enable_checker(enable_checker),
      .test_fail(test_fail),
      .sram_read_only(read_only)
  );

  // Debug outputs to use in the case of test failure
  // (these will the the ones that failed, since test_fail
  // is clocked)
  reg [DATA_BITS-1:0] prev_pattern = {DATA_BITS{1'b0}};
  reg [ADDR_BITS-1:0] prev_addr = 0;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      prev_pattern <= {DATA_BITS{1'b0}};
      prev_addr <= 0;
    end else begin
      prev_pattern <= pattern;
      prev_addr <= addr;
    end
  end

  // Results checker
  assign test_fail = ~test_pass;

  result_checker #(
      .DATA_BITS(DATA_BITS)
  ) result_check (
      .clk(clk),
      .reset(reset),
      .enable(enable_checker),
      .read_data(data_read),
      .expected_data(pattern_custom),
      .test_pass(test_pass),
      .prev_read_data(prev_read_data),
      .prev_expected_data(prev_expected_data)
  );

  // Sram
  assign data_write = pattern;

  sram_controller #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) sram_ctrl (
      .clk(clk),
      .reset(reset),
      .addr(addr),
      .read_only(read_only),
      .data_i(data_write),
      .data_o(data_read),
      .data_o_addr(addr_read),
      .addr_bus(addr_bus),
      .we_n(we_n),
      .oe_n(oe_n),
      .data_bus_io(data_bus),
      .ce_n(ce_n)
  );

endmodule
