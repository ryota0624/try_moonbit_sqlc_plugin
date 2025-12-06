#!/bin/sh
/opt/homebrew/bin/wasmtime run cmd/main/wasm/target/wasm/release/build/sqlc_gen_mbt_wasm.wasm <&0 2>&2
# 実行権限を忘れずに