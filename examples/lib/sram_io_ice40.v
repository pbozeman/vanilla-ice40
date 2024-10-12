
`ifndef SRAM_IO_ICE40_V
`define SRAM_IO_ICE40_V

`include "directives.v"

//
// See [Lattice ICE technology Library](https://www.latticesemi.com/~/media/latticesemi/documents/technicalbriefs/sbticetechnologylibrary201701.pdf)
//
// Heavily inspired by: https://github.com/mystorm-org/BlackIce-II/blob/master/examples/sram/src/sram_io_ice40.v
//

// The linter can't handle the Lattice IP simulation files
//
// verilator lint_save
// verilator lint_off UNDRIVEN
// verilator lint_off UNUSEDSIGNAL

module sram_io_ice40 #(
    parameter integer ADDR_BITS = 20,
    parameter integer DATA_BITS = 16
) (
    input wire clk,

    // to/from the ice40 pad
    input  wire [ADDR_BITS-1:0] pad_addr,
    input  wire [DATA_BITS-1:0] pad_write_data,
    input  wire                 pad_write_data_enable,
    output reg  [DATA_BITS-1:0] pad_read_data,
    output reg                  pad_read_data_valid,
    input  wire                 pad_ce_n,
    input  wire                 pad_we_n,
    input  wire                 pad_oe_n,

    // to/from the sram chip
    output wire [ADDR_BITS-1:0] io_addr_bus,
    inout  wire [DATA_BITS-1:0] io_data_bus,
    output wire                 io_we_n,
    output wire                 io_oe_n,
    output wire                 io_ce_n
);

`ifndef LINTING

  `define UNUSED_LOW 1'b0

  //
  // cs_n (posedge)
  //
  // PIN_TYPE[5:2] = Output registered, (no enable)
  // PIN_TYPE[1:0] = Simple input pin (D_IN_0)
  //
  SB_IO #(
      .PIN_TYPE   (6'b0101_01),
      .PULLUP     (1'b0),
      .NEG_TRIGGER(1'b0)
  ) u_sram_io_ce_n (
      .PACKAGE_PIN (io_ce_n),
      .CLOCK_ENABLE(1'b1),
      .OUTPUT_CLK  (clk),
      .D_OUT_0     (pad_ce_n)
  );

  //
  // we_n (negedge)
  //
  // PIN_TYPE[5:2] = Output 'DDR' data is clocked out on
  //                 rising and falling clock edges.
  // PIN_TYPE[1:0] = Simple input pin (D_IN_0)
  //
  reg        pad_we_n_p1;
  reg        pad_we_n_p2;
  wire [1:0] pad_we_n_ddr;

  always @(posedge clk) pad_we_n_p1 <= pad_we_n;
  always @(negedge clk) pad_we_n_p2 <= pad_we_n_p1;

  assign pad_we_n_ddr = {pad_we_n_p2, pad_we_n_p1};

  SB_IO #(
      .PIN_TYPE   (6'b0100_01),
      .PULLUP     (1'b0),
      .NEG_TRIGGER(1'b0)
  ) u_sram_io_we_n (
      .PACKAGE_PIN (io_we_n),
      .CLOCK_ENABLE(1'b1),
      .OUTPUT_CLK  (clk),
      .D_OUT_0     (pad_we_n_ddr[1]),
      .D_OUT_1     (pad_we_n_ddr[0])
  );

  //
  // oe_n (negedge)
  //
  // PIN_TYPE[5:2] = Output 'DDR' data is clocked out on
  //                 rising and falling clock edges.
  // PIN_TYPE[1:0] = Simple input pin (D_IN_0)
  //
  reg        pad_oe_n_p1;
  reg        pad_oe_n_p2;
  wire [1:0] pad_oe_n_ddr;

  always @(posedge clk) pad_oe_n_p1 <= pad_oe_n;
  always @(negedge clk) pad_oe_n_p2 <= pad_oe_n_p1;

  assign pad_oe_n_ddr = {pad_oe_n_p2, pad_oe_n_p1};

  SB_IO #(
      .PIN_TYPE   (6'b0100_01),
      .PULLUP     (1'b0),
      .NEG_TRIGGER(1'b0)
  ) u_sram_io_oe_n (
      .PACKAGE_PIN (io_oe_n),
      .CLOCK_ENABLE(1'b1),
      .OUTPUT_CLK  (clk),
      .D_OUT_0     (pad_oe_n_ddr[1]),
      .D_OUT_1     (pad_oe_n_ddr[0])
  );

  //
  // addr (posedge)
  //
  // PIN_TYPE[5:2] = Output registered, (no enable)
  // PIN_TYPE[1:0] = Simple input pin (D_IN_0)
  //
  SB_IO #(
      .PIN_TYPE   (6'b0101_01),
      .PULLUP     (1'b0),
      .NEG_TRIGGER(1'b0)
  ) u_sram_io_addr_bus[ADDR_BITS-1:0] (
      .PACKAGE_PIN (io_addr_bus),
      .CLOCK_ENABLE(1'b1),
      .OUTPUT_CLK  (clk),
      .D_OUT_0     (pad_addr)
  );

  //
  // data (posedge output, negedge input)
  //
  // PIN_TYPE[5:2] = Output registered and enable registered
  // PIN_TYPE[1:0] = Input 'DDR' data is clocked out on rising
  //                 and falling clock edges. Use the D_IN_0
  //                 and D_IN_1 pins for DDR operation.
  //
  wire [DATA_BITS-1:0] pad_read_data_p0;
  wire [DATA_BITS-1:0] pad_read_data_p1;

  SB_IO #(
      .PIN_TYPE   (6'b1101_00),
      .PULLUP     (1'b0),
      .NEG_TRIGGER(1'b0)
  ) u_sram_io_data[DATA_BITS-1:0] (
      .PACKAGE_PIN      (io_data_bus),
      .LATCH_INPUT_VALUE(1'b1),
      .CLOCK_ENABLE     (1'b1),
      .INPUT_CLK        (clk),
      .OUTPUT_CLK       (clk),
      .OUTPUT_ENABLE    (pad_write_data_enable),
      .D_OUT_0          (pad_write_data),
      .D_OUT_1          (pad_write_data),
      // .D_IN_0           (pad_read_data_p0),
      .D_IN_1           (pad_read_data_p1)
  );

  // non-neg version
  reg pad_oe_p2 = 1'b0;

  always @(posedge clk) begin
    if (pad_oe_p2) begin
      pad_read_data       <= pad_read_data_p1;
      pad_read_data_valid <= 1'b1;
    end else begin
      pad_read_data_valid <= 1'b0;
    end

    pad_oe_p2 <= !pad_oe_n_p1;
  end

`endif

endmodule

// verilator lint_restore

`endif
