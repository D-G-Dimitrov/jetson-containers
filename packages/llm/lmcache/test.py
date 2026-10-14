#!/usr/bin/env python3
import torch

print('testing LMCache...')
import lmcache

# Compiled extensions (non-fatal: build containers may lack a GPU device)
for mod in ("lmcache.cuda_ops", "lmcache.lmcache_fs",
            "lmcache.lmcache_native", "lmcache.lmcache_redis"):
    try:
        __import__(mod)
        print(f"  {mod}: OK")
    except Exception as e:
        print(f"  {mod}: unavailable ({e})")

print('LMCache version:', lmcache.__version__)
print('CUDA available:', torch.cuda.is_available())
print('LMCache OK')
