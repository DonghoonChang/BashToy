#!/bin/bash

stty -echo
tput civis

# SCREEN
screen_cols=0
screen_lines=0
read_timeout=0.001
refresh_interval=0.05

# INPUT
input_chars_count=3 # max number of input chars per frame
input=""
input_buffer=""
next_char=""

# OUTPUT
temp_file=".stars_temp"
print_file=".stars_print"
next_line=""
bg_char=" "

# STARS
stars_count_max=50
star_tail_length=5
star_speed=2 #downward speed per frame

star_state_exploding=-1
star_state_none=0
star_state_created=1

# Debug
debug_line=50
debug_col=50

declare -a star_chars
declare -a star_lines
declare -a star_cols
declare -a star_speeds

# Screen
get_screen_size () {
	screen_cols=$(tput cols)
	screen_lines=$(tput lines)
}

# Input
read_input () {
	read -s -n $input_chars_count -t $read_timeout input
}

buffer_input () {
	input_buffer="${input_buffer}${input}"
	input=""
}

get_next_char () {
	next_char="${input_buffer:0:1}"
	input_buffer="${input_buffer:1}"
}
# Helpers
# $1: String $2: char
insert_char_at () {
	:
	_length="${#$}"
	
}


# Stars
init_stars () {
	for x in $(seq 0 1 $(( $stars_count_max - 1)));
	do
		star_lines[$x]=$star_state_none
		star_cols[$x]=0
	done
}

get_new_star_col () {
	return $(( $RANDOM % $screen_cols ))
}

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
			get_new_star_col
			star_cols[$x]=$?
			star_chars[$x]=$next_char
			break
		fi
	done
}

update_stars () {
	insert_star

	for x in $(seq 0 1 $(( $stars_count_max - 1)));
	do
		if [[ ${star_lines[$x]} -ge $screen_lines ]];
		then
			star_lines[$x]="$star_state_exploding"

		elif [[ ${star_lines[$x]} -eq $star_state_exploding ]];
		then
			star_lines[$x]="$star_state_none"

		elif [[ ${star_lines[$x]} -eq $star_state_none ]];
		then
			: # Do nothing if there's no star at this index

		else
			star_lines[$x]="$(( ${star_lines[$x]} + $star_speed ))"
		fi
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
		_char="${star_chars[$x]}"

		if [[ $_line -gt $star_state_none ]] && [[ $_line -lt $star_tail_length ]];
		then
			new_line[$_col]="$_char"
		fi
	done

	printf "%s" "${new_line[@]}" > "$temp_file"
	printf "\n" >> "$temp_file"
	cat "$print_file" >> "$temp_file"
	head -n $(( $screen_lines - 5 )) "$temp_file" > "$print_file"
}

draw_stars_from_file () {
	tput home
	tput clear
	cat "$print_file"
}

render () {
	echo "This is where all draw functions will be called"
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
	draw_at "$1" "$2" "$3"

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
		_char="${star_chars[$x]}"

		if [[ $_line -le 0 ]];
		then
			:
		else
			draw_star $_line $_col $_char
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
	tput cup $(( $debug_line + 2 )) $debug_col
	echo -n "Input Buffer: $input_buffer"
	
	tput cup $(( $debug_line + 3 )) $debug_col
	echo -n "Next Char: $next_char"
}

print_states () {
	print_star_lines
	print_star_cols
	print_input_buffer
}

# Clean up
clean_up () {
	echo "Cleaning up..."
	stty echo
	tput cnorm

	rm $temp_file
	rm $print_file
	exit $?
}

# Init
init_stars
trap clean_up EXIT
trap clean_up SIGNINT
trap clean_up SIGTERM

while true;
do
	# Adjust screen size
	get_screen_size

	# Drawing
	draw_line
	draw_stars_from_file

	# Debugging
	print_states

	# Input
	read_input
	buffer_input

	# State Management
	update_stars
	sleep $refresh_interval
done

stty echo
tput cnorm
