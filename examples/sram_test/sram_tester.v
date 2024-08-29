`ifndef SRAM_TESTER_V
`define SRAM_TESTER_V

`include "directives.v"

`include "iter.v"
`include "sram_controller.v"
`include "sram_pattern_generator.v"

module sram_tester #(
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

    // sram controller signals
    output wire write_enable,
    output wire [ADDR_BITS-1:0] addr,
    output wire [DATA_BITS-1:0] write_data,
    output wire [DATA_BITS-1:0] read_data,

    // sram controller to io pins
    output wire [ADDR_BITS-1:0] addr_bus,
    inout wire [DATA_BITS-1:0] data_bus,
    output wire we_n,
    output wire oe_n,
    output wire ce_n
);

  reg  req = 0;
  wire ready;

  // Sram controller
  sram_controller #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) sram_ctrl (
      .clk(clk),
      .reset(reset),
      .req(req),
      .ready(ready),
      .addr(addr),
      .write_enable(write_enable),
      .write_data(write_data),
      .read_data(read_data),
      .addr_bus(addr_bus),
      .we_n(we_n),
      .oe_n(oe_n),
      .data_bus_io(data_bus),
      .ce_n(ce_n)
  );

  // Address generator signals
  reg addr_reset;
  reg addr_next;
  wire addr_done;

  reg last_write;
  reg last_read;

  // Pattern generator signals
  wire pattern_reset;
  reg pattern_next;
  wire pattern_done;
  wire [DATA_BITS-1:0] pattern;
  reg [DATA_BITS-1:0] pattern_custom;

  // Address generation
  iter #(
      .MAX_VALUE((1 << ADDR_BITS) - 1)
  ) addr_gen (
      .clk  (clk),
      .reset(addr_reset),
      .next (addr_next),
      .val  (addr),
      .done (addr_done)
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

  always @(posedge clk) begin
    if (state == WRITE_HOLD || state == READ_HOLD) begin
      pattern_custom <= addr;
    end
  end

  // State definitions
  localparam [2:0]
    START = 3'b000,
    WRITING = 3'b001,
    WRITE_HOLD = 3'b010,
    READING = 3'b011,
    READ_HOLD = 3'b100,
    DONE = 3'b110,
    HALT = 3'b111;

  reg [ 2:0] state = START;

  reg [31:0] count = 0;

  assign write_enable = ((state == START || state == DONE ||
                          state == WRITING || state == WRITE_HOLD)
                          && ~last_write);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= START;
      addr_reset <= 1'b1;
      test_done <= 1'b0;
      test_pass <= 1'b1;
      addr_next <= 1'b0;
      last_write <= 1'b0;
    end else begin
      pattern_next <= 1'b0;

      case (state)
        START: begin
          req <= 1'b1;
          addr_reset <= 1'b0;
          test_done <= 1'b0;
          last_write <= 1'b0;
          state <= WRITING;
        end

        WRITING: begin
          last_write <= addr_done;
          addr_reset <= 1'b0;
          addr_next <= 1'b1;
          state <= WRITE_HOLD;
        end

        WRITE_HOLD: begin
          addr_next <= 1'b0;
          if (last_write) begin
            // start over and read data back
            last_write <= 1'b0;
            addr_reset <= 1'b1;
            state <= READING;
          end else begin
            state <= WRITING;
          end
        end

        READING: begin
          last_read <= addr_done;
          addr_reset <= 1'b0;
          addr_next <= 1'b1;
          state <= READ_HOLD;
        end

        READ_HOLD: begin
          prev_read_data <= read_data;
          prev_expected_data <= pattern;

          if (read_data != pattern) begin
            addr_next <= 1'b0;
            test_pass <= 1'b0;
            state <= HALT;
          end else begin
            if (last_read) begin
              addr_next <= 1'b0;
              if (pattern_done) begin
                state <= DONE;
              end else begin
                pattern_next <= 1'b1;
                addr_reset <= 1'b1;
                state <= WRITING;
              end

            end else begin
              addr_reset <= 1'b0;
              addr_next <= 1'b0;
              state <= READING;
            end
          end
        end

        DONE: begin
          test_done <= 1'b1;
          state <= START;
        end

        HALT: begin
          // spin
        end

        default: begin
          // should not happen
        end
      endcase

    end
  end

  assign pattern_reset = (reset || state == DONE);
  assign write_data = pattern;

endmodule

`endif
