`define ASSERT(condition) \
  if (!(condition)) begin \
    $display("ASSERTION FAILURE: %s:%0d", `__FILE__, `__LINE__); \
    #5; \
    $fatal; \
  end
