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
      .addr_bus(addr_bus),
      .we_n(we_n),
      .oe_n(oe_n),
      .data_bus_io(data_bus),
      .ce_n(ce_n)
  );

  wire [DATA_BITS-1:0] pattern;
  assign data_write = pattern;

  pattern_generator #(
      .DATA_BITS(DATA_BITS)
  ) pattern_gen (
      .clk(clk),
      .reset(reset),
      .next_pattern(next_pattern),
      .pattern(pattern),
      .pattern_done(pattern_done),
      .seed(addr[DATA_BITS-1:0])
  );

  address_generator #(
      .ADDR_BITS(ADDR_BITS)
  ) addr_gen (
      .clk(clk),
      .reset(addr_gen_reset),
      .next_addr(next_addr),
      .addr(addr),
      .addr_done(addr_done)
  );

  test_controller test_ctrl (
      .clk(clk),
      .reset(reset),
      .addr_done(addr_done),
      .pattern_done(pattern_done),
      .read_only(read_only),
      .next_addr(next_addr),
      .next_pattern(next_pattern),
      .test_done(test_done),
      .addr_gen_reset(addr_gen_reset),
      .enable_checker(enable_checker)
  );

  reg [DATA_BITS-1:0] prev_pattern;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      prev_pattern <= {DATA_BITS{1'b0}};
    end else begin
      prev_pattern <= pattern;
    end
  end

  result_checker #(
      .DATA_BITS(DATA_BITS)
  ) result_check (
      .clk(clk),
      .reset(reset),
      .enable(enable_checker),
      .read_data(data_read),
      .expected_data(prev_pattern),
      .test_pass(test_pass)
  );

endmodule
