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

///|
pub fn process_generate_request(
  generate_request : @plugin.GenerateRequest,
) -> @plugin.GenerateResponse raise {
  let codes = generate_code(generate_request)
  let file = @plugin.File::new(
    "generated_queries.mbt",
    @encoding/utf8.encode(codes),
  )
  @plugin.GenerateResponse::new([file])
}

///|
pub fn generate_code(
  generate_request : @plugin.GenerateRequest,
) -> String raise {
  let codes = generate_request.queries
    .map(Query::from_plugin_query(_, engine=generate_request.settings.engine))
    .map(generate_code_from_query)
  codes.join("\n")
}

///|
priv struct Parameter {
  column : Column
}

///|
priv struct Column {
  name : String
  mbt_type : String
}

///|
fn Column::new(name~ : String, mbt_type~ : String) -> Column {
  Column::{ name, mbt_type }
}

///|
priv struct Query {
  name : String
  parameters : Array[Parameter]
  columns : Array[Column]
}

///|
fn Query::from_plugin_query(
  plugin_query : @plugin.Query,
  engine~ : String,
) -> Query raise {
  Query::{
    name: plugin_query.name,
    parameters: plugin_query.parameters.map(param => Parameter::{
      column: Column::new(
        name=param.column.name,
        mbt_type=plugin_column_type_to_mbt_type(engine, param.column.type_),
      ),
    }),
    columns: plugin_query.columns.map(col => Column::new(
      name=col.name,
      mbt_type=plugin_column_type_to_mbt_type(engine, col.type_),
    )),
  }
}

///|
fn plugin_column_type_to_mbt_type(
  engine : String,
  plugin_type : @plugin.Identifier,
) -> String raise {
  match engine {
    "sqlite" => sqlite_plugin_column_type_to_mbt_type(plugin_type)
    other => fail("Unsupported engine: \{other}")
  }
}

///|
fn sqlite_plugin_column_type_to_mbt_type(
  plugin_type : @plugin.Identifier,
) -> String raise {
  match plugin_type.name {
    "integer" => "Int64"
    "text" => "String"
    other => fail("Unsupported SQLite column type: \{other}")
  }
}

///|
fn generate_code_from_query(query : Query) -> String raise {
  let result_type_name = "ResultOf" + query.name
  let result_struct = @mustache.parse(
    result_type_struct_template,
    Json::object({
      "struct_name": Json::string(result_type_name),
      "fields": query.columns.map(col => Json::object({
        "field_name": Json::string(col.name),
        "field_type": Json::string(col.mbt_type),
      })),
    }),
  )
  let query_func = @mustache.parse(
    query_template,
    Json::object({
      "function_name": Json::string(query.name),
      "args": query.parameters.map(param => Json::object({
        "name": Json::string(param.column.name),
        "type": Json::string(param.column.mbt_type),
      })),
      "result_type": Json::string(result_type_name),
    }),
  )
  result_struct + query_func
}

///|
let query_template =
  #|fn {{function_name}}({{#args}}{{name}}: {{type}},{{/args}}) -> {{result_type}} {}

///|
let result_type_struct_template =
  #|pub(all)struct {{struct_name}} {
  #|  {{#fields}}{{field_name}}: {{field_type}};
  #|  {{/fields}}
  #|} derive(ToJson, FromJson, Show)
  #|

///|
test "generate_code_from_query" {
  let query = Query::{
    name: "getUsers",
    parameters: [
      Parameter::{ column: Column::new(name="age", mbt_type="Int") },
      Parameter::{ column: Column::new(name="name", mbt_type="String") },
    ],
    columns: [
      Column::new(name="id", mbt_type="Int64"),
      Column::new(name="username", mbt_type="String"),
    ],
  }
  let code = generate_code_from_query(query)
  inspect(
    code,
    content=(
      #|pub(all)struct ResultOfgetUsers {
      #|  id: Int64;
      #|  username: String;
      #|  
      #|} derive(ToJson, FromJson, Show)
      #|fn getUsers(age: Int,name: String,) -> ResultOfgetUsers {}
    ),
  )
}
