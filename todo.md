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

### make

- add yosys compilation
- make: all files are included in both yosys and verification.. limit them to just
  the dependencies
- move to per top pcf files

### misc

- make sure all components have a reset_i
- create reset component and use in top modules
- redo nets without mirroring
- standardize wave output names

### sram

- the sram tester is a total mess.. clean it up. I just kept beating on output
  from Claude.ai. I likely would have been better at just doing this myself.

### uart

- add tests

### fifo

- maybe add an "almost full" as it's hard to manage right
  at the boundary of being full
