let fib = fn (n) => {
    if n < 2 
        then 1 
        else fib(n - 1) + fib(n - 2)
}

inspect(fib(30))
