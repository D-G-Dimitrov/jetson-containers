#!/usr/bin/env python3
print("testing xformers with a tiny model…")

import os, torch, xformers, xformers.ops
from diffusers import DiffusionPipeline

os.environ.setdefault("PYTORCH_ALLOC_CONF", "expandable_segments:True")

device_name = torch.cuda.get_device_name(0)
cap = torch.cuda.get_device_capability(0)
print(f"{torch.__version__} {device_name} (sm_{cap[0]}{cap[1]})")
print(f"xformers {xformers.__version__}")

pipe = DiffusionPipeline.from_pretrained(
    "segmind/tiny-sd",
    torch_dtype=torch.float16,
    use_safetensors=False,
    low_cpu_mem_usage=False,
    device_map=None,
).to("cuda")

# Attempt to enable xformers memory-efficient attention, with compatibility
# shims for newer xformers versions that moved/renamed the API.
try:
    import xformers.ops as xops
except ImportError:
    xops = None

if xops is not None:
    # If the old symbol is missing, try to find the new one and attach it
    if not hasattr(xops, "memory_efficient_attention"):
        mea = None
        # Try the most likely new locations
        try:
            # new top-level import in some versions
            from xformers.ops import memory_efficient_attention as mea
        except Exception:
            try:
                # other versions expose it under fmha
                from xformers.ops.fmha import memory_efficient_attention as mea
            except Exception:
                mea = None

        if mea is not None:
            # Provide the old attribute name for downstream code that expects it
            setattr(xops, "memory_efficient_attention", mea)

# Now call the diffusers helper which will either succeed or raise a helpful exception
try:
    pipe.enable_xformers_memory_efficient_attention()
    print("xformers memory-efficient attention enabled")
except (NotImplementedError, AttributeError) as e:
    print(f"xformers attention operators not available for sm_{cap[0]}{cap[1]} — running with default attention ({e})")

with torch.inference_mode(), torch.autocast("cuda", dtype=torch.float16):
    image = pipe("a small cat", num_inference_steps=20, guidance_scale=7.0, height=256, width=256).images[0]

out_path = "/data/images/tiny_cat.png"
os.makedirs(os.path.dirname(out_path), exist_ok=True)
image.save(out_path)
print("xformers + tiny-sd OK ->", out_path)
