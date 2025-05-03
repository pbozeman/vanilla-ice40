#!/usr/bin/env python3

import sys

from dataclasses import dataclass

from boards import hx8k_v2


@dataclass
class IcePinConfigV2:
    # logical name, e.g. IOL_1A, to physical pin,
    # e.g. E4 (for bga) or 112 for lqfp
    logical_pin_to_phys: {str, str}

    # on board signals, e.g. CLK, LED, etc.
    signals: (str, str)

    # numeric pin, e.g. 3, to logical name of the pin that its connected
    # to, e.g.: IOL_23B
    j1_to_logical: {int, str}
    j2_to_logical: {int, str}
    j3_to_logical: {int, str}
    j4_to_logical: {int, str}


sram_256_buses = [
    (
        "SRAM_256_A_ADDR_BUS",
        [
            "A_2",
            "A_6",
            "A_10",
            "A_14",
            "A_18",
            "A_58",
            "A_62",
            "A_66",
            "A_70",
            "A_74",
            "A_98",
            "A_94",
            "A_90",
            "A_86",
            "A_9",
            "A_5",
            "A_1",
        ],
    ),
    (
        "SRAM_256_A_DATA_BUS",
        [
            "A_22",
            "A_26",
            "A_30",
            "A_34",
            "A_38",
            "A_42",
            "A_46",
            "A_50",
            "A_78",
            "A_41",
            "A_37",
            "A_33",
            "A_29",
            "A_25",
            "A_21",
            "A_17",
        ],
    ),
    (
        "SRAM_256_B_ADDR_BUS",
        [
            "B_11",
            "B_15",
            "B_12",
            "B_16",
            "B_20",
            "B_60",
            "B_64",
            "B_68",
            "B_72",
            "B_76",
            "B_88",
            "B_84",
            "B_80",
            "A_97",
            "A_93",
            "A_53",
            "A_49",
            "A_45",
        ],
    ),
    (
        "SRAM_256_B_DATA_BUS",
        [
            "B_24",
            "B_28",
            "B_32",
            "B_36",
            "B_40",
            "B_44",
            "B_48",
            "B_52",
            "A_89",
            "A_85",
            "A_81",
            "A_77",
            "A_73",
            "A_69",
            "A_65",
            "A_61",
        ],
    ),
    (
        "SRAM_256_C_ADDR_BUS",
        [
            "C_2",
            "C_6",
            "C_10",
            "C_14",
            "C_18",
            "B_19",
            "B_23",
            "B_27",
            "B_31",
            "B_35",
            "C_65",
            "C_61",
            "C_57",
            "C_53",
            "C_49",
            "C_9",
            "C_5",
            "C_1",
        ],
    ),
    (
        "SRAM_256_C_DATA_BUS",
        [
            "C_22",
            "C_26",
            "C_30",
            "C_34",
            "C_38",
            "C_42",
            "C_46",
            "C_50",
            "C_45",
            "C_41",
            "C_37",
            "C_33",
            "C_29",
            "C_25",
            "C_21",
            "C_17",
        ],
    ),
    (
        "SRAM_256_D_ADDR_BUS",
        [
            "B_39",
            "B_43",
            "B_47",
            "B_51",
            "B_55",
            "B_95",
            "B_99",
            "B_92",
            "B_96",
            "B_100",
            "D_100",
            "D_96",
            "D_92",
            "D_88",
            "D_84",
            "D_44",
            "D_40",
            "D_36",
        ],
    ),
    (
        "SRAM_256_D_DATA_BUS",
        [
            "B_59",
            "B_63",
            "B_67",
            "B_71",
            "B_75",
            "B_79",
            "B_83",
            "B_87",
            "D_80",
            "D_76",
            "D_72",
            "D_68",
            "D_64",
            "D_60",
            "D_56",
            "D_52",
        ],
    ),
]

sram_256_signals = [
    ("SRAM_256_A_OE_N", "A_13"),
    ("SRAM_256_A_WE_N", "A_54"),
    ("SRAM_256_B_OE_N", "A_57"),
    ("SRAM_256_B_WE_N", "B_56"),
    ("SRAM_256_C_OE_N", "C_13"),
    ("SRAM_256_C_WE_N", "C_54"),
    ("SRAM_256_D_OE_N", "D_48"),
    ("SRAM_256_D_WE_N", "B_91"),
]


def combine_headers(header_maps):
    combined_map = {}

    for prefix, original_map in header_maps.items():
        for key, value in original_map.items():
            new_key = f"{prefix}_{key}"
            combined_map[new_key] = value

    return combined_map


def sram_pcf(header_map):
    for s, p in sram_256_signals:
        print(f"set_io {s} {header_map[p]}")

    print()
    for b in sram_256_buses:
        for i, p in enumerate(b[1]):
            print(f"set_io {b[0]}[{i}] {header_map[b[1][i]]}")


def gen_pcf(pin_config):
    for s, p in pin_config.signals:
        print(f"set_io {s} {pin_config.logical_pin_to_phys[p]}")
    print()

    header_map = combine_headers(
        {
            "A": pin_config.j1_to_logical,
            "B": pin_config.j2_to_logical,
            "C": pin_config.j3_to_logical,
            "D": pin_config.j4_to_logical,
        }
    )

    sram_pcf(header_map)


hx8k_v2_config = IcePinConfigV2(
    hx8k_v2.logical_pin_to_phys,
    hx8k_v2.signals,
    hx8k_v2.j1_to_logical,
    hx8k_v2.j2_to_logical,
    hx8k_v2.j3_to_logical,
    hx8k_v2.j4_to_logical,
)

boards = {"hx8k_v2": hx8k_v2_config}


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
