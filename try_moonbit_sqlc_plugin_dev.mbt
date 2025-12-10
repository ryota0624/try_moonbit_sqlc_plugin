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

// https://github.com/sqlc-dev/plugin-sdk-go/blob/main/metadata/meta.go#L15-L26

///|
enum Cmd {
  Exec
  ExecResult
  ExecRows
  ExecLastId
  Many
  One
  CopyFrom
  BatchExec
  BatchMany
  BatchOne
} derive(Show)

///|
fn Cmd::from_string(cmd_str : String) -> Cmd raise {
  match cmd_str {
    ":exec" => Cmd::Exec
    ":execresult" => Cmd::ExecResult
    ":execrows" => Cmd::ExecRows
    ":execlastid" => Cmd::ExecLastId
    ":many" => Cmd::Many
    ":one" => Cmd::One
    ":copyfrom" => Cmd::CopyFrom
    ":batchexec" => Cmd::BatchExec
    ":batchmany" => Cmd::BatchMany
    ":batchone" => Cmd::BatchOne
    other => fail("Unknown command: \{other}")
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
  let sqlite_pkg_json =
    #|{
    #|	"import": [
    #|		"mizchi/sqlite"
    #|	]
    #|}
  let pkg_json_file = @plugin.File::new(
    "moon.pkg.json",
    @encoding/utf8.encode(sqlite_pkg_json),
  )
  @plugin.GenerateResponse::new([file, pkg_json_file])
}

///|
let sqlite_utility_code =
  #| ///|
  #| pub suberror SQLiteError {
  #|   RowConversionError
  #|   PrepareStatementError
  #| }
  #| 
  #| ///|
  #| trait FromRow {
  #|   from_row(row : @sqlite.Statement) -> Self raise SQLiteError
  #| }
  #| 
  #| ///|
  #| trait ToSqlValue {
  #|   to_sql_value(Self) -> @sqlite.SqlValue
  #| }
  #| 
  #| ///|
  #| fn to_sql_values(array : Array[&ToSqlValue]) -> Array[@sqlite.SqlValue] {
  #|   array.map(v => v.to_sql_value())
  #| }
  #| 
  #| impl ToSqlValue for Int64 with to_sql_value(self : Int64) -> @sqlite.SqlValue {
  #|   @sqlite.SqlValue::Int64(self)
  #| }
  #| ///|
  #| impl ToSqlValue for Int with to_sql_value(self : Int) -> @sqlite.SqlValue {
  #|   @sqlite.SqlValue::Int(self)
  #| }
  #| ///|
  #| impl ToSqlValue for Double with to_sql_value(self : Double) -> @sqlite.SqlValue {
  #|   @sqlite.SqlValue::Double(self)
  #| }
  #| 
  #| ///|
  #| impl ToSqlValue for String with to_sql_value(self : String) -> @sqlite.SqlValue {
  #|   @sqlite.SqlValue::Text(@encoding/utf8.encode(self))
  #| }
  #| 
  #| ///|
  #| impl ToSqlValue for Bytes with to_sql_value(self : Bytes) -> @sqlite.SqlValue {
  #|   @sqlite.SqlValue::Blob(self)
  #| }
  #| 
  #| ///|
  #| impl[T : ToSqlValue] ToSqlValue for T? with to_sql_value(self : T?) -> @sqlite.SqlValue {
  #|   match self {
  #|     Some(value) => value.to_sql_value()
  #|     None => @sqlite.SqlValue::Null
  #|   }
  #| }

///|
pub fn generate_code(
  generate_request : @plugin.GenerateRequest,
) -> String raise {
  let codes = generate_request.queries
    .map(Query::from_plugin_query(_, engine=generate_request.settings.engine))
    .map(generate_code_from_query)
  codes.push(sqlite_utility_code)
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
  cmd : Cmd
  name : String
  parameters : Array[Parameter]
  columns : Array[Column]
  sql : String
}

///|
fn Query::from_plugin_query(
  plugin_query : @plugin.Query,
  engine~ : String,
) -> Query raise {
  Query::{
    cmd: Cmd::from_string(plugin_query.cmd),
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
    sql: plugin_query.text,
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
    "integer" => "Int"
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
      "fields": query.columns.mapi((index, col) => Json::object({
        "field_name": Json::string(col.name),
        "field_type": Json::string(col.mbt_type),
        "field_extractor_name": Json::string(
          sqlite_field_extractor_name_from_mbt_type(col.mbt_type, index),
        ),
      })),
    }),
  )
  let query_template = match query.cmd {
    Cmd::Many => list_query_template
    Cmd::One => find_one_query_template
    Cmd::Exec => exec_query_template
    other => fail("Unsupported command for code generation: \{other}")
  }
  let sql = query.sql
    .split("\n")
    .map(line => "#|" + line.to_string())
    .join("\n")
  let template_param = {
    "function_name": Json::string(query.name),
    "args": query.parameters.map(param => Json::object({
      "name": Json::string(param.column.name),
      "type": Json::string(param.column.mbt_type),
    }))
    |> Json::array,
    "result_type": Json::string(result_type_name),
    "sql": Json::string(sql),
  }
  let bind_all = if query.parameters.is_empty() {
    ""
  } else {
    @mustache.parse(bind_all_code, Json::object(template_param))
  }
  let query_func = @mustache.parse(
    query_template,
    Json::object(
      template_param.merge({ "bind_all_code": Json::string(bind_all) }),
    ),
  )
  result_struct + query_func
}

