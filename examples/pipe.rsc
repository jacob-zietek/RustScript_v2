let add5 = add(_, 5)
let mul3 = mul(_, 3)

let x = 10 |> add5 |> mul3

let g = "asdf"
	|> to_charlist
	|> reverse
	|> enumerate
	|> map(fn((i, c)) => c + to_string(i), _)
