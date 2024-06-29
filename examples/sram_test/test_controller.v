// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module test_controller (
    input  wire clk,
    input  wire reset,
    input  wire addr_done,
    input  wire pattern_done,
    output reg  read_only,
    output reg  next_addr,
    output reg  next_pattern,
    output reg  test_done,
    output wire enable_checker,
    output wire addr_gen_reset
);

  localparam IDLE = 3'b000;
  localparam WRITING = 3'b001;
  localparam SWITCHING = 3'b010;
  localparam READING = 3'b011;
  localparam NEXT_PATTERN = 3'b100;
  localparam DONE = 3'b101;

  reg [2:0] state;
  reg write_complete;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= IDLE;
      read_only <= 1'b0;
      next_addr <= 1'b0;
      next_pattern <= 1'b0;
      test_done <= 1'b0;
      write_complete <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          state <= WRITING;
          read_only <= 1'b0;
          next_addr <= 1'b1;
          write_complete <= 1'b0;
          next_pattern <= 1'b0;
        end
        WRITING: begin
          next_pattern <= 1'b0;
          read_only <= 1'b0;
          if (addr_done && !write_complete) begin
            write_complete <= 1'b1;
            read_only <= 1'b1;
            next_addr <= 1'b1;
            state <= SWITCHING;
          end else begin
            next_addr <= 1'b1;
          end
        end
        SWITCHING: begin
          read_only <= 1'b1;
          next_pattern <= 1'b0;
          state <= READING;
        end
        READING: begin
          next_pattern <= 1'b0;
          if (addr_done) begin
            if (pattern_done) begin
              state <= DONE;
            end else begin
              state <= NEXT_PATTERN;
            end
            next_addr <= 1'b0;
          end else begin
            next_addr <= 1'b1;
          end
        end
        NEXT_PATTERN: begin
          next_pattern <= 1'b1;
          state <= WRITING;
          read_only <= 1'b0;
          write_complete <= 1'b0;
        end
        DONE: begin
          next_pattern <= 1'b0;
          test_done <= 1'b1;
        end
        default: state <= IDLE;
      endcase
    end
  end

  assign enable_checker = (state == READING);
  assign addr_gen_reset = (reset || state == SWITCHING || state == NEXT_PATTERN);

endmodule
