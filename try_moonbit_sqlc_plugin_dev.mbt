///|
pub fn fib(n : Int) -> Int64 {
  loop (n, 0L, 1L) {
    (0, _, b) => b
    (i, a, b) => continue (i - 1, b, a + b)
  }
}

///|
/// data is a labelled argument without default value having type Array[Int]
/// start is an optional labelled argument with default value 0 having type Int
/// length is an optional labelled argument without default value having type Option[Int]
pub fn sum(data~ : Array[Int], start? : Int = 0, length? : Int) -> Int {
  let end = if length is Some(length) { start + length } else { data.length() }
  for i = start, sum = 0; i < end; i = i + 1, sum = sum + data[i] {

  } else {
    sum
  }
}

///|
/// parse GenerateRequest from Bytes
pub fn parse_generate_request(data : Bytes) -> @plugin.GenerateRequest raise {
  @protobuf.BytesReader::from_bytes(data) |> @protobuf.Read::read
}

///|
/// parse GenerateRequest from Array[Byte]
pub fn parse_generate_request_from_array_bytes(
  byte_array : Array[Byte],
) -> @plugin.GenerateRequest raise {
  Bytes::from_array(byte_array) |> parse_generate_request
}
