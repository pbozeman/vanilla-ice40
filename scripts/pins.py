#!/usr/bin/env python3

import unittest

# This script generates pcf files for the vanilla ice peripheral boards.
#
# It is easier to transcribe the mappings for each level rather than try to
# trace all the connections back from destination to their source. It's also
# easier to audit for correctness as the lists below can be compared
# directly to the schematics.
#
# Once each layer's mapping is defined, it's relatively simple to traverse the
# dictionaries and print out pcf files.

hx8k_pins = [
    ('IOL_1A', 'E4'),
    ('IOL_1B', 'B2'),
    ('IOL_2A', 'F5'),
    ('IOL_2B', 'B1'),
    ('IOL_3A', 'C1'),
    ('IOL_3B', 'C2'),
    ('IOL_4A', 'F4'),
    ('IOL_4B', 'D2'),
    ('IOL_5A', 'G5'),
    ('IOL_5B', 'D1'),
    ('IOL_6A', 'G4'),
    ('IOL_6B', 'E3'),
    ('IOL_7A', 'H5'),
    ('IOL_7B', 'E2'),
    ('IOL_8A', 'G3'),
    ('IOL_8B', 'F3'),
    ('IOL_9A', 'H3'),
    ('IOL_9B', 'F2'),
    ('IOL_10A', 'H6'),
    ('IOL_10B', 'F1'),
    ('IOL_11A', 'H4'),
    ('IOL_11B', 'G2'),
    ('IOL_12A', 'J4'),
    ('IOL_12B', 'H2'),
    ('IOL_13A', 'J5'),
    ('IOL_13B', 'G1'),
    ('IOL_14A', 'J3'),
    ('IOL_14B', 'H1'),
    ('IOL_15A', 'J2'),
    ('IOL_15B', 'J1'),
    ('IOL_16A', 'K1'),
    ('IOL_16B', 'K3'),
    ('IOL_17A', 'L4'),
    ('IOL_17B', 'L1'),
    ('IOL_18A', 'K4'),
    ('IOL_18B', 'M1'),
    ('IOL_19A', 'L6'),
    ('IOL_19B', 'L3'),
    ('IOL_20A', 'K5'),
    ('IOL_20B', 'M2'),
    ('IOL_21A', 'L7'),
    ('IOL_21B', 'N2'),
    ('IOL_22A', 'M6'),
    ('IOL_22B', 'M3'),
    ('IOL_23A', 'L5'),
    ('IOL_23B', 'N3'),
    ('IOL_24A', 'P1'),
    ('IOL_24B', 'M4'),
    ('IOL_25A', 'P2'),
    ('IOL_25B', 'M5'),
    ('IOL_26A', 'R1'),
    ('IOL_26B', 'N4'),
    ('IOB_52', 'N6'),
    ('IOB_53', 'T1'),
    ('IOB_54', 'P4'),
    ('IOB_55', 'R2'),
    ('IOB_56', 'N5'),
    ('IOB_57', 'T2'),
    ('IOB_58', 'P5'),
    ('IOB_59', 'R3'),
    ('IOB_60', 'R5'),
    ('IOB_61', 'T3'),
    ('IOB_63', 'R4'),
    ('IOB_64', 'M7'),
    ('IOB_66', 'N7'),
    ('IOB_67', 'P6'),
    ('IOB_68', 'M8'),
    ('IOB_69', 'T5'),
    ('IOB_71', 'R6'),
    ('IOB_72', 'P8'),
    ('IOB_73', 'T6'),
    ('IOB_74', 'L9'),
    ('IOB_75', 'T7'),
    ('IOB_76', 'T8'),
    ('IOB_77', 'P7'),
    ('IOB_78', 'N9'),
    ('IOB_79', 'T9'),
    ('IOB_80', 'M9'),
    ('IOB_81', 'R9'),
    ('IOB_82', 'K9'),
    ('IOB_83', 'P9'),
    ('IOB_84', 'R10'),
    ('IOB_85', 'L10'),
    ('IOB_86', 'P10'),
    ('IOB_87', 'N10'),
    ('IOB_88', 'T10'),
    ('IOB_89', 'T11'),
    ('IOB_91', 'T15'),
    ('IOB_92', 'T14'),
    ('IOB_93', 'M11'),
    ('IOB_94', 'T13'),
    ('IOB_98', 'N12'),
    ('IOB_99', 'L11'),
    ('IOB_100', 'T16'),
    ('IOB_101', 'M12'),
    ('IOB_102', 'R16'),
    ('IOB_103_CBSEL0', 'K11'),
    ('IOB_104_CBSEL1', 'P13'),
    ('CDONE', 'M10'),
    ('CRESET#', 'N11'),
    ('IOB_105_SDO', 'P12'),
    ('IOB_106_SDI', 'P11'),
    ('IOB_107_SCK', 'R11'),
    ('IOB_108_SS', 'R12'),
    ('IOR_109', 'R14'),
    ('IOR_110', 'R15'),
    ('IOR_111', 'P14'),
    ('IOR_112', 'P15'),
    ('IOR_113', 'P16'),
    ('IOR_114', 'M13'),
    ('IOR_115', 'M14'),
    ('IOR_116', 'L12'),
    ('IOR_117', 'N16'),
    ('IOR_118', 'L13'),
    ('IOR_119', 'L14'),
    ('IOR_120', 'K12'),
    ('IOR_121', 'M16'),
    ('IOR_122', 'J10'),
    ('IOR_123', 'M15'),
    ('IOR_126', 'J11'),
    ('IOR_127', 'L16'),
    ('IOR_128', 'K13'),
    ('IOR_129', 'K14'),
    ('IOR_130', 'J15'),
    ('IOR_131', 'K15'),
    ('IOR_133', 'K16'),
    ('IOR_134', 'J14'),
    ('IOR_136', 'J12'),
    ('IOR_137', 'J13'),
    ('IOR_138', 'J16'),
    ('IOR_139', 'H13'),
    ('IOR_140', 'H11'),
    ('IOR_141', 'H16'),
    ('IOR_142', 'H14'),
    ('IOR_143', 'G16'),
    ('IOR_144', 'H12'),
    ('IOR_145', 'G15'),
    ('IOR_146', 'G10'),
    ('IOR_147', 'F16'),
    ('IOR_148', 'G11'),
    ('IOR_149', 'F15'),
    ('IOR_150', 'G14'),
    ('IOR_151', 'E16'),
    ('IOR_152', 'G13'),
    ('IOR_153', 'D16'),
    ('IOR_154', 'G12'),
    ('IOR_155', 'F14'),
    ('IOR_156', 'F12'),
    ('IOR_157', 'D15'),
    ('IOR_158', 'F11'),
    ('IOR_160', 'E14'),
    ('IOR_161', 'C16'),
    ('IOR_162', 'F13'),
    ('IOR_165', 'B16'),
    ('IOR_166', 'E13'),
    ('IOR_167', 'D14'),
    ('IOT_168', 'C14'),
    ('IOT_169', 'B15'),
    ('IOT_170', 'D13'),
    ('IOT_171', 'B14'),
    ('IOT_172', 'C12'),
    ('IOT_173', 'E11'),
    ('IOT_174', 'C13'),
    ('IOT_176', 'A16'),
    ('IOT_177', 'A15'),
    ('IOT_178', 'B13'),
    ('IOT_179', 'E10'),
    ('IOT_180', 'C11'),
    ('IOT_181', 'D11'),
    ('IOT_182', 'B12'),
    ('IOT_183', 'B10'),
    ('IOT_184', 'B11'),
    ('IOT_185', 'C10'),
    ('IOT_186', 'A10'),
    ('IOT_187', 'A11'),
    ('IOT_190', 'D10'),
    ('IOT_191', 'C9'),
    ('IOT_192', 'E9'),
    ('IOT_193', 'D9'),
    ('IOT_194', 'A9'),
    ('IOT_196', 'F9'),
    ('IOT_197', 'C8'),
    ('IOT_198', 'F7'),
    ('IOT_199', 'B9'),
    ('IOT_200', 'D8'),
    ('IOT_203', 'B8'),
    ('IOT_205', 'A7'),
    ('IOT_206', 'C7'),
    ('IOT_207', 'B7'),
    ('IOT_208', 'B6'),
    ('IOT_209', 'C6'),
    ('IOT_210', 'D7'),
    ('IOT_211', 'A6'),
    ('IOT_212', 'D6'),
    ('IOT_213', 'A5'),
    ('IOT_214', 'B5'),
    ('IOT_215', 'E6'),
    ('IOT_216', 'B4'),
    ('IOT_218', 'A2'),
    ('IOT_219', 'D5'),
    ('IOT_220', 'A1'),
    ('IOT_221', 'C5'),
    ('IOT_222', 'C4'),
    ('IOT_223', 'B3'),
    ('IOT_224', 'D4'),
    ('IOT_225', 'E5'),
    ('IOT_226', 'D3'),
    ('IOT_227', 'C3'),
]

