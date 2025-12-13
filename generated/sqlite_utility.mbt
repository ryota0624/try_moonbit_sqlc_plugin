///|
pub suberror SQLiteError {
  RowConversionError(ColumnExtractionError)
  PrepareStatementError
  QueryExecutionError
} derive(Show)

///|
pub suberror ColumnExtractionError (Int, String) derive(Show)

///|
fn sqlValueTypeName(value : @sqlite.SqlValue) -> String {
  match value {
    @sqlite.SqlValue::Null => "Null"
    @sqlite.SqlValue::Int(_) => "Int"
    @sqlite.SqlValue::Int64(_) => "Int64"
    @sqlite.SqlValue::Double(_) => "Double"
    @sqlite.SqlValue::Text(_) => "Text"
    @sqlite.SqlValue::Blob(_) => "Blob"
  }
}

///|
fn execute_statement(stmt : @sqlite.Statement) -> Unit raise SQLiteError {
  let result = stmt.execute()
  stmt.finalize() |> ignore
  if !result {
    raise SQLiteError::QueryExecutionError
  }
} ///|

///|
priv trait FromRow {
  from_row(row : @sqlite.Statement) -> Self raise SQLiteError
}

///|
priv trait ToSqlValue {
  to_sql_value(Self) -> @sqlite.SqlValue
}

///|
fn to_sql_values(array : Array[&ToSqlValue]) -> Array[@sqlite.SqlValue] {
  array.map(v => v.to_sql_value())
}

///|
impl ToSqlValue for Int64 with to_sql_value(self : Int64) -> @sqlite.SqlValue {
  @sqlite.SqlValue::Int64(self)
}

///|
impl ToSqlValue for Int with to_sql_value(self : Int) -> @sqlite.SqlValue {
  @sqlite.SqlValue::Int(self)
}

///|
impl ToSqlValue for Double with to_sql_value(self : Double) -> @sqlite.SqlValue {
  @sqlite.SqlValue::Double(self)
}

///|
impl ToSqlValue for String with to_sql_value(self : String) -> @sqlite.SqlValue {
  @sqlite.SqlValue::Text(@encoding/utf8.encode(self))
}

///|
impl ToSqlValue for Bytes with to_sql_value(self : Bytes) -> @sqlite.SqlValue {
  @sqlite.SqlValue::Blob(self)
}

///|
impl[T : ToSqlValue] ToSqlValue for T? with to_sql_value(self : T?) -> @sqlite.SqlValue {
  match self {
    Some(value) => value.to_sql_value()
    None => @sqlite.SqlValue::Null
  }
}

///|
priv struct SqliteStatement(@sqlite.Statement)

///|
fn[T : FromSqlValue] SqliteStatement::column(
  self : SqliteStatement,
  index : Int,
) -> T raise ColumnExtractionError {
  from_sql_value(self.0.column(index), index)
}

///|
priv trait FromSqlValue {
  from_sql_value(value : @sqlite.SqlValue, columnIndex : Int) -> Self raise ColumnExtractionError
}

///|
impl FromSqlValue for String with from_sql_value(
  value : @sqlite.SqlValue,
  columnIndex : Int,
) -> String raise ColumnExtractionError {
  match value {
    @sqlite.SqlValue::Text(bytes) => {
      let text = try? (bytes |> @encoding/utf8.decode)
      text
      .map_err(_ => ColumnExtractionError((columnIndex, "utf8 decode error")))
      .unwrap_or_error()
    }
    a =>
      raise ColumnExtractionError(
        (columnIndex, "type mismatch actual \{sqlValueTypeName(a)}"),
      )
  }
}

///|
impl FromSqlValue for Int with from_sql_value(
  value : @sqlite.SqlValue,
  columnIndex : Int,
) -> Int raise ColumnExtractionError {
  match value {
    @sqlite.SqlValue::Int(v) => v
    @sqlite.SqlValue::Int64(v) => v.to_int()
    _ =>
      raise ColumnExtractionError(
        (columnIndex, "type mismatch actual \{sqlValueTypeName(value)}"),
      )
  }
}

///|
impl FromSqlValue for Double with from_sql_value(
  value : @sqlite.SqlValue,
  columnIndex : Int,
) -> Double raise ColumnExtractionError {
  match value {
    @sqlite.SqlValue::Double(v) => v
    _ =>
      raise ColumnExtractionError(
        (columnIndex, "type mismatch actual \{sqlValueTypeName(value)}"),
      )
  }
}

///|
impl FromSqlValue for Bytes with from_sql_value(
  value : @sqlite.SqlValue,
  columnIndex : Int,
) -> Bytes raise ColumnExtractionError {
  match value {
    @sqlite.SqlValue::Blob(v) => v
    _ =>
      raise ColumnExtractionError(
        (columnIndex, "type mismatch actual \{sqlValueTypeName(value)}"),
      )
  }
}

///|
impl FromSqlValue for Int64 with from_sql_value(
  value : @sqlite.SqlValue,
  columnIndex : Int,
) -> Int64 raise ColumnExtractionError {
  match value {
    @sqlite.SqlValue::Int64(v) => v
    _ =>
      raise ColumnExtractionError(
        (columnIndex, "type mismatch actual \{sqlValueTypeName(value)}"),
      )
  }
}

///|
impl[T : FromSqlValue] FromSqlValue for T? with from_sql_value(
  value : @sqlite.SqlValue,
  columnIndex : Int,
) -> T? raise ColumnExtractionError {
  if value is @sqlite.SqlValue::Null {
    None
  } else {
    Some(FromSqlValue::from_sql_value(value, columnIndex))
  }
}

///|
fn[T : FromSqlValue] from_sql_value(
  value : @sqlite.SqlValue,
  columnIndex : Int,
) -> T raise ColumnExtractionError {
  FromSqlValue::from_sql_value(value, columnIndex)
}
