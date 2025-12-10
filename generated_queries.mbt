// ///|
// pub suberror SQLiteError {
//   RowConversionError
//   PrepareStatementError
// }

// ///|
// trait FromRow {
//   from_row(row : @sqlite.Statement) -> Self raise SQLiteError
// }

// ///|
// trait ToSqlValue {
//   to_sql_value(Self) -> @sqlite.SqlValue
// }

// ///|
// fn to_sql_values(array : Array[&ToSqlValue]) -> Array[@sqlite.SqlValue] {
//   array.map(v => v.to_sql_value())
// }

// ///|
// impl ToSqlValue for Int64 with to_sql_value(self : Int64) -> @sqlite.SqlValue {
//   @sqlite.SqlValue::Int64(self)
// }

// ///|
// impl ToSqlValue for Int with to_sql_value(self : Int) -> @sqlite.SqlValue {
//   @sqlite.SqlValue::Int(self)
// }

// ///|
// impl ToSqlValue for Double with to_sql_value(self : Double) -> @sqlite.SqlValue {
//   @sqlite.SqlValue::Double(self)
// }

// ///|
// impl ToSqlValue for String with to_sql_value(self : String) -> @sqlite.SqlValue {
//   @sqlite.SqlValue::Text(@encoding/utf8.encode(self))
// }

// ///|
// impl ToSqlValue for Bytes with to_sql_value(self : Bytes) -> @sqlite.SqlValue {
//   @sqlite.SqlValue::Blob(self)
// }

// ///|
// impl[T : ToSqlValue] ToSqlValue for T? with to_sql_value(self : T?) -> @sqlite.SqlValue {
//   match self {
//     Some(value) => value.to_sql_value()
//     None => @sqlite.SqlValue::Null
//   }
// }

// ///|
// pub(all) struct ResultOfget_author {
//   id : Int64
//   name : String
//   bio : String
// } derive(ToJson, FromJson, Show)

// ///|
// impl FromRow for ResultOfget_author with from_row(row : @sqlite.Statement) -> ResultOfget_author raise SQLiteError {
//   let id = row.column_int(0).to_int64()
//   let name = row.column_text(1)
//   let bio = row.column_text(2)
//   ResultOfget_author::{ id, name: name.to_string(), bio: bio.to_string() }
// }

// ///|
// fn get_author(
//   database : @sqlite.Database,
//   id : Int64,
// ) -> ResultOfget_author? raise SQLiteError {
//   database
//   .query("")
//   .bind(stmt => {
//     stmt.bind_all(to_sql_values([id])) |> ignore
//     let result = stmt.iter().head().map(FromRow::from_row)
//     stmt.finalize() |> ignore
//     result
//   })
// }

// ///|
// pub(all) struct ResultOflist_authors {
//   id : Int64
//   name : String
//   bio : String
// } derive(ToJson, FromJson, Show)

// ///|
// impl FromRow for ResultOflist_authors with from_row(row : @sqlite.Statement) -> ResultOflist_authors raise SQLiteError {
//   let id = row.column_int(0).to_int64()
//   let name = row.column_text(1)
//   let bio = row.column_text(2)
//   ResultOflist_authors::{ id, name: name.to_string(), bio: bio.to_string() }
// }

// ///|
// fn list_authors(
//   database : @sqlite.Database,
// ) -> Array[ResultOflist_authors] raise SQLiteError {
//   database
//   .query("")
//   .map(stmt => {
//     // if input is not empty 
//     //  stmt.bind_all(to_sql_values([])) |> ignore
//     let result = Array::new()
//     for i in stmt.iter() {
//       let row = FromRow::from_row(i)
//       result.push(row)
//     }
//     stmt.finalize() |> ignore
//     result
//   })
//   .unwrap_or_error(PrepareStatementError)
// }

// ///|
// pub(all) struct ResultOfcreate_author {} derive(ToJson, FromJson, Show)

// ///|
// fn create_author(
//   database : @sqlite.Database,
//   name : String,
//   bio : String,
// ) -> Unit raise SQLiteError {
//   database
//   .prepare("")
//   .map(stmt => {
//     stmt.bind_all(to_sql_values([name, bio])) |> ignore
//     stmt.execute() |> ignore
//     stmt.finalize()
//   })
//   .unwrap_or_error(PrepareStatementError)
// }

// ///|
// pub(all) struct ResultOfdelete_author {} derive(ToJson, FromJson, Show)

// ///|
// impl FromRow for ResultOfdelete_author with from_row(row : @sqlite.Statement) -> ResultOfdelete_author raise SQLiteError {
//   ResultOfdelete_author::{  }
// }

// ///|
// fn delete_author(id : Int64) -> ResultOfdelete_author {

// }
