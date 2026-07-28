#!/opt/homebrew/bin/bash

green='\033[0;32m'
red='\033[0;31m'
reset='\033[0m'

error() { echo -e "${red}[ERROR] $*${reset}" >&2; exit 1; }

success() { echo -e "${green}[SUCCESS] $*${reset}"; }
create_db(){
    local db_name="$1"
    [ -z "$db_name" ] && error "You need to provide db name"
    [ -d "$db_name" ] && error "Database '$db_name' already exists"

    mkdir "$db_name" || error "Failed to create database '$db_name'"
    success "Database '$db_name' created"
}

create_table(){
    local db="$1"; shift
    local table_name="$1"; shift
    local cols=("$@")
    local colNum="${#cols[@]}"
    [ -z "$db" ] && error "Databse name cannot be empty"
    [ -d "$db" ] || error "Database '$db' doesn't exist"
    [ "$colNum" -lt 1 ] && error "You must have at least one column"
    [ "$colNum" -gt 4 ] && error "Maximum number of columns is 4"

    [ -z "$table_name" ] && error "Table name cannot be empty"
    [ -f "${table_name}.txt" ] && error "Table '$table_name' already exists"

    touch "${table_name}.txt" || error "Failed to create table '$table_name'"

    echo "### $table_name ###">>"${table_name}.txt"
    echo -n "**">>"${table_name}.txt"
    for name in "${cols[@]}"; do
        printf " %-7.7s**" "$name" >> "${table_name}.txt"
    done    
    success "table '$table_name' created"
}

#** 6 ** 6 ** 7 ** 7 ** 29-

select_data(){
    true
}

insert_data(){
    true
}

delete_data(){
    true
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

