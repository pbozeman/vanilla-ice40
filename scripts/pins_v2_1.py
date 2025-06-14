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


sram_256_buses = [
    (
        "SRAM_256_A_ADDR_BUS",
        [
            "A_2",
            "A_4",
            "A_6",
            "A_8",
            "A_10",
            "A_42",
            "A_44",
            "A_46",
            "A_48",
            "A_50",
            "A_49",
            "A_47",
            "A_45",
            "A_43",
            "A_41",
            "A_5",
            "A_3",
            "A_1",
        ],
    ),
    (
        "SRAM_256_A_DATA_BUS",
        [
            "A_12",
            "A_14",
            "A_21",
            "A_23",
            "A_25",
            "A_27",
            "A_29",
            "A_31",
            "A_39",
            "A_37",
            "A_35",
            "A_33",
            "A_19",
            "A_17",
            "A_15",
            "A_13",
        ],
    ),
    (
        "SRAM_256_B_ADDR_BUS",
        [
            "B_2",
            "B_4",
            "B_6",
            "B_8",
            "B_10",
            "B_42",
            "B_44",
            "B_46",
            "B_48",
            "B_50",
            "B_49",
            "B_47",
            "B_45",
            "B_43",
            "B_41",
            "B_5",
            "B_3",
            "B_1",
        ],
    ),
    (
        "SRAM_256_B_DATA_BUS",
        [
            "B_12",
            "B_21",
            "B_23",
            "B_25",
            "B_27",
            "B_29",
            "B_31",
            "B_38",
            "B_39",
            "B_37",
            "B_35",
            "B_33",
            "B_19",
            "B_17",
            "B_15",
            "B_13",
        ],
    ),
    (
        "SRAM_256_C_ADDR_BUS",
        [
            "C_49",
            "C_47",
            "C_45",
            "C_43",
            "C_41",
            "C_9",
            "C_7",
            "C_5",
            "C_3",
            "C_1",
            "C_2",
            "C_4",
            "C_6",
            "C_8",
            "C_10",
            "C_46",
            "C_48",
            "C_50",
        ],
    ),
    (
        "SRAM_256_C_DATA_BUS",
        [
            "C_39",
            "C_30",
            "C_28",
            "C_26",
            "C_24",
            "C_22",
            "C_20",
            "C_13",
            "C_12",
            "C_14",
            "C_16",
            "C_18",
            "C_32",
            "C_34",
            "C_36",
            "C_38",
        ],
    ),
    (
        "SRAM_256_D_ADDR_BUS",
        [
            "D_49",
            "D_47",
            "D_45",
            "D_43",
            "D_41",
            "D_9",
            "D_7",
            "D_5",
            "D_3",
            "D_1",
            "D_2",
            "D_4",
            "D_6",
            "D_8",
            # 10 here
            "D_46",
            "D_48",
            "D_50",
            "D_10",
        ],
    ),
    (
        "SRAM_256_D_DATA_BUS",
        [
            "D_39",
            "D_37",
            "D_30",
            "D_28",
            "D_26",
            "D_24",
            "D_22",
            "D_20",
            "D_12",
            "D_14",
            "D_16",
            "D_18",
            "D_32",
            "D_34",
            "D_36",
            "D_38",
        ],
    ),
]

sram_256_signals = [
    ("SRAM_256_A_OE_N", "A_7"),
    ("SRAM_256_A_WE_N", "A_40"),
    ("SRAM_256_A_LB_N", "A_11"),
    ("SRAM_256_A_UB_N", "A_9"),
    ("SRAM_256_B_OE_N", "B_7"),
    ("SRAM_256_B_WE_N", "B_40"),
    ("SRAM_256_B_LB_N", "B_11"),
    ("SRAM_256_B_UB_N", "B_9"),
    ("SRAM_256_C_OE_N", "C_44"),
    ("SRAM_256_C_WE_N", "C_11"),
    ("SRAM_256_C_LB_N", "C_40"),
    ("SRAM_256_C_UB_N", "C_42"),
    ("SRAM_256_D_OE_N", "D_44"),
    ("SRAM_256_D_WE_N", "D_11"),
    ("SRAM_256_D_LB_N", "D_40"),
    ("SRAM_256_D_UB_N", "D_42"),
]

pmod_buses = [
    (
        "PMOD_A",
        ["C_23", "C_27", "C_31", "C_35", "C_25", "C_29", "C_33", "C_37"],
    ),
    (
        # this is based on the ADC pmods, which actually
        # don't have the last 2 connected
        "PMOD_B",
        [
            "D_29",
            "D_32",
            "D_33",
            "D_35",
            "D_27",
            "D_25",
        ],
    ),
]


def combine_headers(pin_config, header_maps):
    combined_map = {}

    for prefix, original_map in header_maps.items():
        for key, value in original_map.items():
            new_key = f"{prefix}_{key}"
            combined_map[new_key] = pin_config.logical_pin_to_phys[value]

    return combined_map


def header_pcf(header_map):
    print()
    for s, p in sram_256_signals:
        print(f"set_io {s} {header_map[p]}")

    print()
    for b in sram_256_buses:
        for i, p in enumerate(b[1]):
            print(f"set_io {b[0]}[{i}] {header_map[b[1][i]]}")

    print()
    for b in pmod_buses:
        for i, p in enumerate(b[1]):
            print(f"set_io {b[0]}[{i}] {header_map[b[1][i]]}")


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
