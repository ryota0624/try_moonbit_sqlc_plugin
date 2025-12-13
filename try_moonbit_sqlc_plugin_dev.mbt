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
priv enum Cmd {
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
  let query_file = @plugin.File::new(
    "queries.mbt",
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
  let utility_code_file = @plugin.File::new(
    "sqlite_utility.mbt",
    @encoding/utf8.encode(
      sqlite_utility_code_error +
      sqlite_utility_code_to_sql_value +
      sqlite_utility_code_from_sql_value,
    ),
  )
  @plugin.GenerateResponse::new([query_file, utility_code_file, pkg_json_file])
}

///|
let sqlite_utility_code_error =
  #| ///|
  #|pub suberror SQLiteError {
  #|  RowConversionError(ColumnExtractionError)
  #|  PrepareStatementError
  #|} derive(Show)
  #|
  #| ///|
  #|pub suberror ColumnExtractionError (Int, String) derive(Show)
  #|
  #|///|
  #|fn sqlValueTypeName(value : @sqlite.SqlValue) -> String {
  #|  match value {
  #|    @sqlite.SqlValue::Null => "Null"
  #|    @sqlite.SqlValue::Int(_) => "Int"
  #|    @sqlite.SqlValue::Int64(_) => "Int64"
  #|    @sqlite.SqlValue::Double(_) => "Double"
  #|    @sqlite.SqlValue::Text(_) => "Text"
  #|    @sqlite.SqlValue::Blob(_) => "Blob"
  #|  }
  #|}

///|

///|
let sqlite_utility_code_to_sql_value =
  #| ///|
  #|priv trait FromRow {
  #|   from_row(row : @sqlite.Statement) -> Self raise SQLiteError
  #|}
  #| 
  #| ///|
  #|priv trait ToSqlValue {
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
  #|
  #|

///|

///|
let sqlite_utility_code_from_sql_value =
  #| priv struct SqliteStatement(@sqlite.Statement)
  #| 
  #| ///|
  #| fn[T : FromSqlValue] SqliteStatement::column(
  #|   self : SqliteStatement,
  #|   index : Int,
  #| ) -> T raise ColumnExtractionError {
  #|   from_sql_value(self.0.column(index), index)
  #| }
  #| 
  #| ///|
  #| priv trait FromSqlValue {
  #|   from_sql_value(value : @sqlite.SqlValue, columnIndex : Int) -> Self raise ColumnExtractionError
  #| }
  #| 
  #| ///|
  #| impl FromSqlValue for String with from_sql_value(
  #|   value : @sqlite.SqlValue,
  #|   columnIndex : Int,
  #| ) -> String raise ColumnExtractionError {
  #|   match value {
  #|     @sqlite.SqlValue::Text(bytes) => {
  #|       let text = try? (bytes |> @encoding/utf8.decode)
  #|       text
  #|       .map_err(_ => ColumnExtractionError((columnIndex, "utf8 decode error")))
  #|       .unwrap_or_error()
  #|     }
  #|     a =>
  #|       raise ColumnExtractionError(
  #|         (columnIndex, "type mismatch actual \{sqlValueTypeName(a)}"),
  #|       )
  #|   }
  #| }
  #| 
  #| ///|
  #| impl FromSqlValue for Int with from_sql_value(
  #|   value : @sqlite.SqlValue,
  #|   columnIndex : Int,
  #| ) -> Int raise ColumnExtractionError {
  #|   match value {
  #|     @sqlite.SqlValue::Int(v) => v
  #|     @sqlite.SqlValue::Int64(v) => v.to_int()
  #|     _ =>
  #|       raise ColumnExtractionError(
  #|         (columnIndex, "type mismatch actual \{sqlValueTypeName(value)}"),
  #|       )
  #|   }
  #| }
  #| 
  #| ///|
  #| impl FromSqlValue for Double with from_sql_value(
  #|   value : @sqlite.SqlValue,
  #|   columnIndex : Int,
  #| ) -> Double raise ColumnExtractionError {
  #|   match value {
  #|     @sqlite.SqlValue::Double(v) => v
  #|     _ =>
  #|       raise ColumnExtractionError(
  #|         (columnIndex, "type mismatch actual \{sqlValueTypeName(value)}"),
  #|       )
  #|   }
  #| }
  #| 
  #| ///|
  #| impl FromSqlValue for Bytes with from_sql_value(
  #|   value : @sqlite.SqlValue,
  #|   columnIndex : Int,
  #| ) -> Bytes raise ColumnExtractionError {
  #|   match value {
  #|     @sqlite.SqlValue::Blob(v) => v
  #|     _ =>
  #|       raise ColumnExtractionError(
  #|         (columnIndex, "type mismatch actual \{sqlValueTypeName(value)}"),
  #|       )
  #|   }
  #| }
  #| 
  #| ///|
  #| impl FromSqlValue for Int64 with from_sql_value(
  #|   value : @sqlite.SqlValue,
  #|   columnIndex : Int,
  #| ) -> Int64 raise ColumnExtractionError {
  #|   match value {
  #|     @sqlite.SqlValue::Int64(v) => v
  #|     _ =>
  #|       raise ColumnExtractionError(
  #|         (columnIndex, "type mismatch actual \{sqlValueTypeName(value)}"),
  #|       )
  #|   }
  #| }
  #| 
  #| ///|
  #| impl[T : FromSqlValue] FromSqlValue for T? with from_sql_value(
  #|   value : @sqlite.SqlValue,
  #|   columnIndex : Int,
  #| ) -> T? raise ColumnExtractionError {
  #|   if value is @sqlite.SqlValue::Null {
  #|     None
  #|   } else {
  #|     Some(FromSqlValue::from_sql_value(value, columnIndex))
  #|   }
  #| }
  #| 
  #| ///|
  #| fn[T : FromSqlValue] from_sql_value(
  #|   value : @sqlite.SqlValue,
  #|   columnIndex : Int,
  #| ) -> T raise ColumnExtractionError {
  #|   FromSqlValue::from_sql_value(value, columnIndex)
  #| }
  #|

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
        mbt_type=plugin_column_type_to_mbt_type(
          engine,
          param.column.type_,
          param.column.not_null,
        ),
      ),
    }),
    columns: plugin_query.columns.map(col => Column::new(
      name=col.name,
      mbt_type=plugin_column_type_to_mbt_type(engine, col.type_, col.not_null),
    )),
    sql: plugin_query.text,
  }
}

