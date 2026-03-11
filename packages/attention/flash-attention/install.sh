#!/usr/bin/env bash
set -ex

if [ "$FORCE_BUILD" == "on" ]; then
	echo "Forcing build of FlashAttention ${FLASH_ATTENTION_VERSION}"
	exit 1
fi

uv pip install -v flash-attn==${FLASH_ATTENTION_VERSION} flash-attn-4
uv pip show flash-attn && python3 -c 'import flash_attn'
