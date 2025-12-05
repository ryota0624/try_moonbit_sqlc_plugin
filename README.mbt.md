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