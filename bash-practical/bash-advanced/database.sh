#!/usr/bin/env bash

green='\033[0;32m'
red='\033[0;31m'
reset='\033[0m'
error() { echo -e "${red}[ERROR] $*${reset}" >&2; exit 1; }

success() { echo -e "${green}[SUCCESS] $*${reset}"; }

# usage
# prints command list and examples

usage(){
    cat <<EOF
Usage: ./database.sh <command> [arguments]

Commands:
  create_db <db_name>
      Create a new database file (<db_name>.txt).

  create_table <db_name> <table_name> <field1> [field2 ... field4]
      Create a new table inside the database. Max 4 fields.

  insert_data <db_name> <table_name> <val1> [val2 ...]
      Insert a new row into the table. Number of values must match
      the number of fields defined for that table.

  select_data <db_name> <table_name>
      Display all rows from the table, including the header.

  delete_data <db_name> <table_name> <field>=<value>
      Delete all rows where <field> equals <value>.

Examples:
  ./database.sh create_db example_db
  ./database.sh create_table example_db persons id name height age
  ./database.sh insert_data example_db persons 0 Igor 180 36
  ./database.sh select_data example_db persons
  ./database.sh delete_data example_db persons "id=1"
EOF
}

# db_check db
# validates db name is not empty and db.txt exists or throws an error

db_check(){
    local db="$1"
    [ -z "$db" ] && error "Database name cannot be empty"
    [ -f "${db}.txt" ] || error "Database '$db' doesn't exist"
}

# cols_check col_count
# validates column count is between 1 and 4 

cols_check(){
    local colNum="$1"
    [ "$colNum" -lt 1 ] && error "You must have at least one column"
    [ "$colNum" -gt 4 ] && error "Maximum number of columns is 4"
}

# table_col_count db table
# prints the number of data cols defined in table's header row

table_col_count(){
    local db="$1" table="$2"
    awk -v t="### ${table} ###" '
        $0==t { getline; print NF-2; exit }  # NF-2 strips the two ** tokens
    ' "${db}.txt"
}

# format_row val1 val2 ...
# formats values into "** val1    val2    ... **"; each field
# padded to 8 chars (7chars+space)

format_row(){
    local -a fields=("$@")
    local out="**"
    for f in "${fields[@]}"; do
        [ "${#f}" -gt 7 ] && error "value '$f' exceeds max len of 7 chars"
        out+=" $(printf '%-7.7s' "$f")"
    done
    echo "${out} **"
}

# table_check db table
# validates that table exists within db.txt or throws an error

table_check(){
    local db="$1" table="$2"
    grep -q "^### ${table} ###\$" "${db}.txt" || error "Table '$table' doesn't exist"
}

# key_col_index db table key
# prints the column index of key in table's header or 0 if not found

key_col_index(){
    local db="$1" table="$2" key="$3"
    local file="${db}.txt"

    local start_line
    start_line=$(grep -n "^### ${table} ###\$" "$file" | cut -d: -f1)

    awk -v s="$start_line" -v k="$key" '
        NR == s+1 {
            for (i=2; i<NF; i++) {
                if ($i == k) {
                    print i
                    exit
                }
            }
            print "0"   # not found
            exit
        }
    ' "$file"
}

# create_db db_name
# Creates a new empty database file db_name.txt.

create_db(){
    local db_name="$1"
    [ -z "$db_name" ] && error "You need to provide db name"
    [ -f "${db_name}.txt" ] && error "Database '$db_name' already exists"

    touch "${db_name}.txt" || error "Failed to create database '$db_name'"
    success "Database '$db_name' created"
}

# create_table db table field1 field2 ...
# appends a new table to the end of <db>.txt.

create_table(){
    local db="$1"; shift
    local table_name="$1"; shift
    local cols=("$@")
    db_check "$db"
    cols_check "${#cols[@]}"
    [ -z "$table_name" ] && error "Table name cannot be empty"

    local file="${db}.txt"
    if grep -q "^### ${table_name} ###\$" "$file"; then
        error "Table ${table_name} already exists"
    fi

    {
        echo "### ${table_name} ###"
        format_row "${cols[@]}"
        echo ""
    } >> "$file"

    success "table '$table_name' created"
}

# select_data db table
# prints the header and all data  belonging to table

