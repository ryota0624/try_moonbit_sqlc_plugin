///|
fn main {
  @async.run_async_main(main_async)
  panic()
}

///|
async fn main_async() -> Unit {
  let input = @stdio.stdin.read_all()
  let request = @lib.parse_generate_request(input.binary())
  for query in request.queries {
    @stdio.stderr.write(query.name + "\n")
  }
}
