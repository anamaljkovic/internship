##

A database implemented in Bash. Each database is a single `.txt` file, tables are stored as blocks within it.

## Usage


./database.sh <command> [arguments]


| Command | Arguments | Description |
|---|---|---|
| `create_db` | `<db_name>` | Create a new database |
| `create_table` | `<db_name> <table_name> <field1> [field2 ...]` | Create a table (max 4 fields) |
| `insert_data` | `<db_name> <table_name> <val1> [val2 ...]` | Insert a row |
| `select_data` | `<db_name> <table_name>` | Show all rows in a table |
| `delete_data` | `<db_name> <table_name> <field>=<value>` | Delete rows matching field=value |
| `help` | — | Show usage |

## Example

```
./database.sh create_db example_db
./database.sh create_table example_db persons id name height age
./database.sh insert_data example_db persons 0 Igor 180 36
./database.sh insert_data example_db persons 1 Pyotr 178 25
./database.sh select_data example_db persons
./database.sh delete_data example_db persons "id=1"
```

## File format

Each database is one file (`<db_name>.txt`). Tables are separated by a blank line:

```
### persons ###
** id      name    height  age     **
** 0       Igor    180     36      **

### idk ###
** id      hehe    nzm     **
** 0       1       180     **

- Each row is wrapped in `**` markers with one leading space before text.
- Field content is truncated to 7 characters (8 chars including the leading space).
- Max 4 fields per table, keeping every line within 39 characters.

## Notes

- Field and value names longer than 7 characters are rejected.
- Errors print a message and exit with status 1.


