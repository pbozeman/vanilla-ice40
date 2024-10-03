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
  reg  [ADDR_BITS-1:0] s_axi_awaddr;
  reg                  s_axi_awvalid;
  wire                 s_axi_awready;

  // AXI-Lite Write Data Channel
  reg  [DATA_BITS-1:0] s_axi_wdata;
  reg                  s_axi_wstrb;
  reg                  s_axi_wvalid;
  wire                 s_axi_wready;

  // AXI-Lite Write Response Channel
  wire [          1:0] s_axi_bresp;
  wire                 s_axi_bvalid;
  reg                  s_axi_bready;

  // AXI-Lite Read Address Channel
  reg  [ADDR_BITS-1:0] s_axi_araddr;
  reg                  s_axi_arvalid;
  wire                 s_axi_arready;

  // AXI-Lite Read Data Channel
  wire [DATA_BITS-1:0] s_axi_rdata;
  wire [          1:0] s_axi_rresp;
  wire                 s_axi_rvalid;
  reg                  s_axi_rready;

  // Address iteration signals
  reg                  iter_addr_next;
  wire [ADDR_BITS-1:0] iter_addr;
  wire                 iter_addr_done;

  // Pattern gen signals
  wire                 pattern_reset;
  reg                  pattern_next;
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
      .axi_aclk(clk),
      .axi_aresetn(~reset),
      .s_axi_awaddr(s_axi_awaddr),
      .s_axi_awvalid(s_axi_awvalid),
      .s_axi_awready(s_axi_awready),
      .s_axi_wdata(s_axi_wdata),
      .s_axi_wstrb(s_axi_wstrb),
      .s_axi_wvalid(s_axi_wvalid),
      .s_axi_wready(s_axi_wready),
      .s_axi_bresp(s_axi_bresp),
      .s_axi_bvalid(s_axi_bvalid),
      .s_axi_bready(s_axi_bready),
      .s_axi_araddr(s_axi_araddr),
      .s_axi_arvalid(s_axi_arvalid),
      .s_axi_arready(s_axi_arready),
      .s_axi_rdata(s_axi_rdata),
      .s_axi_rresp(s_axi_rresp),
      .s_axi_rvalid(s_axi_rvalid),
      .s_axi_rready(s_axi_rready),
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
      .next (iter_addr_next),
      .val  (iter_addr),
      .done (iter_addr_done)
  );

  sram_pattern_generator #(
      .DATA_BITS(DATA_BITS)
  ) pattern_gen (
      .clk(clk),
      .reset(pattern_reset),
      .next(pattern_next),
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
    iter_addr_next = 1'b0;

    if (!reset) begin
      if (!test_pass) begin
        next_state = HALT;
      end else begin
        case (state)
          START: begin
            write_start = 1'b1;
            iter_addr_next = 1'b1;
            next_state = WRITING;
          end

          WRITING: begin
            if (write_done) begin
              iter_addr_next = 1'b1;

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
              iter_addr_next = 1'b1;

              if (!last_read_write) begin
                read_start = 1'b1;
              end else begin
                write_start  = 1'b1;
                pattern_next = 1'b1;
                next_state   = WRITING;
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
  assign write_done = (s_axi_bready && s_axi_bvalid);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      s_axi_awvalid <= 1'b0;
      s_axi_wvalid  <= 1'b0;
      s_axi_bready  <= 1'b0;
    end else begin
      // We're always ready for a response
      s_axi_bready <= 1'b1;

      // kick off a write, or wait to de-assert valid
      if (write_start) begin
        s_axi_awaddr  <= iter_addr;
        s_axi_wdata   <= pattern;
        s_axi_awvalid <= 1'b1;
        s_axi_wvalid  <= 1'b1;
      end else begin
        if (s_axi_awready && s_axi_awvalid) begin
          s_axi_awvalid <= 1'b0;
        end

        if (s_axi_wready && s_axi_wvalid) begin
          s_axi_wvalid <= 1'b0;
        end
      end
    end
  end

  //
  // AXI read
  //
  reg [DATA_BITS-1:0] expected_data;

  assign read_done = (s_axi_rready && s_axi_rvalid);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      s_axi_arvalid <= 1'b0;
      s_axi_rready  <= 1'b0;
    end else begin
      // We're always ready for a response
      s_axi_rready <= 1'b1;

      // kick off a read, or wait to de-assert valid
      if (read_start) begin
        s_axi_araddr  <= iter_addr;
        s_axi_arvalid <= 1'b1;
        expected_data <= pattern;
      end else begin
        if (s_axi_arready && s_axi_arvalid) begin
          s_axi_arvalid <= 1'b0;
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
        prev_read_data <= s_axi_rdata;
        prev_expected_data <= expected_data;
        if (s_axi_rdata != expected_data) begin
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
        if (iter_addr_done & iter_addr_next) begin
          last_read_write <= iter_addr_done & iter_addr_next;
        end
      end
    end
  end

endmodule

`endif

