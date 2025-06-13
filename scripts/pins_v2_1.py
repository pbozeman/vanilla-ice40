#!/usr/bin/env python3

import sys

from dataclasses import dataclass

from boards import hx8k_v2_1


@dataclass
class IcePinConfigV2:
    # logical name, e.g. IOL_1A, to physical pin,
    # e.g. E4 (for bga) or 112 for lqfp
    logical_pin_to_phys: {str, str}

    # on board signals, e.g. CLK, LED, etc.
    signals: (str, str)

    # numeric pin, e.g. 3, to logical name of the pin that its connected
    # to, e.g.: IOL_23B
    j1_upper_to_logical: {int, str}
    j1_lower_to_logical: {int, str}
    j2_upper_to_logical: {int, str}
    j2_lower_to_logical: {int, str}


def combine_headers(pin_config, header_maps):
    combined_map = {}

    for prefix, original_map in header_maps.items():
        for key, value in original_map.items():
            new_key = f"{prefix}_{key}"
            combined_map[new_key] = pin_config.logical_pin_to_phys[value]

    return combined_map


def header_pcf(header_map):
    pass


def gen_pcf(pin_config):
    for s, p in pin_config.signals:
        print(f"set_io {s} {pin_config.logical_pin_to_phys[p]}")
    print()

    header_map = combine_headers(
        pin_config,
        {
            "A": pin_config.j1_upper_to_logical,
            "B": pin_config.j1_lower_to_logical,
            "C": pin_config.j2_upper_to_logical,
            "D": pin_config.j2_lower_to_logical,
        },
    )

    # hack this in for now
    for k, v in pin_config.j1_upper_to_logical.items():
        print(f"set_io A[{k-1}] {pin_config.logical_pin_to_phys[v]}")

    for k, v in pin_config.j1_lower_to_logical.items():
        print(f"set_io B[{k-1}] {pin_config.logical_pin_to_phys[v]}")

    for k, v in pin_config.j2_upper_to_logical.items():
        print(f"set_io C[{k-1}] {pin_config.logical_pin_to_phys[v]}")

    for k, v in pin_config.j2_lower_to_logical.items():
        print(f"set_io D[{k-1}] {pin_config.logical_pin_to_phys[v]}")

    header_pcf(header_map)


hx8k_v2_1_config = IcePinConfigV2(
    hx8k_v2_1.logical_pin_to_phys,
    hx8k_v2_1.signals,
    hx8k_v2_1.j1_upper_to_logical,
    hx8k_v2_1.j1_lower_to_logical,
    hx8k_v2_1.j2_upper_to_logical,
    hx8k_v2_1.j2_lower_to_logical,
)

boards = {"hx8k_v2_1": hx8k_v2_1_config}


def main():
    if len(sys.argv) < 2:
        print("Usage: pins_v2.py <board_name>")
        sys.exit(1)

    board_name = sys.argv[1]
    if board_name in boards:
        gen_pcf(boards[board_name])
    else:
        print(f"Board '{board_name}' not supported.")
        sys.exit(1)


if __name__ == "__main__":
    main()
