# Todo and fixes

## PCB

### All

- consider redoing the pins on the P b2b connector to match S.
- audit and standardize R manufacturer. Used to be bournes,
  but the need for 0.1% tolerance from the same vendor at both
  digikey and lcsc meant using Yaego. (Not that multivendor is
  bad, but I find single vendor to be more ascetically pleasing :)

### Main board

- lcsc green led is a bit dim
- validate i2c
- validate urx/utx
- validate all passive silk screen positions
- bump font sizes
- remove 3v3 and 1v2 voltage breakouts
- consider signal only option to use ice boards together
- should OE enable on the oscillator use a 1K+ resistor instead of 0R?
- move the resistors for the LEDs to the top of the board. They made good
  test points, and testing at the led doesn't work as well.

### ADC board

- X1 is a default kicad symbol and footprint. I added a pin 1 marker, but
  accidentally did so to the system footprint. Duplicate the symbol as a custom
  symbol and fix the datasheet and footprint correctly.

### PMOD board

- make font bigger
- move pmods slightly over the edge of the pcb
- add mounting holes

### Pass through

- update with current board tolerances and sizes (e.g. vias are off)

### SRAM

- add mounting holes
- lower pcb fence vias violate drc tolerances

## RTL

### Project structure

- rename examples to rtl
- start moving modules into groups directories in lib
- move unit tests with the lib

### make

- make: all files are included in both yosys and verification.. limit them to just
  the dependencies
- move to per top pcf files
- there are some assumptions of running from the rtl/examples dir, e.g.
  the pcf gen rules. update the makefile to be cwd agnostic
- consider removing pcf files from being committed to the repo

### misc

- make sure all components have a reset_i
- create reset component and use in top modules

### uart

- add tests

### fifo

- maybe add an "almost full" as it's hard to manage right
  at the boundary of being full

### SRAM

change the sram data and addr ports to use _bus and/or differentiate the caller ports from the
io on the board

### SRAM VGA

- don't read memory during the blanking period
- use vga_pixel_addr, or at least the counter module. There was a wrapping
  error in the manual iteration that wouldn't have happened if these were used.

### Style

- move to system verilog, but decide on what conventions to use
- rename _controller to_ctrl
- use initial_reset in top modules
- use TICK in unit tests
- use ASSERT_EQ in unit tests where applicable
- switch to axi stream for flow control in relevant modules
- move to standardized module instantiation names
- decide on standardize _WIDTH/BITS parameter names
