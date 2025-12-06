///|
fn main {
  @async.run_async_main(main_async)
  panic()
}

///|
async fn main_async() -> Unit {
  let input = @stdio.stdin.read_all()
  @stdio.stderr.write(input)
}
