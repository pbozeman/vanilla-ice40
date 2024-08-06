# Todo and fixes

## PCB

### Main board

- lcsc green led is a bit dim
- add tx/rx to breakout
- remove 3v3 and 1v2 voltage breakouts
- consider signal only option to use ice boards together

### PMOD board

- make font bigger
- move pmods slightly over the edge of the pcb

### tri sram

- the vga addr buffer likely doesn't need a latch and we
  might be able to drop to just a buffer

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
