#!/usr/bin/env python3
import subprocess
import sys

# Test that ds4 binaries are available and print version info
result = subprocess.run(['/usr/local/bin/ds4', '--help'], capture_output=True, text=True)
if result.returncode != 0:
    print(f"ds4 --help failed: {result.stderr}", file=sys.stderr)
    sys.exit(1)

# Print the help output (first few lines for version info)
print(result.stdout[:500] if result.stdout else result.stderr[:500])
print("\nds4 OK")