///|
fn sqlite_field_extractor_name_from_mbt_type(mbt_type : String, field_index: Int) -> String raise {
  match mbt_type {
    "Int" => "column_int(\{field_index})"
    "Int64" => "column_int64(\{field_index})"
    "Double" => "column_double(\{field_index})"
    "String" => "column_text(\{field_index}) |> @encoding/utf8.decode"
    "Bytes" => "column_blob(\{field_index})"
    other =>
      fail("Unsupported column type for FromRow implementation: \{other}")
  }
}

///|
let bind_all_code =
  #| stmt.bind_all(to_sql_values([{{#args}}{{name}},{{/args}}])) |> ignore

///|
let list_query_template =
  #|fn {{function_name}}(database: @sqlite.Database, {{#args}}{{name}}: {{type}},{{/args}}) -> Array[{{result_type}}] raise SQLiteError {
  #|  let sql = {{{sql}}}
  #|  database
  #|   .query(sql)
  #|   .map(stmt => {
  #|     {{{bind_all_code}}}
  #|     let result = Array::new()
  #|     for i in stmt.iter() {
  #|       let row = FromRow::from_row(i)
  #|       result.push(row)
  #|     }
  #|     stmt.finalize() |> ignore
  #|     result
  #|   })
  #|   .unwrap_or_error(PrepareStatementError)
  #|}

///|
let find_one_query_template =
  #|fn {{function_name}}(database: @sqlite.Database, {{#args}}{{name}}: {{type}},{{/args}}) -> {{result_type}} raise SQLiteError {
  #|  let sql = {{{sql}}}
  #|  database
  #|  .query(sql)
  #|  .bind(stmt => {
  #|    {{{bind_all_code}}}
  #|    let result = stmt.iter().head().map(FromRow::from_row)
  #|    stmt.finalize() |> ignore
  #|    result
  #|  })
  #|  .unwrap_or_error(PrepareStatementError)
  #|}

///|
let exec_query_template =
  #|fn {{function_name}}(database: @sqlite.Database, {{#args}}{{name}}: {{type}},{{/args}}) -> Unit raise SQLiteError {
  #| let sql = {{{sql}}}
  #| database
  #| .prepare(sql)
  #| .map(stmt => {
  #|   {{{bind_all_code}}}
  #|   stmt.execute() |> ignore
  #|   stmt.finalize()
  #| })
  #| .unwrap_or_error(PrepareStatementError)
  #|}

///|
let result_type_struct_template =
  #|pub(all)struct {{struct_name}} {
  #|  {{#fields}}{{field_name}}: {{field_type}};
  #|  {{/fields}}
  #|} derive(ToJson, FromJson, Show)
  #|
  #|impl FromRow for {{struct_name}} with from_row(row : @sqlite.Statement) -> {{struct_name}} raise SQLiteError {
  #|  try {
  #|    {{#fields}} 
  #|      let {{field_name}} = row.{{{field_extractor_name}}}
  #|    {{/fields}}
  #|    {{=<% %>=}}
  #|    <%struct_name%>::{<%#fields%><%field_name%>, <%/fields%>}
  #|    <%={{ }}=%>
  #|  } catch {
  #|    _ => raise SQLiteError::RowConversionError
  #|  }
  #|}
  #|

///|
test "generate_code_from_query" {
  let query = Query::{
    name: "listUsers",
    parameters: [
      Parameter::{ column: Column::new(name="age", mbt_type="Int") },
      Parameter::{ column: Column::new(name="name", mbt_type="String") },
    ],
    columns: [
      Column::new(name="id", mbt_type="Int64"),
      Column::new(name="username", mbt_type="String"),
    ],
    cmd: Cmd::Many,
    sql: "SELECT id, username FROM users WHERE age > ? AND name = ?",
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
      #|fn listUsers(age: Int,name: String,) -> ResultOflistUsers {}
    ),
  )
}
