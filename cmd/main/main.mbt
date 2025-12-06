///|
#cfg(target="native")
fn main {
  @async.run_async_main(main_async)
}

///|
#cfg(target="native")
async fn main_async() -> Unit {
  let input = @stdio.stdin.read_all()
  let request = @lib.parse_generate_request(input.binary())
  let response = try? @lib.process_generate_request(request)
  match response {
    Err(err) => {
      @stdio.stderr.write("Error: \{err}\n")
      panic()
    }
    Ok(res) => {
      let writer = @buffer.new()
      @protobuf.Write::write(res, writer)
      @stdio.stdout.write(writer.to_bytes())
    }
  }
}
