`ifndef SKIDBUF_DEMO_TOP_V
`define SKIDBUF_DEMO_TOP_V

`include "directives.sv"

`include "skidbuf_demo.sv"
`include "initial_reset.sv"

module skidbuf_demo_top (
    input logic CLK,

    input  logic [7:0] R_E,
    output logic [7:0] R_F
);
  logic reset;

  skidbuf_demo demo (
      .clk     (CLK),
      .reset   (reset),
      .data_in (R_E),
      .data_out(R_F)
  );

  initial_reset initial_reset_inst (
      .clk  (CLK),
      .reset(reset)
  );

endmodule

`endif
