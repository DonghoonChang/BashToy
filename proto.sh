#!/bin/bash

margin_l=20
margin_r=20
margin_b=20
margin_t=20

screen_cols=1
screen_lines=1
screen_bg_char=" "

stars_lines_range=1
stars_cols_range=1

declare -A screen
declare -A background
declare -A foreground


get_screen_size () {
	screen_cols=`tput cols`
	screen_lines=`tput lines`

	stars_lines_range=$(( $screen_lines - $margin_t - $margin_b ))
	stars_cols_range=$(( $screen_cols - $margin_l - $margin_r ))
}

get_range () {
	seq 0 $(( $1 - 1 ))
}

init_arrays () {
	for x in $(get_range $screen_lines );
	do
		for y in $(get_range $screen_cols);
		do
			screen["$x,$y"]="$screen_bg_char"
		done
	done
}

init () {
	tput clear
	get_screen_size
	init_arrays
}

generate_random_star () {
	random_col=$(( $RANDOM % $stars_cols_range + $margin_l ))
	random_line=$(( $RANDOM % $stars_lines_range + $margin_t ))
	screen["$random_line,$random_col"]="*"
}

render () {
	tput home
	generate_random_star

	for x in $(get_range $screen_lines );
	do
		for y in $(get_range $screen_cols);
		do
			printf "%1s" "${screen[$x,$y]}"
		done
	done
}

echo "starting.."
init

while [[ true ]];
do
	render
done
