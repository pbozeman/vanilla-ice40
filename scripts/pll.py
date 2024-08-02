#!/usr/bin/env python3

import sys
import argparse

def calculate_pll_parameters(input_freq, output_freq):
    best_error = float('inf')
    best_params = None
    best_output_freq = None
    for divr in range(16):
        for divf in range(128):
            for divq in range(8):
                vco_freq = input_freq / (divr + 1) * (divf + 1)
                pll_output = vco_freq / (2 ** divq)
                error = abs(pll_output - output_freq)
                if error < best_error:
                    best_error = error
                    best_params = (divr, divf, divq)
                    best_output_freq = pll_output
    return best_params, best_output_freq

def main():
    parser = argparse.ArgumentParser(description='Calculate PLL parameters')
    parser.add_argument('input_clock', type=float, help='Input clock frequency in MHz')
    parser.add_argument('desired_output_clock', type=float, help='Desired output clock frequency in MHz')
    args = parser.parse_args()

    # Convert MHz to Hz
    input_clock = args.input_clock * 1e6
    desired_output_clock = args.desired_output_clock * 1e6

    best_params, expected_output_clock = calculate_pll_parameters(input_clock, desired_output_clock)
    divr, divf, divq = best_params

    print(f"Best parameters for PLL:")
    print(f"DIVR (R): {divr}")
    print(f"DIVF (F): {divf}")
    print(f"DIVQ (Q): {divq}")
    print(f"Expected output clock: {expected_output_clock / 1e6:.2f} MHz")

if __name__ == "__main__":
    main()
