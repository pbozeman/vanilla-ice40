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
    output reg  test_pass = 0,

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

  // State definitions
  localparam [2:0]
        START = 3'b000,
        WRITING = 3'b001,
        WRITE_HOLD = 3'b010,
        READING = 3'b011,
        READ_HOLD = 3'b100,
        DONE = 3'b110,
        HALT = 3'b111;

  // State and next state registers
  reg [2:0] state;
  reg [2:0] next_state;

  // Other registers
  reg req;
  reg addr_reset;
  reg addr_next;
  reg last_write;
  reg last_read;
  reg pattern_next;
  reg [DATA_BITS-1:0] pattern_custom;
  reg validate = 0;

  // Wires
  wire ready;
  wire addr_done;
  wire pattern_reset;
  wire pattern_done;
  wire [DATA_BITS-1:0] pattern;

  // Submodule instantiations
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

  // Combinational logic process
  always @(*) begin
    // Default assignments
    next_state = state;
    req = 1'b0;
    addr_reset = 1'b0;
    addr_next = 1'b0;
    pattern_next = 1'b0;
    test_done = 1'b0;
    pattern_custom = addr;

    case (state)
      START: begin
        req = 1'b1;
        addr_reset = 1'b0;
        next_state = WRITING;
      end

      WRITING: begin
        addr_next  = 1'b1;
        next_state = WRITE_HOLD;
      end

      WRITE_HOLD: begin
        if (last_write) begin
          addr_reset = 1'b1;
          next_state = READING;
        end else begin
          next_state = WRITING;
        end
      end

      READING: begin
        addr_next  = 1'b1;
        next_state = READ_HOLD;
      end

      READ_HOLD: begin
        if (last_read) begin
          if (pattern_done) begin
            next_state = DONE;
          end else begin
            pattern_next = 1'b1;
            addr_reset   = 1'b1;
            next_state   = WRITING;
          end
        end else begin
          next_state = READING;
        end
      end

      DONE: begin
        test_done  = 1'b1;
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

  // state == READING
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      last_read <= 1'b0;
    end else begin
      if (state == READING) begin
        last_read <= addr_done;
      end
    end
  end

  // state == READ_HOLD
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      test_pass <= 1'b1;
      prev_read_data <= {DATA_BITS{1'b0}};
      prev_expected_data <= {DATA_BITS{1'b0}};
    end else begin
      if (state == READ_HOLD) begin
        // pipeline the validation to meet timing
        validate <= 1'b1;
        prev_read_data <= read_data;
        prev_expected_data <= pattern;
      end
    end
  end

  // test_pass validation
  // (pipelined to meet timing)
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      validate  <= 1'b0;
      test_pass <= 1'b1;
    end else begin
      if (validate) begin
        if (read_data != pattern) begin
          test_pass <= 1'b0;
        end
      end
    end
  end

  // Continuous assignments
  assign write_enable = ((state == START || state == DONE ||
                            state == WRITING || state == WRITE_HOLD)
                            && ~last_write);
  assign pattern_reset = (reset || state == DONE);
  assign write_data = pattern;

endmodule

`endif
