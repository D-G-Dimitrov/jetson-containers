#!/usr/bin/env python3
import argparse
import subprocess
import sys

# Test that ds4 can load a model and run inference
parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-m', '--model', type=str, default='', required=True, help="path to the GGUF model")
parser.add_argument('-p', '--prompt', type=str, default='Once upon a time,')
parser.add_argument('-n', '--n-predict', type=int, default=128, help='number of output tokens to generate')
parser.add_argument('-c', '--ctx-size', type=int, default=512, help='context size')

args = parser.parse_args()
print(args)

# Run ds4 inference
result = subprocess.run([
    '/usr/local/bin/ds4',
    '-m', args.model,
    '-p', args.prompt,
    '-n', str(args.n_predict),
    '-c', str(args.ctx_size),
    '--nothink',
], capture_output=True, text=True)

print(result.stdout)
if result.returncode != 0:
    print(f"ds4 failed: {result.stderr}", file=sys.stderr)
    sys.exit(1)

print("\nds4 model OK")
