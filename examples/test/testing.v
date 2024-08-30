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
   end

`define WAIT_FOR_SIGNAL(signal)      \
  begin : wait_for_sig_`__LINE__     \
    reg [8:0] cnt;                   \
    cnt = 0;                         \
    while (!(signal)) begin          \
      @(posedge axi_aclk);           \
      cnt = cnt + 1;                 \
      `ASSERT(cnt < 10);             \
    end                              \
    `ASSERT((signal) === 1'b1);      \
  end

`endif
