#!/bin/bash

x=0
while true;
do
	tput home
	tput clear
	(( x++ ))
	x=$(( x % 20 ))
	cat "$x.txt"
	sleep 0.05
done