///|
fn plugin_column_type_to_mbt_type(
  engine : String,
  plugin_type : @plugin.Identifier,
  is_not_null : Bool,
) -> String raise {
  match engine {
    "sqlite" => sqlite_plugin_column_type_to_mbt_type(plugin_type, is_not_null)
    other => fail("Unsupported engine: \{other}")
  }
}

///|
fn sqlite_plugin_column_type_to_mbt_type(
  identifier : @plugin.Identifier,
  is_not_null : Bool,
) -> String raise {
  let t = match identifier.name {
    "integer" => "Int"
    "text" => "String"
    other => fail("Unsupported SQLite column type: \{other}")
  }
  if is_not_null {
    t
  } else {
    "Option[\{t}]"
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
          ["row", sqlite_field_extractor_name_from_mbt_type(index)].join("|>"),
        ),
      })),
      "is_columns_empty": Json::boolean(query.columns.is_empty()),
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
fn sqlite_field_extractor_name_from_mbt_type(field_index : Int) -> String {
  "SqliteStatement::column(\{field_index})"
}

///|
let bind_all_code =
  #| stmt.bind_all(to_sql_values([{{#args}}{{name}},{{/args}}])) |> ignore

///|
let list_query_template =
  #|pub fn {{function_name}}(database: @sqlite.Database, {{#args}}{{name}}: {{type}},{{/args}}) -> Array[{{result_type}}] raise SQLiteError {
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
  #|pub fn {{function_name}}(database: @sqlite.Database, {{#args}}{{name}}: {{type}},{{/args}}) -> {{result_type}} raise SQLiteError {
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
  #|pub fn {{function_name}}(database: @sqlite.Database, {{#args}}{{name}}: {{type}},{{/args}}) -> Unit raise SQLiteError {
  #| let sql = {{{sql}}}
  #| database
  #| .prepare(sql)
  #| .map(stmt => {
  #|   {{{bind_all_code}}}
  #|   // TODO: execute=falseの時の考慮
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
  #|  {{^is_columns_empty}}
  #|  try {
  #|    let row = SqliteStatement(row) 
  #|  {{/is_columns_empty}}
  #|    {{#fields}}
  #|    let {{field_name}} = {{{field_extractor_name}}}
  #|    {{/fields}}
  #|    {{=<% %>=}}
  #|    <%struct_name%>::{<%#fields%><%field_name%>, <%/fields%>}
  #|    <%={{ }}=%>
  #|  {{^is_columns_empty}}
  #|  } catch {
  #|    e => raise SQLiteError::RowConversionError(e)
  #|  }
  #|  {{/is_columns_empty}}
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
