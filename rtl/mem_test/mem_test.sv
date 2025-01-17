`ifndef MEM_TEST_V
`define MEM_TEST_V

`include "sticky_bit.sv"
`include "axi_sram_controller.sv"

// verilator lint_off: UNDRIVEN
module mem_test #(
    parameter integer ADDR_BITS = 20,
    parameter integer DATA_BITS = 16
) (
    // tester signals
    input logic clk,
    input logic reset,

    output logic test_done,
    output logic test_pass,

    // debug/output signals
    output logic [7:0] debug0,
    output logic [7:0] debug1,

    // sram controller to io pins
    output logic [ADDR_BITS-1:0] sram_io_addr,
    inout  wire  [DATA_BITS-1:0] sram_io_data,
    output logic                 sram_io_we_n,
    output logic                 sram_io_oe_n,
    output logic                 sram_io_ce_n
);
  localparam IO_CNT_MAX = 7;
  localparam IO_CNT_WIDTH = $clog2(IO_CNT_MAX);

  typedef enum {
    STATE_IDLE,
    STATE_DATA,
    STATE_DONE,
    STATE_FAIL
  } state_t;

  logic   [        ADDR_BITS-1:0] m_axi_awaddr;
  logic                           m_axi_awvalid;
  logic                           m_axi_awready;
  logic   [        DATA_BITS-1:0] m_axi_wdata;
  logic   [((DATA_BITS+7)/8)-1:0] m_axi_wstrb;
  logic                           m_axi_wvalid;
  logic                           m_axi_wready;
  logic   [                  1:0] m_axi_bresp;
  logic                           m_axi_bvalid;
  logic                           m_axi_bready;
  logic   [        ADDR_BITS-1:0] m_axi_araddr;
  logic                           m_axi_arvalid;
  logic                           m_axi_arready;
  logic   [        DATA_BITS-1:0] m_axi_rdata;
  logic   [                  1:0] m_axi_rresp;
  logic                           m_axi_rvalid;
  logic                           m_axi_rready;

  state_t                         w_state;
  state_t                         w_state_next;

  logic   [     IO_CNT_WIDTH-1:0] w_io_cnt;
  logic   [     IO_CNT_WIDTH-1:0] w_io_cnt_next;

  logic                           m_axi_awvalid_next;
  logic   [        ADDR_BITS-1:0] m_axi_awaddr_next;

  logic                           m_axi_wvalid_next;
  logic   [        DATA_BITS-1:0] m_axi_wdata_next;

  logic                           r_enable;
  logic                           r_enable_next;

  state_t                         r_state;
  state_t                         r_state_next;

  logic   [     IO_CNT_WIDTH-1:0] ra_io_cnt;
  logic   [     IO_CNT_WIDTH-1:0] ra_io_cnt_next;

  logic   [     IO_CNT_WIDTH-1:0] r_io_cnt;
  logic   [     IO_CNT_WIDTH-1:0] r_io_cnt_next;

  logic   [        DATA_BITS-1:0] r_data_expected;

  logic                           m_axi_arvalid_next;
  logic   [        ADDR_BITS-1:0] m_axi_araddr_next;

  axi_sram_controller #(
      .AXI_ADDR_WIDTH(ADDR_BITS),
      .AXI_DATA_WIDTH(DATA_BITS)
  ) ctrl (
      .axi_clk     (clk),
      .axi_resetn  (~reset),
      .axi_awaddr  (m_axi_awaddr),
      .axi_awvalid (m_axi_awvalid),
      .axi_awready (m_axi_awready),
      .axi_wdata   (m_axi_wdata),
      .axi_wstrb   (m_axi_wstrb),
      .axi_wvalid  (m_axi_wvalid),
      .axi_wready  (m_axi_wready),
      .axi_bresp   (m_axi_bresp),
      .axi_bvalid  (m_axi_bvalid),
      .axi_bready  (m_axi_bready),
      .axi_araddr  (m_axi_araddr),
      .axi_arvalid (m_axi_arvalid),
      .axi_arready (m_axi_arready),
      .axi_rdata   (m_axi_rdata),
      .axi_rresp   (m_axi_rresp),
      .axi_rvalid  (m_axi_rvalid),
      .axi_rready  (m_axi_rready),
      .sram_io_addr(sram_io_addr),
      .sram_io_data(sram_io_data),
      .sram_io_we_n(sram_io_we_n),
      .sram_io_oe_n(sram_io_oe_n),
      .sram_io_ce_n(sram_io_ce_n)
  );

  //
  // Write state machine
  //

  assign m_axi_wstrb  = '1;
  assign m_axi_bready = 1'b1;

  logic write_addr_accepted;
  logic write_data_accepted;
  logic write_accepted;

  sticky_bit sticky_awdone (
      .clk  (clk),
      .reset(reset),
      .in   (m_axi_awvalid && m_axi_awready),
      .out  (write_addr_accepted),
      .clear(write_accepted)
  );

  sticky_bit sticky_wdone (
      .clk  (clk),
      .reset(reset),
      .in   (m_axi_wvalid && m_axi_wready),
      .out  (write_data_accepted),
      .clear(write_accepted)
  );

  always_comb begin
    w_state_next       = w_state;

    m_axi_awaddr_next  = m_axi_awaddr;
    m_axi_awvalid_next = m_axi_awvalid && !m_axi_awready;
    m_axi_wvalid_next  = m_axi_wvalid && !m_axi_wready;
    m_axi_wdata_next   = m_axi_wdata;

    w_io_cnt_next      = w_io_cnt;
    r_enable_next      = r_enable;

    write_accepted     = 1'b0;

    case (w_state)
      STATE_IDLE: begin
        w_state_next       = STATE_DATA;
        m_axi_awvalid_next = 1'b1;
        m_axi_awaddr_next  = (ADDR_BITS'(8'hA0) + ADDR_BITS'(w_io_cnt));

        m_axi_wvalid_next  = 1'b1;
        m_axi_wdata_next   = (DATA_BITS'(8'hD0) + DATA_BITS'(w_io_cnt));

        w_io_cnt_next      = w_io_cnt + 1;
      end

      STATE_DATA: begin
        if (write_addr_accepted && write_data_accepted) begin
          write_accepted = 1'b1;

          if (w_io_cnt != IO_CNT_WIDTH'(IO_CNT_MAX)) begin
            w_state_next       = STATE_DATA;
            m_axi_awvalid_next = 1'b1;
            m_axi_awaddr_next  = (ADDR_BITS'(8'hA0) + ADDR_BITS'(w_io_cnt));

            m_axi_wvalid_next  = 1'b1;
            m_axi_wdata_next   = (DATA_BITS'(8'hD0) + DATA_BITS'(w_io_cnt));

            w_io_cnt_next      = w_io_cnt + 1;
          end else begin
            r_enable_next = 1'b1;
            w_state_next  = STATE_DONE;
          end
        end
      end

      STATE_DONE: begin
      end

      STATE_FAIL: begin
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      w_state       <= STATE_IDLE;
      w_io_cnt      <= 0;
      m_axi_awvalid <= 1'b0;
      m_axi_wvalid  <= 1'b0;

      r_enable      <= 1'b0;
    end else begin
      w_state       <= w_state_next;
      w_io_cnt      <= w_io_cnt_next;

      m_axi_awaddr  <= m_axi_awaddr_next;
      m_axi_awvalid <= m_axi_awvalid_next;

      m_axi_wvalid  <= m_axi_wvalid_next;
      m_axi_wdata   <= m_axi_wdata_next;

      r_enable      <= r_enable_next;
    end
  end

  //
  // Read state machine
  //

  assign m_axi_rready    = 1'b1;

  assign r_data_expected = (DATA_BITS'(8'hD0) + DATA_BITS'(r_io_cnt));

  always_comb begin
    r_state_next       = r_state;

    ra_io_cnt_next     = ra_io_cnt;
    r_io_cnt_next      = r_io_cnt;

    m_axi_araddr_next  = m_axi_araddr;
    m_axi_arvalid_next = m_axi_arvalid && !m_axi_arready;

    test_done          = 1'b0;
    test_pass          = 1'b1;

    case (r_state)
      STATE_IDLE: begin
        if (r_enable) begin
          m_axi_araddr_next  = (ADDR_BITS'(8'hA0) + ADDR_BITS'(r_io_cnt));
          m_axi_arvalid_next = 1'b1;
          ra_io_cnt_next     = ra_io_cnt + 1;
          r_state_next       = STATE_DATA;
        end
      end

      STATE_DATA: begin
        if (!m_axi_arvalid || m_axi_arready) begin
          if (ra_io_cnt != IO_CNT_WIDTH'(IO_CNT_MAX)) begin
            m_axi_araddr_next  = (ADDR_BITS'(8'hA0) + ADDR_BITS'(ra_io_cnt));
            m_axi_arvalid_next = 1'b1;
            ra_io_cnt_next     = ra_io_cnt + 1;
          end
        end

        if (m_axi_rvalid && m_axi_rready) begin
          if (m_axi_rdata != r_data_expected) begin
            r_state_next = STATE_FAIL;
          end else begin
            r_io_cnt_next = r_io_cnt + 1;
            if (r_io_cnt_next == IO_CNT_WIDTH'(IO_CNT_MAX)) begin
              r_state_next = STATE_DONE;
            end
          end
        end
      end

      STATE_DONE: begin
        test_done = 1'b1;
      end

      STATE_FAIL: begin
        test_pass = 1'b0;
      end
    endcase


  end

  always_ff @(posedge clk) begin
    if (reset) begin
      r_state       <= STATE_IDLE;
      r_io_cnt      <= 0;
      ra_io_cnt     <= 0;

      m_axi_arvalid <= 1'b0;
    end else begin
      r_state       <= r_state_next;
      r_io_cnt      <= r_io_cnt_next;
      ra_io_cnt     <= ra_io_cnt_next;

      m_axi_araddr  <= m_axi_araddr_next;
      m_axi_arvalid <= m_axi_arvalid_next;
    end
  end

  assign debug0 = 0;
  assign debug1 = 0;

endmodule

`endif
