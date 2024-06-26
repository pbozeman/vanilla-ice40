# Vanilla Ice40

Hardware design and verilog sample files for Lattice ice40 HX4K
development board.

## Development boards

The core board is modular and breaks out 96 of the ice40 io
pins to mezzanine connector. This enables design of expansion
prototype PCBs, reusing the main development board. The expansion
PCBs can be daisy chained.

This is a work in progress for a project I'm doing, but so far the
following boards are in the repo:

* vanilla-ice40: core board with USBC connector for power,
programming, and uart/com port communication. It is
directly programmable with Lattice Diamond Programmer. The
onboard FTDI chip can be disabled, and the SPI pins to the
flash and ice40 are exposed if one wishes to use an external
programmer.

* breakout-sram: 16Mbit sram chip with with mezzanine connectors
on both side of the board for pass through of unused pins.

* breakout-pmod: 12 port pmod connector, spaced such that they
can be used in single, dual or quad pmod configurations.

* breakout-passthrough: direct passthrough of all signals. (This
is basically a template and for testing.)

Parts numbers are populated for Digikey and JLCPCB, and JLCPCB
rotations are provided. The bom and positions file, along with
gerbers, can be exported with the JLCPCB Fabrication Toolkit
plugin.

## Verilog examples

Basic verilog examples. Icecube2 projects exist in lattice_proj.

Test benches run under iverilog by running `make check` to run
all test benches. Wave files are written
to `.build/<test_name>.vcd` and can be viewed with gtkwave.

Diamond Programmer does not use relative paths, so programmer
projects are not checked in.
