pub(all)struct ResultOfget_author {
  id: Int;
  name: String;
  bio: String;
  
} derive(ToJson, FromJson, Show)

impl FromRow for ResultOfget_author with from_row(row : @sqlite.Statement) -> ResultOfget_author raise SQLiteError {
  try {
     
      let id = row.column_int(0)
     
      let name = row.column_text(1) |> @encoding/utf8.decode
     
      let bio = row.column_text(2) |> @encoding/utf8.decode
    
    
    ResultOfget_author::{id, name, bio, }
    
  } catch {
    _ => raise SQLiteError::RowConversionError
  }
}
fn get_author(database: @sqlite.Database, id: Int,) -> ResultOfget_author raise SQLiteError {
  let sql = #|SELECT id, name, bio FROM authors
#|WHERE id = ? LIMIT 1
  database
  .query(sql)
  .bind(stmt => {
     stmt.bind_all(to_sql_values([id,])) |> ignore
    let result = stmt.iter().head().map(FromRow::from_row)
    stmt.finalize() |> ignore
    result
  })
  .unwrap_or_error(PrepareStatementError)
}
pub(all)struct ResultOflist_authors {
  id: Int;
  name: String;
  bio: String;
  
} derive(ToJson, FromJson, Show)

impl FromRow for ResultOflist_authors with from_row(row : @sqlite.Statement) -> ResultOflist_authors raise SQLiteError {
  try {
     
      let id = row.column_int(0)
     
      let name = row.column_text(1) |> @encoding/utf8.decode
     
      let bio = row.column_text(2) |> @encoding/utf8.decode
    
    
    ResultOflist_authors::{id, name, bio, }
    
  } catch {
    _ => raise SQLiteError::RowConversionError
  }
}
fn list_authors(database: @sqlite.Database, ) -> Array[ResultOflist_authors] raise SQLiteError {
  let sql = #|SELECT id, name, bio FROM authors
#|ORDER BY name
  database
   .query(sql)
   .map(stmt => {
     
     let result = Array::new()
     for i in stmt.iter() {
       let row = FromRow::from_row(i)
       result.push(row)
     }
     stmt.finalize() |> ignore
     result
   })
   .unwrap_or_error(PrepareStatementError)
}
pub(all)struct ResultOfdelete_author {
  
} derive(ToJson, FromJson, Show)

impl FromRow for ResultOfdelete_author with from_row(row : @sqlite.Statement) -> ResultOfdelete_author raise SQLiteError {
  try {
    
    
    ResultOfdelete_author::{}
    
  } catch {
    _ => raise SQLiteError::RowConversionError
  }
}
fn delete_author(database: @sqlite.Database, id: Int,) -> Unit raise SQLiteError {
 let sql = #|
#|DELETE FROM authors
#|WHERE id = ?
 database
 .prepare(sql)
 .map(stmt => {
    stmt.bind_all(to_sql_values([id,])) |> ignore
   stmt.execute() |> ignore
   stmt.finalize()
 })
 .unwrap_or_error(PrepareStatementError)
}
pub(all)struct ResultOfcrete_author_table {
  
} derive(ToJson, FromJson, Show)

impl FromRow for ResultOfcrete_author_table with from_row(row : @sqlite.Statement) -> ResultOfcrete_author_table raise SQLiteError {
  try {
    
    
    ResultOfcrete_author_table::{}
    
  } catch {
    _ => raise SQLiteError::RowConversionError
  }
}
fn crete_author_table(database: @sqlite.Database, ) -> Unit raise SQLiteError {
 let sql = #|CREATE TABLE authors (
#|          id   integer    PRIMARY KEY AUTOINCREMENT,
#|          name text   NOT NULL,
#|          bio  text
#|)
 database
 .prepare(sql)
 .map(stmt => {
   
   stmt.execute() |> ignore
   stmt.finalize()
 })
 .unwrap_or_error(PrepareStatementError)
}
 ///|
 pub suberror SQLiteError {
   RowConversionError
   PrepareStatementError
 }
 
 ///|
 trait FromRow {
   from_row(row : @sqlite.Statement) -> Self raise SQLiteError
 }
 
 ///|
 trait ToSqlValue {
   to_sql_value(Self) -> @sqlite.SqlValue
 }
 
 ///|
 fn to_sql_values(array : Array[&ToSqlValue]) -> Array[@sqlite.SqlValue] {
   array.map(v => v.to_sql_value())
 }
 
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