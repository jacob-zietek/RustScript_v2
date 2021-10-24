open Base
open Stdio

open Rustscript.Run
open Util

let () =
    let state = 
        Map.empty (module String) |> run_file (test_file "match_expr.rsc") in
    assert_equal_expressions "fib(20)" "10946" state;

    printf "Passed\n"
