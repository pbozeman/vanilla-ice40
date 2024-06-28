// for simulation
`timescale 1ns / 1ps

// avoid undeclared symbols
`default_nettype none

module sram_tester_top #(
    parameter integer ADDR_BITS = 20,
    parameter integer DATA_BITS = 16
) (
    input  wire clk,
    input  wire reset,
    output wire test_done,
    output wire led1_o,
    output wire led2_o,

    // sram pins
    output wire [ADDR_BITS-1:0] SRAM_ADDR_BUS,
    inout wire [DATA_BITS-1:0] SRAM_DATA_BUS,
    output wire we_n,
    output wire oe_n,
    output wire ce_n
);

    // Internal signals
    wire [ADDR_BITS-1:0] addr;
    wire [DATA_BITS-1:0] data_write;
    wire [DATA_BITS-1:0] data_write;
    wire rw;
    wire test_pass;

    // Instantiate the sram_tester
    sram_tester #(
        .ADDR_BITS(ADDR_BITS),
        .DATA_BITS(DATA_BITS)
    ) tester (
        .clk(clk),
        .reset(reset),
        .test_done(test_done),
        .test_pass(test_pass),
        .rw(rw),
        .addr(addr),
        .data_write(data_write),
        .data_read(data_read),
        .SRAM_ADDR_BUS(SRAM_ADDR_BUS),
        .SRAM_DATA_BUS(SRAM_DATA_BUS),
        .we_n(we_n),
        .oe_n(oe_n),
        .ce_n(ce_n)
    );

    // LED1 blinks every addr reset (too fast to see, use a scope)
    assign led1_o = (addr == {ADDR_BITS{1'b0}});

    // LED2 is success
    assign led2_o = test_pass;

endmodule
