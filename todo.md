# Todo and fixes

## PCB

### All

- consider redoing the pins on the P b2b connector to match S.

### Main board

- lcsc green led is a bit dim
- validate i2c
- validate urx/utx
- validate all passive silk screen positions
- bump font sizes
- remove 3v3 and 1v2 voltage breakouts
- consider signal only option to use ice boards together
- should OE enable on the oscillator use a 1K+ resistor instead of 0R?

### ADC board

- check resistor array footprint pad sizes
- add fence vias around the edge of the pcb

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

### make

- add yosys compilation
- make: all files are included in both yosys and verification.. limit them to just
  the dependencies
- move to per top pcf files

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
