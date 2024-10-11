`ifndef SRAM_TESTER_AXI_V
`define SRAM_TESTER_AXI_V

`include "directives.v"

`include "axi_sram_controller.v"
`include "iter.v"
`include "sram_pattern_generator.v"

module sram_tester_axi #(
    parameter integer ADDR_BITS = 20,
    parameter integer DATA_BITS = 16
) (
    // tester signals
    input  wire clk,
    input  wire reset,
    output reg  test_done,
    output reg  test_pass,

    // debug/output signals
    output wire [2:0] pattern_state,
    output reg [DATA_BITS-1:0] prev_read_data,
    output reg [DATA_BITS-1:0] prev_expected_data,

    // sram controller to io pins
    output wire [ADDR_BITS-1:0] sram_addr,
    inout wire [DATA_BITS-1:0] sram_data,
    output wire sram_we_n,
    output wire sram_oe_n,
    output wire sram_ce_n
);
  // AXI-Lite Write Address Channel
  reg  [ADDR_BITS-1:0] axi_awaddr;
  reg                  axi_awvalid;
  wire                 axi_awready;

  // AXI-Lite Write Data Channel
  reg  [DATA_BITS-1:0] axi_wdata;
  reg                  axi_wstrb;
  reg                  axi_wvalid;
  wire                 axi_wready;

  // AXI-Lite Write Response Channel
  wire [          1:0] axi_bresp;
  wire                 axi_bvalid;
  reg                  axi_bready;

  // AXI-Lite Read Address Channel
  reg  [ADDR_BITS-1:0] axi_araddr;
  reg                  axi_arvalid;
  wire                 axi_arready;

  // AXI-Lite Read Data Channel
  wire [DATA_BITS-1:0] axi_rdata;
  wire [          1:0] axi_rresp;
  wire                 axi_rvalid;
  reg                  axi_rready;

  // Address iteration signals
  reg                  iter_addr_inc;
  wire [ADDR_BITS-1:0] iter_addr;
  wire                 iter_addr_done;

  // Pattern gen signals
  wire                 pattern_reset;
  reg                  pattern_inc;
  wire [DATA_BITS-1:0] pattern;
  wire                 pattern_done;
  reg  [DATA_BITS-1:0] pattern_custom;

  // State definitions
  localparam [2:0] START = 3'b000;
  localparam [2:0] WRITING = 3'b001;
  localparam [2:0] READING = 3'b010;
  localparam [2:0] DONE = 3'b011;
  localparam [2:0] HALT = 3'b100;

  // State and next state registers
  reg [2:0] state;
  reg [2:0] next_state;

  // Instantiate the AXI SRAM controller
  axi_sram_controller #(
      .AXI_ADDR_WIDTH(ADDR_BITS),
      .AXI_DATA_WIDTH(DATA_BITS)
  ) ctrl (
      .axi_clk(clk),
      .axi_resetn(~reset),
      .axi_awaddr(axi_awaddr),
      .axi_awvalid(axi_awvalid),
      .axi_awready(axi_awready),
      .axi_wdata(axi_wdata),
      .axi_wstrb(axi_wstrb),
      .axi_wvalid(axi_wvalid),
      .axi_wready(axi_wready),
      .axi_bresp(axi_bresp),
      .axi_bvalid(axi_bvalid),
      .axi_bready(axi_bready),
      .axi_araddr(axi_araddr),
      .axi_arvalid(axi_arvalid),
      .axi_arready(axi_arready),
      .axi_rdata(axi_rdata),
      .axi_rresp(axi_rresp),
      .axi_rvalid(axi_rvalid),
      .axi_rready(axi_rready),
      .sram_addr(sram_addr),
      .sram_data(sram_data),
      .sram_we_n(sram_we_n),
      .sram_oe_n(sram_oe_n),
      .sram_ce_n(sram_ce_n)
  );

  iter #(
      .MAX_VALUE((1 << ADDR_BITS) - 1)
  ) addr_gen (
      .clk  (clk),
      .reset(reset),
      .inc  (iter_addr_inc),
      .val  (iter_addr),
      .done (iter_addr_done)
  );

  sram_pattern_generator #(
      .DATA_BITS(DATA_BITS)
  ) pattern_gen (
      .clk(clk),
      .reset(pattern_reset),
      .inc(pattern_inc),
      .custom(pattern_custom),
      .pattern(pattern),
      .done(pattern_done),
      .state(pattern_state)
  );

  reg  write_start;
  wire write_done;

  reg  read_start;
  wire read_done;

  reg  last_read_write;

  //
  // Combinational logic process
  //
  always @(*) begin
    next_state = state;
    write_start = 1'b0;
    read_start = 1'b0;
    iter_addr_inc = 1'b0;

    if (!reset) begin
      if (!test_pass) begin
        next_state = HALT;
      end else begin
        case (state)
          START: begin
            write_start = 1'b1;
            iter_addr_inc = 1'b1;
            next_state = WRITING;
          end

          WRITING: begin
            if (write_done) begin
              iter_addr_inc = 1'b1;

              if (!last_read_write) begin
                write_start = 1'b1;
              end else begin
                read_start = 1'b1;
                next_state = READING;
              end
            end
          end

          READING: begin
            if (read_done) begin
              iter_addr_inc = 1'b1;

              if (!last_read_write) begin
                read_start = 1'b1;
              end else begin
                write_start = 1'b1;
                pattern_inc = 1'b1;
                next_state  = WRITING;
              end
            end
          end

          default: begin
          end

        endcase
      end
    end
  end

  //
  // State registration
  //
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= START;
    end else begin
      state <= next_state;
    end
  end

  //
  // AXI write
  //
  assign write_done = (axi_bready && axi_bvalid);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      axi_awvalid <= 1'b0;
      axi_wvalid  <= 1'b0;
      axi_bready  <= 1'b0;
    end else begin
      // We're always ready for a response
      axi_bready <= 1'b1;

      // kick off a write, or wait to de-assert valid
      if (write_start) begin
        axi_awaddr  <= iter_addr;
        axi_wdata   <= pattern;
        axi_awvalid <= 1'b1;
        axi_wvalid  <= 1'b1;
      end else begin
        if (axi_awready && axi_awvalid) begin
          axi_awvalid <= 1'b0;
        end

        if (axi_wready && axi_wvalid) begin
          axi_wvalid <= 1'b0;
        end
      end
    end
  end

  //
  // AXI read
  //
  reg [DATA_BITS-1:0] expected_data;

  assign read_done = (axi_rready && axi_rvalid);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      axi_arvalid <= 1'b0;
      axi_rready  <= 1'b0;
    end else begin
      // We're always ready for a response
      axi_rready <= 1'b1;

      // kick off a read, or wait to de-assert valid
      if (read_start) begin
        axi_araddr <= iter_addr;
        axi_arvalid <= 1'b1;
        expected_data <= pattern;
      end else begin
        if (axi_arready && axi_arvalid) begin
          axi_arvalid <= 1'b0;
        end
      end

    end
  end

  //
  // test response and debug signals
  //
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      test_pass <= 1'b1;
      prev_read_data <= {DATA_BITS{1'b0}};
      prev_expected_data <= {DATA_BITS{1'b0}};
    end else begin
      if (read_done) begin
        prev_read_data <= axi_rdata;
        prev_expected_data <= expected_data;
        if (axi_rdata != expected_data) begin
          test_pass <= 1'b0;
        end
      end
    end
  end

  //
  // test done
  //
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      test_done <= 1'b0;
    end else begin
      test_done <= (state == READING && next_state == WRITING);
    end
  end

  //
  // last read/write detection
  //
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      last_read_write <= 1'b0;
    end else begin
      if (state != next_state) begin
        last_read_write <= 0;
      end else begin
        if (iter_addr_done & iter_addr_inc) begin
          last_read_write <= iter_addr_done & iter_addr_inc;
        end
      end
    end
  end

endmodule

`endif

