# Breakout ADC Layout Notes

## General notes

The board is (mostly) optimized for single sided assembly.
This is to keep costs down if using getting PCB assembly
service, or to avoid needing 2 stencils for DIY stencil based
soldering. This turned out to not be possible due to the
place and routing requirements of the op amps, but the
components on the backside were kept to a minimum and should
be easily and quickly hand soldered.

## Op Amp

[lmh6551 data sheet](https://www.ti.com/lit/ds/symlink/lmh6551.pdf)

### Power and GND plane guidelines

The following quote implies that there should be a ground plane
one layer 1 for the caps to connect directly to.

>
>The SMT capacitors should be connected directly to a ground plane.
>Thin traces or small vias will reduce the effectiveness of bypass
>capacitors.

Does this quote only apply to layer1, or does it apply to the
layers below as well?

>The LMH6551 is sensitive to parasitic capacitances on the amplifier
>inputs and to a lesser extent on the outputs as well. Ground and
>power plane metal should be removed from beneath the amplifier
>and from beneath Rf and Rg.

The 2 requirements above seem impossible to satisfy with all the
components on the top of the board. I gave up on optimizing
for single sided assembly and put the feedback network and
components on the bottom of the board. Note: the reference
design has the feedback network on the opposite side of the
chip as well.

Note: there is a power trace run under Rf, that goes under a large
percentage of the pad, but there is in the reference layout also.

## ADC

[ADC10DL065 data sheet](https://www.ti.com/lit/ds/symlink/adc10dl065.pdf)

### V reference pins

VRPA/B, VRMA/B, VMRNA/B should all share a single ground connection.
See figure 7 in the data sheet.

### DRGND

Regarding the following quote, is it ok to have a GND plane on layer 2
and then just drop a via to it as long as that via is moved a bit away
from the chip? It does seem to imply that layer1 should not have a gnd
plane around the chip and that everyone should be dropping down to the
layer below? Or, should I handle the GND for these pins as a different
net in the schematic and then run a trace away from the chip and connect
it to the main gnd with something acting as a net-tie?

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
