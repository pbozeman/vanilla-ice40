#!/usr/bin/env python3

import argparse
import multiprocessing as mp
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path


def try_seed(args):
    """Try a single nextpnr seed and return (seed, success, output)"""
    seed, nextpnr_cmd, nextpnr_args = args
    print(f"Running {nextpnr_cmd} with seed {seed}...")

    # Construct command with seed in the middle and user args at the end
    cmd = [nextpnr_cmd, "--seed", str(seed)] + nextpnr_args

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        success = result.returncode == 0
        return seed, success, result.stdout + result.stderr
    except Exception as e:
        return seed, False, str(e)


def find_working_seed(
    nextpnr_cmd, nextpnr_args, max_seeds, num_processes, output_file=None
):
    """Find a working nextpnr seed using parallel processing"""
    if num_processes is None:
        num_processes = mp.cpu_count()

    # Create a pool of workers
    with mp.Pool(processes=num_processes) as pool:
        args = [(seed, nextpnr_cmd, nextpnr_args) for seed in range(max_seeds)]
        # Try seeds in parallel
        for seed, success, output in pool.imap_unordered(try_seed, args):
            if success:
                pool.terminate()
                pool.join()
                # the sleep should not be necessary because of the join, but it seems that
                # some of the children continue to write anyway. This messes up the later real
                # build. An alternative would be to have them write to temp dirs.
                time.sleep(1)
                print("\nOutput from successful run:")
                print(output)
                print(f"\nSuccess! Found working seed: {seed}")

                # Write seed to output file if specified
                if output_file:
                    try:
                        with open(output_file, "w") as f:
                            f.write(str(seed))
                        print(f"Wrote seed to {output_file}")
                    except Exception as e:
                        print(f"Warning: Failed to write seed to {output_file}: {e}")

                return 0
            else:
                print(f"Seed {seed} failed")

    print(f"\nNo seeds meet timing after trying {max_seeds} seeds")
    return 1


def main():
    parser = argparse.ArgumentParser(
        description="Find a working nextpnr seed in parallel"
    )
    parser.add_argument(
        "--max-seeds",
        type=int,
        default=32,
        help="Maximum number of seeds to try (default: 32)",
    )
    parser.add_argument(
        "--jobs",
        type=int,
        default=None,
        help="Number of parallel jobs (default: number of CPU cores)",
    )
    parser.add_argument(
        "-o", "--output", help="Write successful seed to this file", type=str
    )
    parser.add_argument(
        "nextpnr_command", help="nextpnr command to run (e.g. nextpnr-ice40)"
    )
    parser.add_argument(
        "nextpnr_args", nargs=argparse.REMAINDER, help="Arguments to pass to nextpnr"
    )

    args = parser.parse_args()

    return find_working_seed(
        args.nextpnr_command,
        args.nextpnr_args,
        max_seeds=args.max_seeds,
        num_processes=args.jobs,
        output_file=args.output,
    )


if __name__ == "__main__":
    sys.exit(main())