hx8k_b2b_left = [
    (3, 'IOL_23B'),
    (4, 'IOL_23A'),
    (5, 'IOL_17A'),
    (6, 'IOL_22B'),
    (7, 'IOL_19B'),
    (8, 'IOL_18A'),
    (9, 'IOL_16B'),
    (10, 'IOL_13A'),
    (13, 'IOL_7A'),
    (14, 'IOL_12A'),
    (15, 'IOL_11A'),
    (16, 'IOL_9A'),
    (17, 'IOL_6A'),
    (18, 'IOL_8A'),
    (19, 'IOL_8B'),
    (20, 'IOL_4A'),
    (23, 'IOL_10A'),
    (24, 'IOL_6B'),
    (25, 'IOL_1A'),
    (26, 'IOL_5A'),
    (27, 'IOL_2A'),
    (28, 'IOT_225'),
    (29, 'IOT_215'),
    (30, 'IOT_226'),
    (31, 'IOT_227'),
    (32, 'IOT_224'),
    (33, 'IOT_222'),
    (34, 'IOT_219'),
    (35, 'IOT_221'),
    (36, 'IOT_212'),
    (37, 'IOT_209'),
    (38, 'IOT_210'),
    (41, 'IOT_206'),
    (42, 'IOT_200'),
    (43, 'IOT_197'),
    (44, 'IOT_193'),
    (45, 'IOT_191'),
    (46, 'IOT_190'),
    (47, 'IOT_185'),
    (48, 'IOT_181'),
    (51, 'IOT_180'),
    (52, 'IOT_172'),
    (53, 'IOT_170'),
    (54, 'IOT_168'),
    (55, 'IOT_192'),
    (56, 'IOT_179'),
    (57, 'IOT_173'),
    (58, 'IOT_196'),
    (63, 'IOL_26A'),
    (64, 'IOL_25A'),
    (65, 'IOL_24A'),
    (66, 'IOL_21B'),
    (67, 'IOL_20B'),
    (68, 'IOL_18B'),
    (69, 'IOL_17B'),
    (70, 'IOL_16A'),
    (73, 'IOL_15A'),
    (74, 'IOL_15B'),
    (75, 'IOL_12B'),
    (76, 'IOL_14B'),
    (77, 'IOL_11B'),
    (78, 'IOL_13B'),
    (79, 'IOL_10B'),
    (80, 'IOL_9B'),
    (83, 'IOL_7B'),
    (84, 'IOL_5B'),
    (85, 'IOL_4B'),
    (86, 'IOL_3A'),
    (87, 'IOL_3B'),
    (88, 'IOL_2B'),
    (89, 'IOT_198'),
    (90, 'IOL_1B'),
    (91, 'IOT_220'),
    (92, 'IOT_218'),
    (93, 'IOT_223'),
    (94, 'IOT_216'),
    (95, 'IOT_214'),
    (96, 'IOT_213'),
    (97, 'IOT_208'),
    (98, 'IOT_211'),
    (101, 'IOT_207'),
    (102, 'IOT_205'),
    (103, 'IOT_203'),
    (104, 'IOT_199'),
    (105, 'IOT_194'),
    (106, 'IOT_183'),
    (107, 'IOT_186'),
    (108, 'IOT_184'),
    (111, 'IOT_187'),
    (112, 'IOT_182'),
    (113, 'IOT_187'),
    (114, 'IOT_174'),
    (115, 'IOT_171'),
    (116, 'IOT_177'),
    (117, 'IOT_169'),
    (118, 'IOT_176')
]

