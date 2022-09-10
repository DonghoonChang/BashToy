#!/bin/bash

declare -a array
toReplace=( 10 20 45 99 1000 1001 )

default="."
replaced="*"

for x in {1..100};
do
	array[$x]="$default"
done

for x in "${toReplace[@]}";
do
	array[$x]="$replaced"
done

line=`echo "${array[@]}"`
printf "%s" "${array[@]}"
printf "\n"
