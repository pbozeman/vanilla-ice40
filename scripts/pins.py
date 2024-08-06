#!/usr/bin/env python3

import sys

from dataclasses import dataclass

from boards import hx4k, hx8k

# This script generates pcf files for the vanilla ice peripheral boards.
#
# It is easier to transcribe the mappings for each level rather than try to
# trace all the connections back from destination to their source. It's also
# easier to audit for correctness as the lists below can be compared
# directly to the schematics.
#
# Once each layer's mapping is defined, it's relatively simple to traverse the
# dictionaries and print out pcf files.


# These 3 maps define an ice40 and its connections to the board to board
# connectors. Note: some boards, e.g. the lqfp, does not have a left
# connector.
@dataclass
class IcePinConfig:
    # logical name, e.g. IOL_1A, to physical pin,
    # e.g. E4 (for bga) or 112 for lqfp
    logical_pin_to_phys: {str, str}

    # on board signals, e.g. CLK, LED, etc.
    signals: (str, str)

    # numeric pin, e.g. 3, on the leftmost connector to logical name of the pin
    # that its connected to, e.g.: IOL_23B
    left_pin_to_logical: {int, str}

    # same format as above, but for the connector on the right of the board
    right_pin_to_logical: {int, str}


# base peripheral groups, i.e. pins in groups of 8.
peripheral_groups = [
    ("A", [3, 5, 7, 9, 4, 6, 8, 10]),
    ("B", [13, 15, 17, 19, 14, 16, 18, 20]),
    ("C", [23, 25, 27, 29, 24, 26, 28, 30]),
    ("D", [31, 33, 35, 37, 32, 34, 36, 38]),
    ("E", [63, 65, 67, 69, 64, 66, 68, 70]),
    ("F", [73, 75, 77, 79, 74, 76, 78, 80]),
    ("G", [41, 43, 45, 47, 42, 44, 46, 48]),
    ("H", [51, 53, 55, 57, 52, 54, 56, 58]),
    ("I", [91, 93, 95, 97, 92, 94, 96, 98]),
    ("J", [111, 113, 115, 117, 112, 114, 116, 118]),
    ("K", [108, 106, 104, 102, 107, 105, 103, 101]),
    ("L", [90, 88, 86, 84, 89, 87, 85, 83]),
]

# sram chip, mapped to the peripheral groups
sram_groups = [
    (
        "SRAM_ADDR_BUS",
        [
            "C[7]",
            "C[3]",
            "C[6]",
            "C[2]",
            "C[5]",
            "A[0]",
            "A[4]",
            "A[1]",
            "A[5]",
            "B[6]",
            "B[3]",
            "B[7]",
            "C[0]",
            "C[4]",
            "C[1]",
            "G[3]",
            "G[6]",
            "G[2]",
            "G[5]",
            "G[1]",
        ],
    ),
    (
        "SRAM_DATA_BUS",
        [
            "D[4]",
            "D[1]",
            "D[5]",
            "D[2]",
            "D[6]",
            "D[3]",
            "D[7]",
            "G[0]",
            "B[2]",
            "B[5]",
            "B[1]",
            "B[4]",
            "B[0]",
            "A[7]",
            "A[3]",
            "A[6]",
        ],
    ),
]

sram_signals = [("SRAM_CS_N", "D[0]"), ("SRAM_OE_N", "A[2]"), ("SRAM_WE_N", "G[4]")]


def b2b_pin_to_pin(pin):
    if pin <= 60:
        return pin + 60
    else:
        return pin - 60


def traverse(key, *dicts):
    for d in dicts:
        key = d[key]
    return key


def peripheral_pin_to_ice_pin(pin, io_dict, pin_dict):
    return traverse(b2b_pin_to_pin(pin), io_dict, pin_dict)


def peripheral_group_to_ice_group(grp, io_dict, pin_dict):
    return [peripheral_pin_to_ice_pin(p, io_dict, pin_dict) for p in grp]


def groups_to_pins(groups):
    result = []
    for name, pins in groups:
        for i, p in enumerate(pins):
            result.append((f"{name}[{i}]", p))
    return result


def ice_group_to_pcf_pin(label, pins, width=2):
    return "\n".join(
        f"set_io {label}_{i+1:0{width}} {pin}" for i, pin in enumerate(pins)
    )


def ice_group_to_pcf_array(label, pins):
    return "\n".join(f"set_io {label}[{i}] {pin}" for i, pin in enumerate(pins))


def gen_pcf_from_groups(side: str, ice_groups):
    ice_group_pins = groups_to_pins(ice_groups)

    # pmod pins
    concatenated_groups = sum([pins for _, pins in ice_groups], [])
    ice_pins = [p for p in concatenated_groups]

    base_to_p = {p[0]: p[1] for p in ice_group_pins}

    def base_group_to_ice_group(grp):
        return [base_to_p[p] for p in grp]

    # base groups
    for g in ice_groups:
        lable, pins = g
        print(ice_group_to_pcf_pin(f"{side}_{lable}", pins))
        print()
        print(ice_group_to_pcf_array(f"{side}_{lable}", pins))
        print()

    # pmod aliases
    for g in ice_groups:
        lable, pins = g
        print(ice_group_to_pcf_array(f"{side}_PMOD_{lable}", pins))
        print()

    # all pmods
    print(ice_group_to_pcf_array(f"{side}_PMOD", [p for p in ice_pins]))
    print()

    # sram
    sram_ice_groups = [(l, base_group_to_ice_group(p)) for l, p in sram_groups]

    for s, p in sram_signals:
        print(f"set_io {side}_{s} {base_to_p[p]}")

    print()
    for g in sram_ice_groups:
        lable, pins = g
        print(ice_group_to_pcf_pin(f"{side}_{lable}", pins))
        print()
        print(ice_group_to_pcf_array(f"{side}_{lable}", pins))
        print()


def gen_left_pcf(pin_config):
    ice_groups = [
        (
            l,
            peripheral_group_to_ice_group(
                g, pin_config.left_pin_to_logical, pin_config.logical_pin_to_phys
            ),
        )
        for l, g in peripheral_groups
    ]
    gen_pcf_from_groups("L", pin_config.ice_groups)


def gen_right_pcf(pin_config):
    ice_groups = [
        (
            l,
            peripheral_group_to_ice_group(
                g, pin_config.right_pin_to_logical, pin_config.logical_pin_to_phys
            ),
        )
        for l, g in peripheral_groups
    ]
    gen_pcf_from_groups("R", ice_groups)


def gen_pcf(pin_config):
    for s, p in pin_config.signals:
        print(f"set_io {s} {pin_config.logical_pin_to_phys[p]}")
    print()

    if pin_config.left_pin_to_logical:
        gen_left_pcf(pin_config)

    if pin_config.right_pin_to_logical:
        gen_right_pcf(pin_config)


hx8k_config = IcePinConfig(
    hx8k.logical_pin_to_phys,
    hx8k.signals,
    hx8k.left_pin_to_logical,
    hx8k.right_pin_to_logical,
)

hx4k_config = IcePinConfig(
    hx4k.logical_pin_to_phys,
    hx4k.signals,
    hx4k.left_pin_to_logical,
    hx4k.right_pin_to_logical,
)

boards = {"hx4k": hx4k_config, "hx8k": hx8k_config}


def main():
    if len(sys.argv) < 2:
        print("Usage: pins.py <board_name>")
        sys.exit(1)

    board_name = sys.argv[1]
    if board_name in boards:
        gen_pcf(boards[board_name])
    else:
        print(f"Board '{board_name}' not supported.")
        sys.exit(1)


if __name__ == "__main__":
    main()
