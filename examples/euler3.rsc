let gcd = fn(a, b) => match (a, b)
    | (0, b) -> b
    | (a, 0) -> a
    | (a, b) when a > b -> gcd(b, a)
    | (a, b) -> {
        let remainder = b % a
        if remainder != 0 then (gcd(a, remainder)) else a
    }

let abs = fn(x) => if x < 0 then -x else x

let pollard = fn(n) => match n
    | 1 -> ()
    | n when n % 2 == 0 -> 2
    | n -> {
        let g = fn(x, n) => (x * x + 1) % n
        let iter = fn(x, y, d) => match (x, y, d)
            | (x, y, 1) -> {
                let x = g(x, n)
                let y = g(g(y, n), n)
                let d = gcd(abs(x - y), n)
                iter(x, y, d)
            }
            | (_, _, d) -> if d == n then () else d

        iter(2, 2, 1)
    }

let largest_factor = fn(n) => {
    let d = pollard(n)
    if d == () then () else n / d
}

let euler3 = {
    # repeatedly factors until largest is found
    let aux = fn(n) => match largest_factor(n)
        | () -> n
        | f when n == f -> f
        | f -> aux(f)

    let n = 600851475143
    aux(n)
}

# inspect(euler3) # should be 6857
