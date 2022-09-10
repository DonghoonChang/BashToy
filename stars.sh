#!/bin/bash

stty -echo
tput civis

# SCREEN(Frames)
read_timeout=0.01
refresh_interval=0.001

# Screen(Size)
screen_cols=0
screen_lines=0
screen_available_cols=0
screen_available_lines=0

# Stars Gen Boundary
margin_left=20
margin_right=20
margin_bottom=15
margin_top=15

# INPUT
input_chars_count=3 # max number of input chars per frame
input=""
input_buffer=""
next_char=""

# OUTPUT
file_temp=".stars_temp"
file_print=".stars_print"
bg_char=" "

# STARS(Appearance)
stars_count_max=10
star_tail_char="|"
star_head_char="*"
star_tail_length=5
star_speed=1 #downward speed per frame

# STARS(State)
star_state_eol=-1 #End of Life
star_state_none=0
star_state_created=1

# Debug
debug_line=50
debug_col=5

declare -a star_lines
declare -a star_cols

# Screen
get_screen_size () {
	screen_cols=$(tput cols)
	screen_lines=$(tput lines)
	screen_available_cols=$(( $screen_cols - $margin_left - $margin_right ))
	screen_available_lines=$(( $screen_lines - $margin_top - $margin_bottom ))
}

# Input
read_input () {
	read -s -n $input_chars_count -t $read_timeout input
}

buffer_input () {
	input_buffer="${input_buffer}${input}"
	input=""
}

apply_input () {
	buffer_input
	insert_star
}

get_next_char () {
	next_char="${input_buffer:0:1}"
	input_buffer="${input_buffer:1}"
}

# Helpers
DEBUG=0
REMOVE_PRINT_FILES=1

# Initalisation
setup_cleanup () {
	trap cleanup EXIT
}

init () {
	setup_cleanup
	tput clear
	touch "$file_temp"
	touch "$file_print"
	get_screen_size

	stars_count_max=$(( $screen_cols / 5 ))

	if [[ $1 == "-d" ]];
	then
		echo "Debuggging Set"
		DEBUG=1
		sleep 1
	fi

	if [[ $1 == "-D" ]];
	then
		echo "Debugging Set"
		echo "Print files are not removed after exit"
		REMOVE_PRINT_FILES=0
		DEBUG=1
		sleep 1
	fi

	for x in $(seq 0 1 $(( $stars_count_max - 1)));
	do
		star_lines[$x]=$star_state_none
		star_cols[$x]=0
	done
}

# State management
insert_star () {
	get_next_char
	if [[ "$next_char" == "" ]]
	then
		return
	fi

	for x in $(seq 0 1 $(( $stars_count_max - 1)));
	do
		if [[ "${star_lines[$x]}" -eq "$star_state_none" ]];
		then
			star_lines[$x]=$star_state_created
			star_cols[$x]=$(( $RANDOM % $screen_available_cols + $margin_left ))
			break
		fi
	done
}

update_stars () {
	for x in $(seq 0 1 $(( $stars_count_max - 1)));
	do
		if [[ ${star_lines[$x]} -ge $screen_available_lines ]];
		then
			star_lines[$x]="$star_state_eol"
			continue;
		fi

		if [[ ${star_lines[$x]} -eq $star_state_eol ]];
		then
			star_lines[$x]="$star_state_none"
			continue
		fi

		if [[ ${star_lines[$x]} -eq $star_state_none ]];
		then
			continue # Do nothing if there's no star at this index
		fi 		

		(( star_lines[$x]++ ))
	done
}

# Output
draw_line () {
	declare -a new_line
	
	for x in $(seq 1 $screen_cols);
	do
		new_line[$x]="$bg_char"
	done
	
	for x in $(seq 0 1 $(( $stars_count_max - 1)));
	do
		_line="${star_lines[$x]}"
		_col="${star_cols[$x]}"
		
		if [[ $_line -le $star_state_none ]];
		then
			continue
		fi

		if [[ $_line -eq $star_state_created ]];
		then
			new_line[$_col]="$star_head_char"
			continue
		fi


		if [[ $_line -le $(( $star_tail_length + 1 )) ]]; # +1: Accounting for head
		then
			new_line[$_col]="$star_tail_char"
		fi
	done

	printf "%s" "${new_line[@]}" > "$file_temp"
	printf "\n" >> "$file_temp"
	cat "$file_print" >> "$file_temp"
	head -n $screen_available_lines "$file_temp" > "$file_print"
}

draw_stars_from_file () {
	cat "$file_print"
}

draw_margin_top () {
	for x in $(seq 1 1 $margin_top);
	do
		printf "\n"
	done
}

render () {
	draw_line
	tput home
	draw_margin_top
	draw_stars_from_file

	#draw_stars
}

# $1 = line $2 = col $3 = char
draw_at () {
	tput cup "$1" "$2"
	echo -n "$3"
}

# $1 = line $2 = col $3 = char
draw_star () {
	tail_line_start=$(( $1 - 1 ))
	tail_line_end=$(( $1 - $star_tail_length ))

	# draw head
	draw_at "$1" "$2" "$star_head_char"
	
	# draw tail
	for x in $(seq $tail_line_start -1 $tail_line_end);
	do
		if [[ $x -lt 0 ]];
		then
			break
		fi

		draw_at "$x" "$2" "$star_tail_char"
	done
}

draw_stars () {
	for x in $(seq 0 1 $(( $stars_count_max - 1)));
	do
		_line="${star_lines[$x]}"
		_col="${star_cols[$x]}"

		if [[ $_line -le $star_state_none ]];
		then
			:
		else
			draw_star $_line $_col 
		fi
	done
}

# Debugging
print_star_lines () {
	tput cup $debug_line $debug_col 
	echo -n "Star Lines: ${star_lines[@]}"
}

print_star_cols () {
	tput cup $(( $debug_line + 1 )) $debug_col
	echo -n "Star Cols: ${star_cols[@]}"
}

print_input_buffer () {
	tput cup $(( $debug_line + 3 )) $debug_col
	echo -n "Input Buffer: $input_buffer"
	
	tput cup $(( $debug_line + 4 )) $debug_col
	echo -n "Next Char: $next_char"
}

print_states () {
	print_star_lines
	print_star_cols
	print_input_buffer
}

# Clean up
cleanup () {
	echo "Cleaning up..."
	stty echo
	tput cnorm
	
	if [[ $REMOVE_PRINT_FILES -eq 1 ]];
	then
		rm $file_temp
		rm $file_print
	fi

	tput clear
	exit $?
}

# Init
init "$@"

while true;
do
	# Input
	read_input
	apply_input

	# Drawing
	render

	# Debugging
	if [[ $DEBUG -eq 1 ]];
	then
		print_states
	fi

	# State Management
	update_stars

	sleep $refresh_interval
done

stty echo
tput cnorm
