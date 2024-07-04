`ifndef SRAM_TESTER_TOP_V
`define SRAM_TESTER_TOP_V

`include "directives.v"

`include "bit_reverser.v"
`include "sram_tester.v"

module sram_tester_top #(
    parameter integer ADDR_BITS = 20,
    parameter integer DATA_BITS = 16
) (
    // board signals
    input  wire CLK,
    output wire LED1,
    output wire LED2,

    // Buses
    output wire [ADDR_BITS-1:0] SRAM_ADDR_BUS,
    inout  wire [DATA_BITS-1:0] SRAM_DATA_BUS,

    // Control signals
    output wire SRAM_CS_N,
    output wire SRAM_OE_N,
    output wire SRAM_WE_N,

    output wire [7:0] BA_PINS,
    output wire [7:0] DC_PINS,
    output wire [7:0] KL_PINS,
    output wire [7:0] HG_PINS,
    output wire [7:0] LK_PINS

);

  // Internal signals
  wire reset = 0;
  wire [ADDR_BITS-1:0] addr;
  wire [DATA_BITS-1:0] write_data;
  wire [DATA_BITS-1:0] read_data;
  wire test_done;
  wire test_pass;
  wire read_only;

  wire [2:0] pattern_state;
  wire [2:0] test_state;
  wire [DATA_BITS-1:0] prev_expected_data;
  wire [DATA_BITS-1:0] prev_read_data;

  // Instantiate the sram_tester
  sram_tester #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) tester (
      .clk(CLK),
      .reset(reset),
      .test_done(test_done),
      .test_pass(test_pass),
      .pattern_state(pattern_state),
      .test_state(test_state),
      .prev_expected_data(prev_expected_data),
      .prev_read_data(prev_read_data),
      .read_only(read_only),
      .addr(addr),
      .write_data(write_data),
      .read_data(read_data),
      .addr_bus(SRAM_ADDR_BUS),
      .data_bus(SRAM_DATA_BUS),
      .ce_n(SRAM_CS_N),
      .we_n(SRAM_WE_N),
      .oe_n(SRAM_OE_N)
  );

  wire [ADDR_BITS-1:0] addr_reversed;
  wire [DATA_BITS-1:0] data_reversed;

  // Reverse the entire address
  bit_reverser #(
      .WIDTH(ADDR_BITS)
  ) addr_reverser (
      .in (addr),
      .out(addr_reversed)
  );
  // Reverse the data

  bit_reverser #(
      .WIDTH(8)
  ) data_reverser (
      .in (SRAM_DATA_BUS),
      .out(data_reversed)
  );

  wire [2:0] pattern_state_reversed;
  bit_reverser #(
      .WIDTH(3)
  ) pattern_state_reverser (
      .in (pattern_state),
      .out(pattern_state_reversed)
  );

  // LED1 blinks every addr reset (too fast to see, use a scope)
  assign LED1 = CLK;  //(addr == {ADDR_BITS{1'b0}});

  // LED2 is success
  assign LED2 = test_pass;

  assign HG_PINS = (test_pass ? write_data : prev_expected_data);
  assign LK_PINS = (test_pass ? read_data : prev_read_data);

  assign BA_PINS[2:0] = pattern_state_reversed;

  // set pmod leds to the addr
  generate
    if (ADDR_BITS >= 20) begin : full_addr_mapping
      assign BA_PINS[3]   = 1'b0;
      assign BA_PINS[7:4] = addr_reversed[3:0];
      assign DC_PINS      = addr_reversed[11:4];
      assign KL_PINS      = addr_reversed[19:12];
    end else if (ADDR_BITS >= 16) begin : partial_addr_mapping
      assign BA_PINS[3]   = 1'b0;
      assign BA_PINS[7:4] = addr_reversed[3:0];
      assign DC_PINS      = addr_reversed[11:4];
      assign KL_PINS      = addr_reversed[ADDR_BITS-1:12];
    end else begin : minimal_addr_mapping
      assign BA_PINS[3]   = 1'b0;
      assign BA_PINS[7:4] = 4'b0;
      assign DC_PINS      = addr_reversed[ADDR_BITS-1:ADDR_BITS/2];
      assign KL_PINS      = addr_reversed[ADDR_BITS/2-1:0];
    end
  endgenerate

endmodule

`endif
