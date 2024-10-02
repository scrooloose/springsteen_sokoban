#!/bin/bash

PROGRAM_NAME=$0
PLAYER="@"
CRATE="o"
GOAL="."
WALL="#"
EMPTY=" "

board_grid=()
goal_squares=()
player_x=-1
player_y=-1

function init_game_from_file() {
    local fname=$1

    # init board grid
    while IFS= read -r line; do
        map_row=$(echo "$line")
        board_grid+=("$map_row")
    done < "$fname"

    init_player_start_xy
    init_goal_squares
}

function init_player_start_xy() {
    for (( y = 0; y < ${#board_grid[@]}; y++ )); do
        row="${board_grid[$y]}"

        for (( x = 0; x < ${#row}; x++ )); do
            if [[ "${row:x:1}" == "$PLAYER" ]]; then
                player_x=$x
                player_y=$y
                return 0
            fi
        done
    done

    return 1
}

function init_goal_squares() {
    for (( y = 0; y < "${#board_grid[@]}"; y++ )); do
        row=${board_grid[$y]}

        for (( x = 0; x < ${#row}; x++ )); do
            if [[ "${row:x:1}" == "$GOAL" ]]; then
                goal_squares+=("${x},${y}")
            fi
        done
    done

    echo "${goal_squares[@]}"
    return 1
}

function render_board() {
    for row in "${board_grid[@]}"; do
        echo "$row"
    done
}

function tile_at() {
    local x=$1 y=$2

    local row="${board_grid[$y]}"
    echo "${row:x:1}"
}

function set_tile() {
    local x=$1 y=$2 new_val=$3

    local row="${board_grid[$y]}"
    local new_row="${row:0:x}${new_val}${row:x+1}"
    board_grid[$y]="$new_row"
}

function handle_keypress() {
    local key=$1

    if [[ $key == "j" ]]; then
        handle_move_attempt 0 1
    elif [[ $key == "k" ]]; then
        handle_move_attempt 0 -1
    elif [[ $key == "h" ]]; then
        handle_move_attempt -1 0
    elif [[ $key == "l" ]]; then
        handle_move_attempt 1 0
    fi
}

function handle_move_attempt() {
    local dx=$1 dy=$2

    new_x=$(($player_x+$dx))
    new_y=$(($player_y+$dy))

    if $(is_walkable $new_x $new_y); then
        handle_player_leaving_square $player_x $player_y
        player_x=$new_x
        player_y=$new_y
        set_tile $player_x $player_y "$PLAYER"
    else
        target_tile=$(tile_at $new_x $new_y)
        if [[ $target_tile == "$CRATE" ]]; then
            if $(is_walkable $(($new_x+$dx)) $(($new_y+$dy))); then
                handle_player_leaving_square $player_x $player_y
                player_x=$new_x
                player_y=$new_y
                set_tile $player_x $player_y $PLAYER
                set_tile $(($new_x+$dx)) $(($new_y+$dy)) "$CRATE"
            fi
        fi
    fi
}

function is_walkable() {
    local x=$1 y=$2
    tile=$(tile_at $x $y)
    if [[ $tile == " " || $tile == "$GOAL" ]]; then
        return 0
    fi
    return 1
}

function handle_player_leaving_square() {
    local x=$1 y=$2

    for goal_square in ${goal_squares[@]}; do
        goal_x=${goal_square/,*/}
        goal_y=${goal_square/*,/}

        if [[ $goal_x == $x && $goal_y == $y ]]; then
            set_tile $x $y "$GOAL"
            return 0
        fi
    done

    set_tile $x $y " "
}

function has_won() {
    for goal_square in ${goal_squares[@]}; do
        goal_x=${goal_square/,*/}
        goal_y=${goal_square/*,/}

        if [[ $(tile_at $goal_x $goal_y) != $CRATE ]]; then
            set_tile $x $y "$GOAL"
            return 1
        fi
    done

    return 0
}

function main_loop() {
    clear
    render_board
    while true; do
        IFS= read -s -n 1 key_press
        handle_keypress "$key_press"
        clear
        render_board

        if $(has_won); then
            echo ""
            echo "You win!"
        fi
    done
}

function usage() {
    echo "usage: $PROGRAM_NAME levels/<level-file-name>"
    echo ""
    echo "Use the vim movement keys to move your character (the '$PLAYER' symbol) around."
    echo "Push all the crates (the '$CRATE' characters) onto the goal squares (the '$GOAL' symbols) to win."
    exit 1
}

if [[ ! -e $1 ]]; then
    usage
fi

init_game_from_file "$1"
main_loop
