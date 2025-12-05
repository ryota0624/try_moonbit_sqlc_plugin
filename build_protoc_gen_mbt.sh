git clone git@github.com:moonbitlang/protoc-gen-mbt.git tmp
cd tmp
moon build -C cli
cp cli/target/native/release/build/protoc-gen-mbt.exe ../protoc-gen-mbt.exe
cd ..
rm -rf tmp