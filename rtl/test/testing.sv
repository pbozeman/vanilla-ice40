`ifndef TESTING_V
`define TESTING_V

`include "directives.sv"

`define ASSERT(condition) \
  if (!(condition)) begin \
    $display("ASSERTION FAILURE: %s:%0d", `__FILE__, `__LINE__); \
    $fatal; \
  end

`define ASSERT_EQ(a, b) \
  if (!(a === b)) begin \
    $display("ASSERTION FAILURE: %s:%0d %d(0x%h) %d(0x%h)", `__FILE__, `__LINE__, a, a, b, b); \
    $fatal; \
  end

`define TEST_SETUP(mod)                       \
   initial begin                              \
     $dumpfile({".build/", `"mod`", ".vcd"}); \
     $dumpvars(0, mod);                       \
   end

`define TEST_SETUP_SLOW(mod)                                 \
   initial begin                                             \
     $dumpfile({".build/", `"mod`", ".vcd"});                \
     $dumpvars(5, mod);                                      \
   end                                                       \
   logic skip_slow_tests;                                    \
   initial begin                                             \
     if ($value$plusargs("SKIP_SLOW_TESTS=%b", skip_slow_tests)) begin \
       if (skip_slow_tests) begin                            \
         #10;                                                \
         $display({"SKIPPED slow tb: ", `"mod`"});           \
         $finish;                                            \
       end                                                   \
     end                                                     \
   end

`define FIXME_DISABLED_TEST_SETUP(mod)           \
   initial begin                                 \
     #10;                                        \
     $display({"FIXME DISABLED tb: ", `"mod`"}); \
     $finish;                                    \
   end                                           \

`define TICK(clk)  \
   @(posedge clk); \
   #1;

`define WAIT_FOR_SIGNAL(signal)      \
  begin : wait_for_sig_`__LINE__     \
    logic [8:0] cnt;                   \
    cnt = 0;                         \
    while (!(signal)) begin          \
      @(posedge axi_clk);            \
      cnt = cnt + 1;                 \
      `ASSERT(cnt < 20);             \
    end                              \
    `ASSERT((signal) === 1'b1);      \
  end

`endif
