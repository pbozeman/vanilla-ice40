# Todo and fixes

## PCB

### All

- review FB specs
- review b2b footprints and polarity

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

- add zone fill keepouts under Rg, Rf, and Op amps per the data sheet
- check resistor array footprint pad sizes

### PMOD board

- make font bigger
- move pmods slightly over the edge of the pcb
- add mounting holes

### SRAM

- add mounting holes

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
