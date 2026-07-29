#!/opt/homebrew/bin/bash

green='\033[0;32m'
red='\033[0;31m'
reset='\033[0m'
error() { echo -e "${red}[ERROR] $*${reset}" >&2; exit 1; }

success() { echo -e "${green}[SUCCESS] $*${reset}"; }

db_check(){
    local db="$1"
    [ -z "$db" ] && error "Database name cannot be empty"
    [ -f "${db}.txt" ] || error "Database '$db' doesn't exist"
}

cols_check(){
    local colNum="$1"
    [ "$colNum" -lt 1 ] && error "You must have at least one column"
    [ "$colNum" -gt 4 ] && error "Maximum number of columns is 4"
}

table_col_count(){
    local db="$1" table="$2"
    awk -v t="### ${table} ###" '
        $0==t { getline; print NF-2; exit }  # NF-2 strips the two ** tokens
    ' "${db}.txt"
}

format_row(){
    local -a fields=("$@")
    local out="**"
    for f in "${fields[@]}"; do
        out+=" $(printf '%-7.7s' "$f")"
    done
    echo "${out} **"
}

table_check(){
    local db="$1" table="$2"
    grep -q "^### ${table} ###\$" "${db}.txt" || error "Table '$table' doesn't exist"
}

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

create_db(){
    local db_name="$1"
    [ -z "$db_name" ] && error "You need to provide db name"
    [ -f "${db_name}.txt" ] && error "Database '$db_name' already exists"

    touch "${db_name}.txt" || error "Failed to create database '$db_name'"
    success "Database '$db_name' created"
}

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

select_data(){
    true
}

insert_data(){
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

#make one function that will do the checking for db and table existence
#use awk to see which column is id in the table
#use awk for checkin how many cols has a table when inserting data


delete_data(){
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
        *) error "Uknown command: $1" ;;
    esac
}


main "$@"

