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
    true
}

create_table(){
    true
}

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