hx8k_signals = [
    ('CLK', 'IOL_14A'),
    ('UART_RX', 'IOR_140'),
    ('UART_TX', 'IOR_154'),
]

peripheral_groups = [
    ('A', [3, 5, 7, 9, 4, 6, 8, 10]),
    ('B', [13, 15, 17, 19, 14, 16, 18, 20]),
    ('C', [23, 25, 27, 29, 24, 26, 28, 30]),
    ('D', [31, 33, 35, 37, 32, 34, 36, 38]),
    ('E', [63, 65, 67, 69, 64, 66, 68, 70]),
    ('F', [73, 75, 77, 79, 74, 76, 78, 80]),
    ('G', [41, 43, 45, 47, 42, 44, 46, 48]),
    ('H', [51, 53, 55, 57, 52, 54, 56, 58]),
    ('I', [91, 93, 95, 97, 92, 94, 96, 98]),
    ('J', [111, 113, 115, 117, 112, 114, 116, 118]),
    ('K', [108, 106, 104, 102, 107, 105, 103, 101]),
    ('L', [90, 88, 86, 84, 89, 87, 85, 83]),
]

sram_groups = [
    ('SRAM_ADDR_BUS', ['C[7]',
                       'C[3]',
                       'C[6]',
                       'C[2]',
                       'C[5]',
                       'A[0]',
                       'A[4]',
                       'A[1]',
                       'A[5]',
                       'B[6]',
                       'B[3]',
                       'B[7]',
                       'C[0]',
                       'C[4]',
                       'C[1]',
                       'G[3]',
                       'G[6]',
                       'G[2]',
                       'G[5]',
                       'G[1]']),
    ('SRAM_DATA_BUS', ['D[4]',
                       'D[1]',
                       'D[5]',
                       'D[2]',
                       'D[6]',
                       'D[3]',
                       'D[7]',
                       'G[0]',
                       'B[2]',
                       'B[5]',
                       'B[1]',
                       'B[4]',
                       'B[0]',
                       'A[7]',
                       'A[3]',
                       'A[6]'])
]

