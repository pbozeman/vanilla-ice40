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

- redo silk screen numbers (they are wrong)
- make font bigger
- update schematic to match actual pinouts

## RTL

### Project structure

- update source layout
  - change to rtl dir
  - move icecube projects into a single dir
- add yosys compilation

### uart

- add tests

### fifo

- add tests
