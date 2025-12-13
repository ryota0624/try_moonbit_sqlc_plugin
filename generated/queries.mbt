pub(all)struct ResultOfget_author {
  id: Int;
  name: String;
  bio: Option[String];
  
} derive(ToJson, FromJson, Show)

impl FromRow for ResultOfget_author with from_row(row : @sqlite.Statement) -> ResultOfget_author raise SQLiteError {
  try {
    let row = SqliteStatement(row)
     
    let id = row|>SqliteStatement::column(0)
     
    let name = row|>SqliteStatement::column(1)
     
    let bio = row|>SqliteStatement::column(2)
    
    
    ResultOfget_author::{id, name, bio, }
    
  } catch {
    e => raise SQLiteError::RowConversionError(e)
  }
}
pub fn get_author(database: @sqlite.Database, id: Int,) -> ResultOfget_author raise SQLiteError {
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
  bio: Option[String];
  
} derive(ToJson, FromJson, Show)

impl FromRow for ResultOflist_authors with from_row(row : @sqlite.Statement) -> ResultOflist_authors raise SQLiteError {
  try {
    let row = SqliteStatement(row)
     
    let id = row|>SqliteStatement::column(0)
     
    let name = row|>SqliteStatement::column(1)
     
    let bio = row|>SqliteStatement::column(2)
    
    
    ResultOflist_authors::{id, name, bio, }
    
  } catch {
    e => raise SQLiteError::RowConversionError(e)
  }
}
pub fn list_authors(database: @sqlite.Database, ) -> Array[ResultOflist_authors] raise SQLiteError {
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
pub(all)struct ResultOfcreate_author {
  
} derive(ToJson, FromJson, Show)

impl FromRow for ResultOfcreate_author with from_row(row : @sqlite.Statement) -> ResultOfcreate_author raise SQLiteError {
  try {
    let row = SqliteStatement(row)
    
    
    ResultOfcreate_author::{}
    
  } catch {
    e => raise SQLiteError::RowConversionError(e)
  }
}
pub fn create_author(database: @sqlite.Database, id: Int,name: String,bio: Option[String],) -> Unit raise SQLiteError {
 let sql = #|
#|INSERT INTO authors (
#|  id, name, bio
#|) VALUES (
#|  ?, ?, ? 
#|)
 database
 .prepare(sql)
 .map(stmt => {
    stmt.bind_all(to_sql_values([id,name,bio,])) |> ignore
   // TODO: execute=falseの時の考慮
   stmt.execute() |> ignore
   stmt.finalize()
 })
 .unwrap_or_error(PrepareStatementError)
}
pub(all)struct ResultOfdelete_author {
  
} derive(ToJson, FromJson, Show)

impl FromRow for ResultOfdelete_author with from_row(row : @sqlite.Statement) -> ResultOfdelete_author raise SQLiteError {
  try {
    let row = SqliteStatement(row)
    
    
    ResultOfdelete_author::{}
    
  } catch {
    e => raise SQLiteError::RowConversionError(e)
  }
}
pub fn delete_author(database: @sqlite.Database, id: Int,) -> Unit raise SQLiteError {
 let sql = #|DELETE FROM authors
#|WHERE id = ?
 database
 .prepare(sql)
 .map(stmt => {
    stmt.bind_all(to_sql_values([id,])) |> ignore
   // TODO: execute=falseの時の考慮
   stmt.execute() |> ignore
   stmt.finalize()
 })
 .unwrap_or_error(PrepareStatementError)
}
pub(all)struct ResultOfcreate_author_table {
  
} derive(ToJson, FromJson, Show)

impl FromRow for ResultOfcreate_author_table with from_row(row : @sqlite.Statement) -> ResultOfcreate_author_table raise SQLiteError {
  try {
    let row = SqliteStatement(row)
    
    
    ResultOfcreate_author_table::{}
    
  } catch {
    e => raise SQLiteError::RowConversionError(e)
  }
}
pub fn create_author_table(database: @sqlite.Database, ) -> Unit raise SQLiteError {
 let sql = #|CREATE TABLE authors (
#|          id   integer    PRIMARY KEY AUTOINCREMENT,
#|          name text   NOT NULL,
#|          bio  text
#|)
 database
 .prepare(sql)
 .map(stmt => {
   
   // TODO: execute=falseの時の考慮
   stmt.execute() |> ignore
   stmt.finalize()
 })
 .unwrap_or_error(PrepareStatementError)
}