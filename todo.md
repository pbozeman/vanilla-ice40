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