select_data(){
    [ "$#" -lt 2 ] && error "Usage: select_data <db> <table>"
    local db="$1"
    local table="$2"

    db_check "$db"
    table_check "$db" "$table"

    local file="${db}.txt"

    local start_line
    start_line=$(grep -n "^### ${table} ###\$" "$file" | cut -d: -f1)

    local blank_line
    blank_line=$(awk -v s="$start_line" 'NR>s && $0=="" {print NR; exit}' "$file")
    [ -z "$blank_line" ] && error "Table '$table' block is malformed"

    local data_start=$((start_line + 2))
    local data_end=$((blank_line - 1))

    echo "Table: $table"

    head -n "$((start_line + 1))" "$file" | tail -n 1

    if [ "$data_end" -ge "$data_start" ]; then
        tail -n +"$data_start" "$file" | head -n "$((data_end - data_start + 1))"
    else
        echo "(no rows)"
    fi
}

# insert_data db table val1 val2 ...
# validates if the value count matches the columns count
# inserts a new formatted row at the end of table's block

insert_data(){
    [ "$#" -lt 3 ] && error "Usage: insert_data <db> <table> <val1> <valn>"
    local db="$1"; shift
    local table="$1"; shift
    local vals=("$@")
    db_check "$db"
    table_check "$db" "$table"

    local expected
    expected=$(table_col_count "$db" "$table")
    [ "${#vals[@]}" -ne "$expected" ] && error "Expected $expected vals, got ${#vals[@]}"

    local file="${db}.txt"
    local new_row
    new_row=$(format_row "${vals[@]}")

    local start_line
    start_line=$(grep -n "^### ${table} ###\$" "$file" | cut -d: -f1)

    local blank_line
    blank_line=$(awk -v s="$start_line" 'NR>s && $0=="" {print NR; exit}' "$file")
    [ -z "$blank_line" ] && error "Error within a file - missing newline"

    local insert_at=$((blank_line - 1))

    local tmp
    tmp=$(mktemp)
    head -n "$insert_at" "$file" > "$tmp"
    echo "$new_row" >> "$tmp"
    tail -n +"$((insert_at + 1))" "$file" >> "$tmp"
    mv "$tmp" "$file"

    success "row added to '$table' table"
}

#todo
#make one function that will do the checking for db and table existence
#use awk to see which column is id in the table
#use awk for checkin how many cols has a table when inserting data

# delete_data db table key=value
# removes all rows where key equals value by remaking
# the file with those rows excluded


delete_data(){
    [ "$#" -lt 3 ] && error "Usage: delete_data <db> <table> <val1>=<val2>"
    local db="$1"
    local table="$2"
    local target="$3"

    db_check "$db"
    table_check "$db" "$table"

    if [[ "$target" != *"="* ]]; then
        error "Wrong format for delete command -> delete_data db table key=value"
    fi

    local key="${target%%=*}"
    local value="${target#*=}"
    local file="${db}.txt"

    local col_index
    col_index=$(key_col_index "$db" "$table" "$key")
    [ "$col_index" -eq 0 ] && error "There is no column '$key' in '$table' table"

    local start_line
    start_line=$(grep -n "^### ${table} ###\$" "$file" | cut -d: -f1)

    local blank_line
    blank_line=$(awk -v s="$start_line" 'NR>s && $0=="" {print NR; exit}' "$file")
    [ -z "$blank_line" ] && error "Error within a file - missing newline"

    local data_start=$((start_line + 2))
    local data_end=$((blank_line - 1))

    local tmp
    tmp=$(mktemp)

    head -n "$((data_start - 1))" "$file" > "$tmp"

    local deleted=0
    if [ "$data_end" -ge "$data_start" ]; then
        while IFS= read -r line; do
            local cell
            cell=$(echo "$line" | awk -v c="$col_index" '{print $c}')
            if [ "$cell" == "$value" ]; then
                deleted=$((deleted + 1))
                continue
            fi
            echo "$line" >> "$tmp"
        done < <(tail -n +"$data_start" "$file" | head -n "$((data_end - data_start + 1))")
    fi

    tail -n +"$blank_line" "$file" >> "$tmp"

    mv "$tmp" "$file"

    [ "$deleted" -eq 0 ] && echo "No rows matched $key=$value" || success "Deleted $deleted row(s) from '$table'"
}

main(){
    case "$1" in
        error) shift; error "$@" ;;
        create_db) shift; create_db "$@" ;;
        create_table) shift; create_table "$@" ;;
        select_data) shift; select_data "$@" ;;
        insert_data) shift; insert_data "$@" ;;
        delete_data) shift; delete_data "$@" ;;
        help) usage;;
        *) error "Uknown command: $1" ;;
    esac
}


main "$@"

