# Breakout ADC Layout Notes

## ADC

[ADC10DL065 data sheet](https://www.ti.com/lit/ds/symlink/adc10dl065.pdf)

### V reference pins

VRPA/B, VRMA/B, VMRNA/B should all share a single ground connection.
See figure 7 in the data sheet.

### DRGND
>
>The ground return for the data outputs (DR GND) carries the ground current
>for the output drivers. The output current can exhibit high transients that
>could add noise to the conversion process. To prevent this from happening,
>the DR GND pins should NOT be connected to system ground in close proximity
>to any of the ADC10DL065’s other ground pins.

### Digital output pins
>
>The effects of the noise generated from the ADC output switching can be
>minimized through the use of 100Ω resistors in series with each data output
>line. Locate these resistors as close to the ADC output pins as possible.
