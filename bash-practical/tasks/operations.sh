#!/opt/homebrew/bin/bash

operations=()
numbers=()
debug=false
res=0
res_arr=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n)
            shift
            while [[ $# -gt 0 && "$1" != -[no]* ]]; do
                if [[ ! "$1" =~ 0|^-?[1-9]+[0-9]*$ ]]; then
                    echo "You need to put in valid numbers"
                    exit 1
                fi
                numbers+=("$1")
                shift
            done
        ;;
        -o)
            shift
            while [[ $# -gt 0 && "$1" != -[nd]* ]]; do
                if [[ ! "$1" == [+\-*%] ]]; then
                    echo "The valid operators are: + - % *"
                    exit 1
                fi
                operations+=("$1")
                shift
            done
        ;;
        -d)
            debug=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if (( ${#numbers[@]} != ${#operations[@]} + 1 ));then
    echo "Wrong number of operands"
    exit 1
fi

res=${numbers[0]}
res_arr+=$res

for((i=0;i<${#operations[@]};i++)); do
    operation=${operations[i]}

    case $operation in
        -) res=$((res-numbers[i+1])) ;;
        +) res=$((res+numbers[i+1])) ;;
        \*) res=$((res*numbers[i+1])) ;;
        %) res=$((res%numbers[i+1])) ;;
    esac
    res_arr+=("$operation")
    res_arr+=("${numbers[i+1]}")
done

if $debug; then
    echo "User: $(whoami)"
    echo "Script: $(basename "$0")"
    echo "Operations: ${operations[*]}"
    echo "Numbers: ${numbers[*]}"
fi
echo "${res_arr[*]}" "= $res"
echo "Result -> $res"
