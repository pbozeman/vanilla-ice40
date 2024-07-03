`ifndef TESTING_V
`define TESTING_V

`include "directives.v"

`define ASSERT(condition) \
  if (!(condition)) begin \
    $display("ASSERTION FAILURE: %s:%0d", `__FILE__, `__LINE__); \
    #5; \
    $fatal; \
  end

`define TEST_SETUP(mod)                       \
   initial begin                              \
     $dumpfile({".build/", `"mod`", ".vcd"}); \
     $dumpvars(0, mod);                       \
   end                                        \
                                              \
   // 10ns period clock                       \
   initial begin                              \
     clk = 0;                                 \
     forever #5 clk = ~clk;                   \
   end

`endif
