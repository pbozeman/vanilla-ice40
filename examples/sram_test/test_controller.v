// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none


// check: addr_reset may be held too long

module test_controller (
    input wire clk,
    input wire reset,
    input wire addr_done,
    input wire pattern_done,
    input wire test_fail,
    output reg read_only = 0,
    output reg next_addr = 0,
    output wire next_pattern,
    output reg test_done = 0,
    output wire enable_checker,
    output reg addr_gen_reset = 0,
    output wire pattern_gen_reset,
    output wire [2:0] test_state
);

  localparam IDLE = 3'b000;
  localparam WRITING = 3'b001;
  localparam SWITCHING_1 = 3'b010;
  localparam SWITCHING_2 = 3'b011;
  localparam READING = 3'b100;
  localparam NEXT_PATTERN = 3'b101;
  localparam DONE = 3'b110;
  localparam HALT = 3'b111;

  reg [2:0] state = 0;
  reg write_complete = 0;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= IDLE;
      read_only <= 1'b0;
      next_addr <= 1'b0;
      test_done <= 1'b0;
      write_complete <= 1'b0;
      addr_gen_reset <= 1'b1;
    end else begin
      case (state)
        IDLE: begin
          state <= WRITING;
          read_only <= 1'b0;
          next_addr <= 1'b1;
          write_complete <= 1'b0;
          test_done <= 1'b0;
          addr_gen_reset <= 1'b0;
        end
        WRITING: begin
          read_only <= 1'b0;
          if (addr_done && !write_complete) begin
            write_complete <= 1'b1;
            read_only <= 1'b1;
            next_addr <= 1'b0;
            addr_gen_reset <= 1'b1;
            state <= SWITCHING_1;
          end else begin
            addr_gen_reset <= 1'b0;
            next_addr <= 1'b1;
          end
        end
        SWITCHING_1: begin
          addr_gen_reset <= 1'b0;
          read_only <= 1'b1;
          next_addr <= 1'b0;
          state <= SWITCHING_2;
        end
        SWITCHING_2: begin
          addr_gen_reset <= 1'b0;
          read_only <= 1'b1;
          next_addr <= 1'b1;
          state <= READING;
        end
        READING: begin
          if (test_fail) begin
            state <= HALT;
            next_addr <= 1'b0;
          end else if (addr_done) begin
            if (pattern_done) begin
              state <= DONE;
            end else begin
              addr_gen_reset <= 1'b1;
              read_only <= 1'b0;
              state <= NEXT_PATTERN;
            end
            next_addr <= 1'b1;
          end else begin
            next_addr <= 1'b1;
          end
        end
        NEXT_PATTERN: begin
          state <= WRITING;
          read_only <= 1'b0;
          write_complete <= 1'b0;
          addr_gen_reset <= 1'b1;
        end
        DONE: begin
          addr_gen_reset <= 1'b1;
          test_done <= 1'b1;
          state <= IDLE;
        end
        HALT: begin
          next_addr <= 1'b0;
          test_done <= 1'b1;
          // Stay in HALT state until reset
        end
        default: state <= IDLE;
      endcase
    end
  end

  assign next_pattern = (state == NEXT_PATTERN);
  assign enable_checker = (state == READING);
  assign pattern_gen_reset = (reset || state == DONE);

endmodule
