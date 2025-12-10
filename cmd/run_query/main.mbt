///|
fn main {
  let db = match @sqlite.Database::open("my_database.db") {
    Some(d) => d
    None => {
      println("Failed to open database")
      return
    }
  }
  try {
    // @lib.create_author_table(db) |> ignore
    // @lib.create_author(db, 1, "John Doe", None) |> ignore
		//     @lib.create_author(db, 12, "D Doe", Some("hou")) |> ignore

    @lib.list_authors(db)
    .iter()
    .each(author => println(
      "Author ID: \{author.id}, Name: \{author.name}, Bio: \{author.bio}",
    ))
  } catch {
    err => {
      println("Error creating author table: \{err}")
      return
    }
  }
  println("Author table created successfully")
}
