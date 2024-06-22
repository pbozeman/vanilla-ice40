`define ASSERT(condition) \
  if (!(condition)) begin \
    $display("ASSERTION FAILURE: %s:%0d", `__FILE__, `__LINE__); \
    $fatal; \
  end
