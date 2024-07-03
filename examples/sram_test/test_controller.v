// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module test_controller (
    input wire clk,
    input wire reset,

    // our signals
    output reg test_done = 0,

    // debug signals
    output wire [2:0] test_state,

    // addr generator signals
    output reg  addr_reset = 0,
    output reg  addr_next = 0,
    input  wire addr_done,

    // pattern generator signals
    output wire pattern_reset,
    output wire pattern_next,
    input  wire pattern_done,

    // result checker signals
    output wire enable_checker,
    input  wire test_fail,

    // sram signals
    output reg sram_read_only = 0
);

  // State definitions
  localparam [2:0]
        IDLE         = 3'b000,
        WRITING      = 3'b001,
        READING      = 3'b010,
        NEXT_PATTERN = 3'b011,
        DONE         = 3'b100,
        HALT         = 3'b101;

  reg [2:0] state = IDLE;
  reg write_complete = 0;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= IDLE;
      sram_read_only <= 1'b0;
      addr_next <= 1'b0;
      test_done <= 1'b0;
      write_complete <= 1'b0;
      addr_reset <= 1'b1;
    end else begin
      addr_next  <= 1'b0;
      addr_reset <= 1'b0;

      case (state)
        IDLE: begin
          state <= WRITING;
          sram_read_only <= 1'b0;
          write_complete <= 1'b0;
          test_done <= 1'b0;
          addr_next <= 1'b1;
        end

        WRITING: begin
          sram_read_only <= 1'b0;
          if (addr_done && !write_complete) begin
            write_complete <= 1'b1;
            sram_read_only <= 1'b1;
            addr_reset <= 1'b1;
            state <= READING;
          end else begin
            addr_next <= 1'b1;
          end
        end

        READING: begin
          sram_read_only <= 1'b1;
          if (test_fail) begin
            state <= HALT;
          end else if (addr_done) begin
            if (pattern_done) begin
              state <= DONE;
            end else begin
              state <= NEXT_PATTERN;
            end
          end else begin
            addr_next <= 1'b1;
          end
        end

        NEXT_PATTERN: begin
          state <= WRITING;
          sram_read_only <= 1'b0;
          write_complete <= 1'b0;
          addr_reset <= 1'b1;
        end

        DONE: begin
          addr_reset <= 1'b1;
          test_done <= 1'b1;
          state <= IDLE;
        end

        HALT: begin
          // Stay in HALT state until reset
          test_done <= 1'b1;
        end

        default: state <= IDLE;
      endcase
    end
  end

  assign pattern_next   = (state == NEXT_PATTERN);
  assign enable_checker = (state == READING);
  assign pattern_reset  = (reset || state == DONE);
  assign test_state     = state;

endmodule
