/* name: get_author :one */
SELECT * FROM authors
WHERE id = ? LIMIT 1;

/* name: list_authors :many */
SELECT * FROM authors
ORDER BY name;

/* name: create_author :execresult */
INSERT INTO authors (
  name, bio
) VALUES (
  ?, ? 
);

/* name: delete_author :exec */
DELETE FROM authors
WHERE id = ?;