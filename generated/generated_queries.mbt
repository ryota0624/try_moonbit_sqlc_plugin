pub(all)struct ResultOfget_author {
  id: Int64;
  name: String;
  bio: String;
  
} derive(ToJson, FromJson, Show)
fn get_author(id: Int64,) -> ResultOfget_author {}
pub(all)struct ResultOflist_authors {
  id: Int64;
  name: String;
  bio: String;
  
} derive(ToJson, FromJson, Show)
fn list_authors() -> ResultOflist_authors {}
pub(all)struct ResultOfcreate_author {
  
} derive(ToJson, FromJson, Show)
fn create_author(name: String,bio: String,) -> ResultOfcreate_author {}
pub(all)struct ResultOfdelete_author {
  
} derive(ToJson, FromJson, Show)
fn delete_author(id: Int64,) -> ResultOfdelete_author {}