#!/bin/bash

for x in {1..20}
do
	echo "" > _temp.txt

	for x2 in $(seq 0 1 $x)
	do
		echo "" >> _temp.txt
	done

	cat "0.txt" >> _temp.txt
	cat _temp.txt > "$x.txt"
done
