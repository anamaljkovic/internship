#!/opt/homebrew/bin/bash

VAR=$1

if [[ ! "$VAR" =~ ^[0-9]+$ ]];then
    echo "You need to provide a positive number"
    exit 1
fi

FIB=(0 1)

for((i=2; i<=VAR; i++));do
    FIB+=($((FIB[i-1]+FIB[i-2])))
done 

echo "fib($VAR)=${FIB[$VAR]}"