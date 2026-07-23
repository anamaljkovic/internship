#!/opt/homebrew/bin/bash

change_case=false
strings=()
reverse=false
lowercase=false
uppercase=false
input=""
output=""
switch=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s)
            shift
            switch=true
            while [[ $# -gt 0 && "$1" != -* && "$2" != -* ]]; do
                strings+=("$1")
                strings+=("$2")
                shift 2
            done
            ;;
        -v) change_case=true; shift ;;
        -r) reverse=true; shift ;;
        -l) lowercase=true; shift ;;
        -u) uppercase=true; shift ;;
        -i) input="$2"; shift 2 ;;
        -o) output="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done


if [[ -z "$input" && -z "$output" ]];then
    echo "You need to provide input and output files."
    exit 1
elif [[ -z "$input" ]];then
    echo "You need to provide an input file."
    exit 1
elif [[ -z "$output" ]];then
    echo "You need to provide an output file."
    exit 1
fi

if [[ ! -f "$input" ]];then
    echo "The input file does not exist"
    exit 1
fi


if [[ "$input" == "$output" ]];then
    echo "Input and output files must be different"
    exit 1
fi


if [[ "$switch" == true && "${#strings[@]}" -ne 2 ]]; then
    echo "After -s flag you need to provide 2 strings"
    exit 1
fi


while IFS= read -r line || [[ -n "$line" ]]; do

    if $reverse; then
        line=$(echo "$line" | rev)
    fi
    if $change_case; then
        line=$(echo "$line" | tr 'a-zA-Z' 'A-Za-z')
    fi
    if $lowercase; then
        line=$( echo "$line" | tr '[:upper:]' '[:lower:]')
    fi
    if $uppercase; then
        line=$( echo "$line" | tr '[:lower:]' '[:upper:]')
    fi
    
    echo "$line"
done < "$input" > "$output"

if [[ ${#strings[@]} == 2 ]]; then
    sed -i '' "s/${strings[0]}/${strings[1]}/g" "$output"
fi