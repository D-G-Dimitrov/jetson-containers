#!/usr/bin/env python3
import argparse
import subprocess
import sys

# Benchmark ds4 inference
parser = argparse.ArgumentParser()
parser.add_argument('-m', '--model', type=str, default='', required=True, help="path to the GGUF model")
parser.add_argument('-p', '--prompt', type=str, default='Once upon a time,')
parser.add_argument('-n', '--n-predict', type=int, default=128, help='number of output tokens to generate')
parser.add_argument('-c', '--ctx-size', type=int, default=512, help='context size')
parser.add_argument('--runs', type=int, default=2, help='number of benchmark iterations')

args = parser.parse_args()

print(args)

for run in range(args.runs):
    result = subprocess.run([
        '/usr/local/bin/ds4',
        '-m', args.model,
        '-p', args.prompt,
        '-n', str(args.n_predict),
        '-c', str(args.ctx_size),
        '--nothink',
    ], capture_output=True, text=True)

    print(f"\nRun {run}:")
    print(result.stdout)
    if result.returncode != 0:
        print(f"ds4 failed: {result.stderr}", file=sys.stderr)
        sys.exit(1)

print("\nds4 benchmark OK")
