# Todo and fixes

## PCB

### Main board

- lcsc green led is a bit dim
- remove values from buttons/leds and replace with silk text
- add tx/rx to breakout
- remove 3v3 and 1v2 voltage breakouts
- add 5v power jumper or transistor
- double check tx/rx net labels. they might be backwards, or at
  least misleading, as they might be from the ftdi perspective
  and not ice40

### PMOD board

- make font bigger
- redo nets since they don't need to be mirrored

## RTL

### Project structure

- add yosys compilation
- drop _i and_o except where actually part of the name.
  The linter catches directional issues just fine, and they are cruft.

### misc

- make sure all components have a reset_i
- create reset component and use in top modules
- redo nets without mirroring

### sram

- rename rw_i. it's ambiguous

### uart

- add tests

### fifo

- maybe add an "almost full" as it's hard to manage right
  at the boundary of being full
