`ifndef SRAM_TESTER_TOP_V
`define SRAM_TESTER_TOP_V

`include "directives.sv"

`include "bit_reverser.sv"
`include "sram_tester.sv"

module sram_tester_top #(
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

  logic [ADDR_BITS-1:0] sram_addr;
  logic [DATA_BITS-1:0] sram_write_data;
  logic [DATA_BITS-1:0] sram_read_data;
  logic                 test_done;
  logic                 test_pass;
  logic                 sram_write_enable;

  logic [          2:0] pattern_state;
  logic [DATA_BITS-1:0] prev_expected_data;
  logic [DATA_BITS-1:0] prev_read_data;

  sram_tester #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) tester (
      // main signals
      .clk      (CLK),
      .reset    (reset),
      .test_done(test_done),
      .test_pass(test_pass),

      // debug signals
      .pattern_state     (pattern_state),
      .prev_expected_data(prev_expected_data),
      .prev_read_data    (prev_read_data),

      // sram controller signals
      .sram_write_enable(sram_write_enable),
      .sram_addr        (sram_addr),
      .sram_write_data  (sram_write_data),
      .sram_read_data   (sram_read_data),

      // sram controller to io pins
      .sram_io_addr_bus(R_SRAM_ADDR_BUS),
      .sram_io_data_bus(R_SRAM_DATA_BUS),
      .sram_io_ce_n    (R_SRAM_CS_N),
      .sram_io_we_n    (R_SRAM_WE_N),
      .sram_io_oe_n    (R_SRAM_OE_N)
  );

  logic [ADDR_BITS-1:0] addr_reversed;
  logic [DATA_BITS-1:0] data_reversed;

  // Reverse the entire address
  bit_reverser #(
      .WIDTH(ADDR_BITS)
  ) addr_reverser (
      .in (sram_addr),
      .out(addr_reversed)
  );

  // Reverse the data
  bit_reverser #(
      .WIDTH(8)
  ) data_reverser (
      .in (R_SRAM_DATA_BUS),
      .out(data_reversed)
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

  assign R_I      = (test_pass ? sram_write_data : prev_expected_data);
  assign R_J      = (test_pass ? sram_read_data : prev_read_data);

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
