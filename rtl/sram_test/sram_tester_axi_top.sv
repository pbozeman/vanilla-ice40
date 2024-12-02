`ifndef SRAM_TESTER_AXI_TOP_V
`define SRAM_TESTER_AXI_TOP_V

`include "directives.sv"

`include "bit_reverser.sv"
`include "sram_tester_axi.sv"

module sram_tester_axi_top #(
    parameter integer ADDR_BITS = 20,
    parameter integer DATA_BITS = 16
) (
    // board signals
    input  logic CLK,
    output logic LED1,
    output logic LED2,

    // Buses
    output logic [ADDR_BITS-1:0] R_SRAM_ADDR_BUS,
    inout  wire  [DATA_BITS-1:0] R_SRAM_DATA_BUS,

    // Control signals
    output logic R_SRAM_CS_N,
    output logic R_SRAM_OE_N,
    output logic R_SRAM_WE_N,

    output logic [7:0] R_E,
    output logic [7:0] R_F,
    output logic [7:0] R_H,
    output logic [7:0] R_I,
    output logic [7:0] R_J
);

  // Internal signals
  logic                 reset = 0;
  logic [          3:0] reset_counter = 0;

  logic                 test_done;
  logic                 test_pass;

  logic [          2:0] pattern_state;
  // verilator lint_off UNUSEDSIGNAL
  logic [DATA_BITS-1:0] expected_data;
  logic [DATA_BITS-1:0] read_data;
  // verilator lint_on UNUSEDSIGNAL

  logic [ADDR_BITS-1:0] iter_addr;

  sram_tester_axi #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) tester (
      // main signals
      .clk      (CLK),
      .reset    (reset),
      .test_done(test_done),
      .test_pass(test_pass),

      // debug signals
      .pattern_state(pattern_state),
      .expected_data(expected_data),
      .read_data    (read_data),
      .iter_addr    (iter_addr),

      // sram controller to io pins
      .sram_io_addr(R_SRAM_ADDR_BUS),
      .sram_io_data(R_SRAM_DATA_BUS),
      .sram_io_ce_n(R_SRAM_CS_N),
      .sram_io_we_n(R_SRAM_WE_N),
      .sram_io_oe_n(R_SRAM_OE_N)
  );

  // The addr leds are not in sync with the data, but I just want to see that
  // they are moving. The first pipeline is needed to meet timing.
  logic [ADDR_BITS-1:0] addr_pipeline;
  logic [ADDR_BITS-1:0] addr_reversed;

  always_ff @(posedge CLK) begin
    addr_pipeline <= iter_addr;
  end

  // Reverse the entire address
  bit_reverser #(
      .WIDTH(ADDR_BITS)
  ) addr_reverser (
      .in (addr_pipeline),
      .out(addr_reversed)
  );

  logic [2:0] pattern_state_reversed;
  bit_reverser #(
      .WIDTH(3)
  ) pattern_state_reverser (
      .in (pattern_state),
      .out(pattern_state_reversed)
  );

  // 10 clock reset
  always_ff @(posedge CLK) begin
    if (reset_counter < 4'd10) begin
      reset_counter <= reset_counter + 1;
      reset         <= 1;
    end else begin
      reset <= 0;
    end
  end

  // LED1 blinks every test round (too fast to see, use a scope)
  assign LED1     = test_done;

  // LED2 is success
  assign LED2     = test_pass;

  assign R_I      = expected_data;
  assign R_J      = read_data;

  assign R_E[2:0] = pattern_state_reversed;

  // set pmod leds to the addr
  generate
    if (ADDR_BITS >= 20) begin : full_addr_mapping
      assign R_E[3]   = 1'b0;
      assign R_E[7:4] = addr_reversed[3:0];
      assign R_F      = addr_reversed[11:4];
      assign R_H      = addr_reversed[19:12];
    end else if (ADDR_BITS >= 16) begin : partial_addr_mapping
      assign R_E[3]   = 1'b0;
      assign R_E[7:4] = addr_reversed[3:0];
      assign R_F      = addr_reversed[11:4];
      assign R_H      = addr_reversed[ADDR_BITS-1:12];
    end else begin : minimal_addr_mapping
      assign R_E[3]   = 1'b0;
      assign R_E[7:4] = 4'b0;
      assign R_F      = addr_reversed[ADDR_BITS-1:ADDR_BITS/2];
      assign R_H      = addr_reversed[ADDR_BITS/2-1:0];
    end
  endgenerate

endmodule

`endif
