let empty_board() = repeat(:empty, 9)

let square_to_string(square) = match square
    | :empty -> " "
    | :x     -> "X"
    | :o     -> "O"

let print_board(board) = {
    foreach([0..3], fn(i) => {
	let [a, b, c] = slice(board, 3 * i, 3 * i + 3)
	let (a, b, c) = (square_to_string(a), square_to_string(b), square_to_string(c))
	println(" " + a + " | " + b + " | " + c)
	if i != 2 then println("-----------") else ()
    })
}

let switch_turn(turn) = match turn
    | :x -> :o
    | :o -> :x

let is_winner(board, turn) = {
    let flatten(ls) = fold([], fn(a, b) => a + b, ls)

    let rows = ([slice(board, 3 * i, 3 * i + 3) for i in [0..3]])
    let cols = ([[nth(board, 3 * i + j) for i in [0..3]] for j in [0..3]])
    let diags = [[nth(board, i) for i in [0, 4, 8]], [nth(board, i) for i in [2, 4, 6]]]

    let sets = flatten([rows, cols, diags])

    any([
	all([sq == turn for sq in set])
	for set in sets
    ])
}

let game_loop(board, turn) = {
    println("===========\n")
    print_board(board)
    print("\nChoose a position for " + square_to_string(turn) + ": ")

    let get_position = fn() => match string_to_int(scanln())
	| (:ok, n) when nth(board, n) != :empty -> {
	    print("That position is already taken, enter another: ")
	    get_position()
	}
	| (:ok, n) when (0 <= n) && (n <= 8) -> n
	| _ -> {
	    print("Error: position must be a number from 0 to 9: ")
	    get_position()
	}

    let position = get_position()
    let new_board = set_nth(board, position, turn)

    if is_winner(new_board, turn) then {
	println(square_to_string(turn) + " Wins!")
	print_board(new_board)
    } else {
	game_loop(set_nth(board, position, turn), switch_turn(turn))
    }
}

game_loop(empty_board(), :x)
