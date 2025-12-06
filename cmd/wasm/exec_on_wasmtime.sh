#!/bin/sh
/opt/homebrew/bin/wasmtime run target/wasm/release/build/cmd/wasm/wasm.wasm <&0 2>&2
# 実行権限を忘れずに