`ifndef SRAM_TESTER_V
`define SRAM_TESTER_V

`include "directives.v"

`include "delay.v"
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
    output wire test_done,
    output reg  test_pass = 0,

    // debug/output signals
    output wire [          2:0] pattern_state,
    output reg  [DATA_BITS-1:0] prev_read_data,
    output reg  [DATA_BITS-1:0] prev_expected_data,

    // sram controller signals
    output wire                 sram_write_enable,
    output wire [ADDR_BITS-1:0] sram_addr,
    output wire [DATA_BITS-1:0] sram_write_data,
    output wire [DATA_BITS-1:0] sram_read_data,

    // sram controller to io pins
    output wire [ADDR_BITS-1:0] sram_io_addr_bus,
    inout  wire [DATA_BITS-1:0] sram_io_data_bus,
    output wire                 sram_io_we_n,
    output wire                 sram_io_oe_n,
    output wire                 sram_io_ce_n
);

  // State definitions
  localparam [2:0] START = 3'b000;
  localparam [2:0] WRITING = 3'b001;
  localparam [2:0] WRITE_HOLD = 3'b010;
  localparam [2:0] READING = 3'b011;
  localparam [2:0] READ_HOLD = 3'b100;
  localparam [2:0] DONE = 3'b110;
  localparam [2:0] HALT = 3'b111;

  // State and next state registers
  reg  [          2:0] state;
  reg  [          2:0] next_state;

  // Other registers
  reg                  addr_inc;
  reg                  last_write;
  reg                  last_read;
  reg                  pattern_inc;
  reg  [DATA_BITS-1:0] pattern_prev;
  reg  [DATA_BITS-1:0] pattern_custom;
  reg                  validate = 0;

  // Wires
  wire                 req;
  // verilator lint_off UNUSEDSIGNAL
  wire                 ready;
  wire                 sram_read_data_valid;
  // verilator lint_on UNUSEDSIGNAL
  wire                 addr_done;
  wire                 pattern_reset;
  wire                 pattern_done;
  wire [DATA_BITS-1:0] pattern;

  // Submodule instantiations
  sram_controller #(
      .ADDR_BITS(ADDR_BITS),
      .DATA_BITS(DATA_BITS)
  ) sram_ctrl (
      .clk            (clk),
      .reset          (reset),
      .req            (req),
      .ready          (ready),
      .addr           (sram_addr),
      .write_enable   (sram_write_enable),
      .write_data     (sram_write_data),
      .read_data      (sram_read_data),
      .read_data_valid(sram_read_data_valid),
      .io_addr_bus    (sram_io_addr_bus),
      .io_we_n        (sram_io_we_n),
      .io_oe_n        (sram_io_oe_n),
      .io_data_bus    (sram_io_data_bus),
      .io_ce_n        (sram_io_ce_n)
  );

  iter #(
      .MAX_VALUE((1 << ADDR_BITS) - 1)
  ) addr_gen (
      .clk  (clk),
      .reset(reset),
      .inc  (addr_inc),
      .val  (sram_addr),
      .done (addr_done)
  );

  sram_pattern_generator #(
      .DATA_BITS(DATA_BITS)
  ) pattern_gen (
      .clk    (clk),
      .reset  (pattern_reset),
      .inc    (pattern_inc),
      .custom (pattern_custom),
      .pattern(pattern),
      .done   (pattern_done),
      .state  (pattern_state)
  );

  // Combinational logic process
  //
  // TODO: reduce to just the state machine
  always @(*) begin
    // Default assignments
    next_state     = state;
    pattern_custom = sram_addr;

    if (!reset) begin
      case (state)
        START: begin
          next_state = WRITING;
        end

        WRITING: begin
          next_state = WRITE_HOLD;
        end

        WRITE_HOLD: begin
          if (last_write) begin
            next_state = READING;
          end else begin
            next_state = WRITING;
          end
        end

        READING: begin
          next_state = READ_HOLD;
        end

        READ_HOLD: begin
          if (last_read) begin
            if (pattern_done) begin
              next_state = DONE;
            end else begin
              next_state = WRITING;
            end
          end else begin
            next_state = READING;
          end
        end

        DONE: begin
          next_state = START;
        end

        HALT: begin
          // No state change
        end

        default: begin
          next_state = START;
        end
      endcase
    end
  end

  // state registration
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= START;
    end else begin
      if (test_pass) begin
        state <= next_state;
      end else begin
        state <= HALT;
      end
    end
  end

  // each of the states gets its own block to help
  // meet timing. I wouldn't think this would help
  // compared to
  //   if (a) .... ;
  //   if (b) .... ;
  // as long as 'a' and 'b' are independent,
  // e.g. different states. I would have thought
  // they would be automatically done in parallel,
  // but this didn't seem to be the case.
  //
  // Maybe a case statement would work too.

  // state == WRITING
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      last_write <= 1'b0;
    end else begin
      if (state == WRITING) begin
        last_write <= addr_done;
      end
    end
  end

  // TODO: these delays are so janky and are a symptom
  // of poor design of the read/validation logic.
  //
  // TODO: Also, use ready signal instead of manual cycles
  delay #(
      .DELAY_CYCLES(3),
      .WIDTH       (DATA_BITS)
  ) prev_delay (
      .clk(clk),
      .in (pattern_prev),
      .out(prev_expected_data)
  );

  reg validate_delay;

  delay #(
      .DELAY_CYCLES(1)
  ) u_validate_delay (
      .clk(clk),
      .in (validate),
      .out(validate_delay)
  );

  // last_read registration (state == READ_HOLD)
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      last_read      <= 1'b0;
      prev_read_data <= {DATA_BITS{1'b0}};
    end else begin
      prev_read_data <= sram_read_data;
      if (state == READ_HOLD) begin
        last_read <= addr_done;
      end
    end
  end

  // addr_inc
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      addr_inc <= 1'b0;
    end else begin
      addr_inc <= (next_state == WRITING || next_state == READING);
    end
  end

  // validation flag
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      validate <= 1'b0;
    end else begin
      validate <= (state == READ_HOLD);
    end
  end

  // test_pass validation
  // (pipelined to meet timing)
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      test_pass <= 1'b1;
    end else begin
      if (validate_delay) begin
        if (prev_read_data != prev_expected_data) begin
          test_pass <= 1'b0;
        end
      end
    end
  end

  // pattern_inc
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      pattern_inc <= 1'b0;
    end else begin
      pattern_inc <= (state == READ_HOLD && addr_done);
    end
  end

  // pattern_prev
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      pattern_prev <= 1'b0;
    end else begin
      pattern_prev <= pattern;
    end
  end

  // Continuous assignments
  assign req = next_state == WRITING || next_state == READING;
  assign
      sram_write_enable = (next_state == WRITING || next_state == WRITE_HOLD);
  assign pattern_reset = (reset || state == DONE);

  assign sram_write_data = pattern;
  assign test_done = (state == DONE);

endmodule

`endif
