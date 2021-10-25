let range = {
    let helper = fn(l, r, acc) =>
        if l + 1 == r then acc else helper(l, r - 1, [r | acc])

    fn (l, r) => helper(l - 1, r - 1, [])
}

let filter = {
    let helper = fn(f, ls, acc) => match ls
        | [] -> acc
        | [hd | tl] when f(hd) -> helper(f, tl, [hd | acc])
        | [hd | tl] -> helper(f, tl, acc)

    fn(f, ls) => helper(f, ls, [])
}

let sum = {
    let helper = fn(ls, acc) => match ls
        | [] -> acc
        | [hd | tl] -> helper(tl, hd + acc)

    fn (ls) => helper(ls, 0)
}

let predicate = fn(n) => (n % 3 == 0) || (n % 5 == 0)
