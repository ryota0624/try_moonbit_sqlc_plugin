///|
#cfg(target="wasm")
fn main {
  let result = try? {
    let reader = @protobuf.BytesReader::from_bytes(
      Bytes::from_array(read_file(@wasi.Fd(0))),
    )
    let request = @protobuf.Read::read(reader)
    let response = @lib.process_generate_request(request)
    let writer = @buffer.new()
    @protobuf.Write::write(response, writer)
    let contents : Array[BytesView] = [
      Bytes::from_array(writer.to_bytes().to_array()),
    ]
    @wasi.Fd(1).fd_write(contents)
  }
  match result {
    Err(e) => {
      log_error("Failed to process request: \{e.to_string()}")
      @wasi.proc_exit(1)
    }
    Ok(_) => @wasi.proc_exit(0)
  }
}

///|
const BUFFER_LEN : UInt64 = 4096

///|
#cfg(target="wasm")
fn read_file(fd : @wasi.Fd) -> Array[Byte] raise @wasi.Errno {
  let result : Array[Byte] = []
  while true {
    let output = FixedArray::make(BUFFER_LEN.to_int(), b'\x00')
    let read_output : Array[FixedArray[Byte]] = [output]
    let size = try? fd.fd_read(read_output)
    match size {
      Err(err) => {
        log_error(err.to_string())
        raise err
      }
      Ok(size) =>
        if size == 0 {
          break
        } else {
          let read = FixedArray::make(size.0.reinterpret_as_int(), b'\x00')
          output.blit_to(
            read,
            src_offset=0,
            dst_offset=0,
            len=size.0.reinterpret_as_int(),
          )
          result.append([..read])
        }
    }
  }
  result
}

///|
#cfg(target="wasm")
fn log_error(err : String) -> Unit {
  let contents : Array[BytesView] = [
    @encoding/utf8.encode("Error: \{err.to_string()}\n"),
  ]
  (try? @wasi.Fd(2).fd_write(contents)) |> ignore
}
