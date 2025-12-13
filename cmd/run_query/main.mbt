///|
fn main {
  let db = match @sqlite.Database::open(":memory:") {
    Some(d) => d
    None => {
      println("Failed to open database")
      return
    }
  }
  println("Database opened successfully")
  try {
    @lib.create_author_table(db) |> ignore
    @lib.create_author(db, 1, "John Doe", None) |> ignore
    @lib.create_author(db, 12, "D Doe", Some("hou")) |> ignore
    @lib.list_authors(db)
    .iter()
    .each(author => println(
      "Author ID: \{author.id}, Name: \{author.name}, Bio: \{author.bio}",
    ))
  } catch {
    err => {
      abort("Error: \{err}")
    }
  }
}
