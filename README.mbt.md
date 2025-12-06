# username/try_moonbit_sqlc_plugin_dev


# history

## protoc x mbtまで
buf config init
touch buf.gen.yaml
sh build-protoc-gen-mbt.sh

git submodule add git@github.com:sqlc-dev/sqlc.git sqlc ...はうまくいかないのでprotoをコピーして書き換える

cat sqlc/protos/plugin/codegen.proto > proto/codegen.proto

buf generate

## protoc pluginの疎通まで

shellでstdin to stdoutで動くことを確認
moonbitで作ったバイナリでstdin to stdoutで動くことを確認
moon build --target native

## codegenerateを実装してsqlcから動くことを確認

codegenerateを実装してsqlcから動くことを確認

## wasmで動かす

moon build --target wasmは通らない
moon build --target wasmが通るように実装
wasm component modelはsqlc側が対応していない！のでwasi対応にする
1. wasi対応のライブラリを使う。
2. パッケージの分離
wasmをwasmtime経由でsqlcから動かすことを確認
wasmファイルのchecksumを取得してsqlcに記載

---



rm -rf .mooncakes && moon  build cmd/wasm --target wasm
rm -rf .mooncakes && moon  build cmd/native --target native

.mooncakesが残っているとビルドに失敗するので削除してからビルドする