sram_signals = [
    ('SRAM_CS#', 'D[0]'),
    ('SRAM_OE#', 'A[2]'),
    ('SRAM_WE#', 'G[4]')
]

def dicts_from_pairs(pairs):
    return ({p[0]: p[1] for p in pairs}, {p[1]: p[0] for p in pairs})

hx8k_pins_l_to_p, hx8k_pins_p_to_l = dicts_from_pairs(hx8k_pins)
hx8k_signal_s_to_p, hx8k_signal_p_to_s = dicts_from_pairs(hx8k_signals)
hx8k_left_to_fpga, hx8k_fpga_to_left = dicts_from_pairs(hx8k_b2b_left);

def b2b_pin_to_pin(pin):
    if pin <= 60:
        return pin + 60
    else:
        return pin - 60

def traverse(key, *dicts):
    for d in dicts:
        key = d[key]
    return key

def peripheral_pin_to_ice_pin(pin):
    return traverse(b2b_pin_to_pin(pin), hx8k_left_to_fpga, hx8k_pins_l_to_p)

def peripheral_group_to_ice_group(grp):
    return [peripheral_pin_to_ice_pin(p) for p in grp]

def groups_to_pins(groups):
    result = []
    for name, pins in groups:
        for i, p in enumerate(pins):
            result.append((f"{name}[{i}]", p))
    return result

def ice_group_to_pcf(label, pins):
    return "\n".join(f"set_io {label}[{i}] {pin}" for i, pin in enumerate(pins))

ice_groups = [(l, peripheral_group_to_ice_group(p)) for l, p in peripheral_groups]
ice_group_pins = groups_to_pins(ice_groups)

base_to_p, p_to_base = dicts_from_pairs(ice_group_pins)

def base_group_to_ice_group(grp):
    return [base_to_p[p] for p in grp]

# pmod pins
concatenated_groups = sum([pins for _, pins in ice_groups], [])
ice_pins = [p for p in concatenated_groups]

# sram pin groups
sram_ice_groups = [(l, base_group_to_ice_group(p)) for l, p in sram_groups]

def gen_pcf():
  # base groups
  for g in ice_groups:
      lable, pins = g
      print(ice_group_to_pcf(lable, pins))
      print()
 
  # pmod aliases
  for g in ice_groups:
      lable, pins = g
      print(ice_group_to_pcf("PMOD_" + lable, pins))
      print()
  
  # all pmods
  print(ice_group_to_pcf("PMOD", [p for p in ice_pins]))
  print()
  
  # sram
  sram_ice_groups = [(l, base_group_to_ice_group(p)) for l, p in sram_groups]
  
  for s, p in sram_signals:
      print(f"set_io {s} {base_to_p[p]}")
  
  print()
  for g in sram_ice_groups:
      lable, pins = g
      print(ice_group_to_pcf(lable, pins))
      print()

def main():
    gen_pcf();

if __name__ == '__main__':
    main()

# Unit tests
#
# These are very incomplete, but this is a basic end to end test that
# ensures translation is mapping to the correct pin through all the layers
class TestTranslation(unittest.TestCase):

    def test_end_to_end(self):
        self.assertEqual(base_to_p['D[0]'], 'A1')
