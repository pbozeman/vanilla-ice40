# Vanilla ICE40

Hardware design and verilog sample files for Lattice ICE40
development boards and expansion boards.

![Vanilla ICE40 ecosystem](images/ecosystem.png?raw=true "vanilla ice40 ecosystem")

## Development Boards

There are 2 core boards, one based on an ICE40 HX4K with 96
available IO pins, and another based on an ICE40 HX8K with
192 available IO pins.

The core boards are "vanilla" with minimal on board peripherals.
Almost all IO pins are routed to mezzanine connectors. Expansion
boards can be mixed and matched for different projects, while reusing
the core board. The expansion boards can be daisy chained.

This is a work in progress for use in a personal project, but so far
the following boards are in the repo:

* **vanilla-ice40**: core board based on the HX4K TQ144 package. There is
an onboard USBC connector for power, programming, and uart/com port
communication. It is directly programmable with Lattice Diamond Programmer
and icestorm. The onboard FTDI chip can be disabled. The SPI pins to the
flash and ice40 are exposed if one wishes to use an external
programmer. There are 2 onboard user LEDs, 1 I2C connector, and 96 IOs
routed to a mezzanine connector on the right side of the board.

* **vanilla-ice40-hx8k**: core board based on the HX8K CT256 BGA package.
It is similar to the board above, but ads a user button on board. It has
192 available IO pins, with 96 IO pins routed to the left and 96 pins routed
to the right of the board. (A PCF file is provided for both boards, sharing
the same signal names for the right side of the board.)

* **breakout-sram**: 16Mbit sram chip with with mezzanine connectors
on both side of the board for pass through of unused pins.

* **breakout-pmod**: 12 port pmod connector, spaced such that they
can be used in single, dual or quad pmod configurations.

* **breakout-passthrough**: direct passthrough of all signals. (This
is basically a template and for testing.) NOTE: the net names and
labels on this board are stale.

Parts numbers are populated for Digikey and JLCPCB, and JLCPCB
rotations are provided. The bom and positions file, along with
gerbers, can be exported with the JLCPCB Fabrication Toolkit
plugin.

All boards other than the HX8K are single sided and optimized for cost
and hand assembly. My soldering skills are below average, and I manged to
hand assemble versions of each of these these boards other than the HX8K.
The HX8K uses BGA, via-in-pad, and 201 sized caps between the BGA pads, and
likely requires higher soldering skills.

## Verilog examples

Basic verilog examples. Icecube2 projects exist in lattice_proj.

Test benches run under iverilog by running `make check` to run
all test benches. Wave files are written
to `.build/<test_name>.vcd` and can be viewed with gtkwave.

Diamond Programmer does not use relative paths, so programmer
projects are not checked in.

### NOTE

I have been doing all recent development icestorm toolchain, so the Icecube2
projects are stale. I have heard that yosys/nextprn don't scale to larger designs,
but for now, they are able to complete synthesis and place-and-route for all
the examples before Icecube2 can synthesize a single project. That coupled with
the ability to compile and program from the command line is so delightful compared
to Icecube2.

## Makefile Targets

The Makefile in the rtl dir works for both hx4k and hx8k boards, but
one needs to change the DEVICE and PACKAGE at the top of the file based on
the board in use.

* **unit**: runs unit tests for any changed files. This is the default
target if one is not specified. vcd files are written to .build/\<name\>_tb.vcd

* **list**: provides a listing of unit test and programming targets

* **\<name\>_tb**: runs the test bench named 'name'

* **\<name\>_top**: builds the bitstream for 'name' and programs the attached board
with the bitstream.

* **lint**: runs verilator on all _tb files and their includes.

* **format**: runs verible source code formatter on all verilog files.

* **check**: runs linter and full unit test suite, even if files have not changed.

* **bits**: build bitstreams for all top level files.
