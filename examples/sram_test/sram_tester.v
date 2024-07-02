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

  wire next_addr;
  wire next_pattern;
  wire addr_done;
  wire pattern_done;
  wire enable_checker;
  wire addr_gen_reset;
  wire pattern_gen_reset;
  wire test_fail;
  wire [ADDR_BITS-1:0] addr_read;

  assign test_fail = ~test_pass;

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

  wire [DATA_BITS-1:0] pattern;

  reg  [DATA_BITS-1:0] hack_pattern;

  assign data_write = hack_pattern;

  always @* begin
    if (pattern_state == 3'b110) begin
      if (read_only) begin
        hack_pattern = addr_read;
      end else begin
        hack_pattern = addr;
      end
    end else begin
      hack_pattern = pattern;
    end
  end

  pattern_generator #(
      .DATA_BITS(DATA_BITS)
  ) pattern_gen (
      .clk(clk),
      .reset(pattern_gen_reset),
      .next_pattern(next_pattern),
      .pattern(pattern),
      .pattern_done(pattern_done),
      .seed(addr[DATA_BITS-1:0]),
      .pattern_state(pattern_state)
  );

  iter #(
      .MAX_VALUE((1 << ADDR_BITS) - 1)
  ) addr_gen (
      .clk(clk),
      .reset(addr_gen_reset),
      .next(next_addr),
      .val(addr),
      .done(addr_done)
  );

  test_controller test_ctrl (
      .clk(clk),
      .reset(reset),
      .addr_done(addr_done),
      .pattern_done(pattern_done),
      .test_fail(test_fail),
      .read_only(read_only),
      .next_addr(next_addr),
      .next_pattern(next_pattern),
      .test_done(test_done),
      .addr_gen_reset(addr_gen_reset),
      .pattern_gen_reset(pattern_gen_reset),
      .enable_checker(enable_checker),
      .test_state(test_state)
  );

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

  result_checker #(
      .DATA_BITS(DATA_BITS)
  ) result_check (
      .clk(clk),
      .reset(reset),
      .enable(enable_checker),
      .read_data(data_read),
      .expected_data(hack_pattern),
      .test_pass(test_pass),
      .prev_read_data(prev_read_data),
      .prev_expected_data(prev_expected_data)
  );

endmodule
