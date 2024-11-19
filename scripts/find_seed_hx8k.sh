#!/bin/sh

# TODO: this was banged out quickly to find 100mhz timing on the hx8k.
# Parameterize the board, speed, etc.
#
# run this after a failed make to, hopefully, find a nextpnr seed that makes timing

# move to the rtl dir
cd $(dirname $(readlink -f $0))
cd ../rtl

# Iterate over seeds
for seed in {0..19}; do
    echo "Running nextpnr with seed $seed..."

    nextpnr-ice40 --hx8k --package ct256 --freq 100 --json .build/$1.json --pcf ../constraints/vanilla-ice40-hx8k-ct256.pcf --top $1 --seed $seed --asc .build/hx8k-ct256/$1.asc

    if [[ $? -ne 0 ]]; then
        echo "Error: nextpnr failed for seed $seed. Skipping."
        continue
    fi

    echo "Seed: $seed"
    exit 0;

done

echo "No seeds meet timing"
exit 1
