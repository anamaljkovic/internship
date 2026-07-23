#!/opt/homebrew/bin/bash

# %03o turning numbers to chars

shift=0
input=""
output=""
pos=true

while getopts "s:i:o:" opt; do
    case $opt in 
        s) shift="$OPTARG" ;;
        i) input="$OPTARG" ;;
        o) output="$OPTARG" ;;
        \?)echo "Invalid option -> -s -i -o are usable flags" >&2 ;exit 1 ;;
    esac
done

if [[ -z "$shift" || -z "$input" || -z "$output" ]]; then
    echo "-s <shift> -i <input> -o <output> are all required"
    exit 1
fi

if [[ ! "$shift" =~ 0|(^-?[1-9]+[0-9]*$) ]]; then
    echo "You need to put a number"
    exit 1;
else
    shift=$((shift%26))
fi

if [[ "$input" == "$output" ]];then
    echo "input file can't be the same as the output one"
    exit 1
fi

if [[ ! -f "$input" ]]; then
    echo "input file does not exist -> $input"
    exit 1
fi

if [[ "$(wc -w < "$input")" -eq 0 ]]; then
    echo "Please provide input file that isn't empty"
    exit 1
fi

if [[ "$shift" =~ ^- ]];then
    pos=false
else
    pos=true
fi

while IFS= read -r -n1 char || [ -n "$char" ]; do
    if [[ "$char" =~ ^[A-Za-z]$ ]]; then
        ascii=$(( $(printf '%d' "'$char") + shift ))
        if [[ "$pos" == true && ( ( "$ascii" -gt 90 && "$char" =~ ^[A-Z]$ ) || "$ascii" -gt 122 ) ]]; then
            ascii=$((ascii - 26))
        elif [[ "$pos" == false && ( ascii -lt 65 || ( "$char" =~ ^[a-z]$ && ascii -lt 97 ) ) ]]; then
            ascii=$((ascii + 26))
        fi

        char=$(printf "\\$(printf '%03o' "$ascii")")
    fi

    printf "%s" "$char"
done < "$input" > "$output"

echo >> "$output"


