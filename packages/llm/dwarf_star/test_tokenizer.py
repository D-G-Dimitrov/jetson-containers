#!/usr/bin/env python3
import argparse
import subprocess
import sys

# Test that ds4 can tokenize and detokenize correctly
parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-m', '--model', type=str, default='', required=True, help="path to the GGUF model")
parser.add_argument('-p', '--prompt', action='append', nargs='*')

args = parser.parse_args()

if args.prompt:
    args.prompt = [x[0] for x in args.prompt]
else:
    args.prompt = []

print(args)

# Run ds4 tokenization test
result = subprocess.run([
    '/usr/local/bin/ds4',
    '--dump-tokens',
    '-m', args.model,
] + [item for sublist in args.prompt for item in ['-p', sublist]], capture_output=True, text=True)

print(result.stdout)
if result.returncode != 0:
    print(f"ds4 tokenize failed: {result.stderr}", file=sys.stderr)
    sys.exit(1)

print("\nds4 tokenizer OK")
