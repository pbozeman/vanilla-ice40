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
- FE and JI are wired backwards. They will work in the AB position,
but probably not in the mirrored BA chain.

## RTL

### Project structure

- add yosys compilation

### misc

- make sure all components have a reset_i
- create reset component and use in top modules

### uart

- add tests

### fifo

- maybe add an "almost full" as it's hard to manage right
  at the boundary of being full
