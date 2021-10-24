open Types
open Scanner
open Printf
open Base

let binary_op_bp = function
    | Or        -> (1, 2)
    | And       -> (3, 4)
    | EQ | NEQ  -> (5, 6)
    | LT | GT   -> (7, 8)
    | Add | Neg -> (9, 10)
    | Mul | Div | Mod -> (11, 12)
    | Head | Tail -> (13, 14)
    | Not -> assert false

let prefix_op_bp = 13

let rec complete_expr lhs ls min_bp = match ls with
    | (Operator op)::xs ->
            let (l_bp, r_bp) = binary_op_bp op
            in
            if l_bp < min_bp 
                then (lhs, ls)
                else let (rhs, rem) = parse xs r_bp in 
                     let complete = Binary {op = op; lhs = lhs; rhs = rhs}
                      in complete_expr complete rem min_bp
    | _ -> (lhs, ls)

and parse_prefix_expr op xs min_bp =
    let (rhs, rem) = parse xs min_bp in 
    let complete = Prefix {op = op; rhs = rhs} in
    complete_expr complete rem min_bp

and parse_expr_tuple xs min_bp =
    let rec aux toks saw_comma acc = match toks with
        | RParen::rest -> acc, rest, saw_comma
        | _ -> let nx, rest = parse toks 0 in begin
            match rest with
                | Comma::rest -> aux rest true (nx::acc)
                | RParen::rest -> (nx::acc), rest, saw_comma
                | _ -> assert false
        end
    in let expr_list, rest, saw_comma = aux xs false [] in begin
        match expr_list, saw_comma with
            | _, true -> complete_expr (TupleExpr (List.rev expr_list)) rest min_bp
            | [], false -> complete_expr (TupleExpr []) rest min_bp
            | _, false -> complete_expr (List.hd_exn expr_list) rest min_bp
    end


and parse_list_expr xs min_bp =
    let rec aux toks acc = match toks with
        | RBracket::rest -> (acc, None), rest
        | _ -> let nx, rest = parse toks 0 in
            match rest with
                | Comma::rest -> aux rest (nx::acc)
                | RBracket::rest -> (nx::acc, None), rest
                | Pipe::rest ->
                    let tail, more = parse rest 0 in begin
                    match more with
                        | RBracket::rest -> (nx::acc, Some tail), rest
                        | _ -> assert false
                    end
                | _ -> 
                        print_toks rest;
                        assert false
    in 
    let (expr_list, tail), rest = aux xs [] in
    let parsed_list = ListExpr ((List.rev expr_list), tail) in
    complete_expr parsed_list rest min_bp

and expr_bp ls min_bp = match ls with
    | (LParen::xs) -> parse_expr_tuple xs min_bp
    | (LBracket::xs) -> parse_list_expr xs min_bp
    | (Number f)::xs -> complete_expr (Atomic (Number f)) xs min_bp
    | (Ident n)::xs -> complete_expr (Ident n) xs min_bp
    | (Operator op)::xs -> parse_prefix_expr op xs min_bp
    | True::xs -> complete_expr (Atomic (Boolean true)) xs min_bp
    | False::xs -> complete_expr (Atomic (Boolean false)) xs min_bp
    | _ -> assert false

and parse_pat ls = match ls with
    | LParen::xs ->
            let rec aux toks acc = match toks with
                | RParen::rest -> (acc, rest)
                | _ ->  let (nx, rest) = parse_pat toks in
                        match rest with
                            | (Comma::rest) -> aux rest (nx::acc)
                            | (RParen::rest) -> (nx::acc, rest)
                            | _ -> assert false
            in 
            let (parsed, remaining) = aux xs [] 
            in (TuplePat (List.rev parsed), remaining)
    | LBracket::xs ->
            let rec aux toks acc = match toks with
                | RBracket::rest -> (acc, None), rest
                | _ -> let (nx, rest) = parse_pat toks in
                    match rest with
                        | Comma::rest -> aux rest (nx::acc)
                        | RBracket::rest -> (nx::acc, None), rest
                        | Pipe::rest ->
                            let tail_pat, more = parse_pat rest in begin
                                match more with
                                    | RBracket::rest -> (nx::acc, Some tail_pat), rest
                                    | _ -> assert false
                            end
                        | _ -> assert false
            in
            let (pat_list, tail), rest = aux xs [] in
            let parsed_list_pat = match tail with
                | None -> FullPat (List.rev pat_list)
                | Some tail_pat -> HeadTailPat (pat_list, tail_pat)
            in
            ListPat parsed_list_pat, rest
    | (Ident s)::xs -> (SinglePat s, xs)
    | (Number f)::xs -> (NumberPat f, xs)
    | Underscore::xs -> (WildcardPat, xs)
    | _ ->
            printf "Expected pattern, got %s" (string_of_toks ls);
            assert false

and parse_let ls =
    let (pat, xs) = parse_pat ls in
    match xs with
        | Equal::xs ->
                let (rhs, rest) = parse xs 0 in
                let let_expr: expr = Let {assignee = pat; assigned_expr = rhs}
                in (let_expr, rest)
        | _ -> assert false

and parse_args toks =
    match toks with
    | LParen::xs ->
            let rec aux toks acc = match toks with
                | RParen::rest -> (acc, rest)
                | _ -> let (nx, rest) = parse toks 0 in begin
                    match rest with
                        | Comma::rest -> aux rest (nx::acc)
                        | RParen::rest -> (nx::acc), rest
                        | _ -> assert false
                end
            in
            let (parsed, remaining) = aux xs []
            in
            (List.rev parsed, remaining)
    | _ ->
            printf "Error parsing args: ";
            print_toks toks;
            assert false

and parse_lambda = function
    | Fn::xs -> 
            begin
                let (args, rest) = parse_pat xs in
                match rest with
                    | Arrow::xs ->
                            let (lambda_expr, rest) = parse xs (-1) in
                            let lambda = 
                                LambdaDef {lambda_def_expr = lambda_expr; lambda_def_args = args} 
                            in (lambda, rest)
                    | _ ->
                            printf "Expected an arrow, got (%s)\n" (string_of_toks rest);
                            assert false
            end
    | _ -> assert false

and parse_lambda_call = function
    | (Ident lambda_name)::xs -> begin
            match parse_args xs with
                | args, rest ->
                        let call_args = TupleExpr args in
                        (LambdaCall {callee = lambda_name; call_args = call_args}, rest)
    end
    | _ -> assert false


and parse_if_expr = function
    | If::xs -> begin
        let (cond, xs) = parse xs 0 in
        match skip_newlines xs with
            | Then::xs -> begin
                let (then_expr, xs) = parse xs 0 in
                match (skip_newlines xs) with
                    | Else::xs ->
                        let (else_expr, rest) = parse xs 0 in
                        (IfExpr {cond = cond; then_expr = then_expr; else_expr = else_expr}, rest)
                    | _ -> 
                        printf "Error parsing as else: ";
                        print_toks xs;
                        assert false
                end
            | _ -> assert false
    end
    | _ -> assert false

and parse_block_expr ls =
    let rec aux ls acc = match skip_newlines ls with
        | RBrace::rest -> (BlockExpr (List.rev acc), rest)
        | rest ->
                let (next_expr, rest) = parse rest 0 in
                aux rest (next_expr::acc)
    in aux ls []

and parse_match_expr ls =
    let (match_val, rest) = parse ls 0 in
    let rest = skip_newlines rest in
    let rec parse_match_arms toks acc = match toks with
        | Pipe::xs ->
            let arm_pat, rest = parse_pat xs in begin
            let cond, rest = match rest with
                | MatchArrow::_ -> None, rest
                | When::rest ->
                        let cond, rest = parse rest 0 in
                        Some cond, rest
                | _ ->
                    printf "Expected When or MatchArrow, got: %s" (string_of_toks rest);
                    assert false
            in
            match rest with
                | MatchArrow::rest ->
                    let rest = skip_newlines rest in
                    let arm_expr, rest = parse rest 0 in begin
                        match rest with
                            | Newline::xs -> 
                                parse_match_arms xs ((arm_pat, arm_expr, cond)::acc)
                            | _ ->
                                printf "Must break line after each match arm";
                                assert false
                    end
                | _ ->
                    printf "Expected an arrow\n";
                    assert false
            end
        | more -> List.rev acc, more
    in
    let (match_arms, rest) = parse_match_arms rest [] in
    if (not (phys_equal match_arms [])) then
        MatchExpr {match_val = match_val; match_arms = match_arms}, rest
    else begin
        printf "No match arms in match expression\n";
        assert false
    end

and parse: token list -> int -> expr * (token list) = fun s min_bp ->
    let s = skip_newlines s in
    match s with
    | LBrace::xs -> parse_block_expr xs
    | (Ident _)::LParen::_ -> 
            let (call, xs) = parse_lambda_call s in
            complete_expr call xs min_bp
    | LParen::_ -> expr_bp s 0
    | LBracket::_ -> expr_bp s 0
    | (Operator _)::_ -> expr_bp s 0
    | (True|False|Number _| Ident _)::_ -> expr_bp s min_bp
    | Let::xs -> parse_let xs
    | Fn::_ -> 
            let (lambda_parsed, xs) = parse_lambda s in
            complete_expr lambda_parsed xs min_bp
    | If::_ -> 
            let (if_parsed, xs) = parse_if_expr s in
            complete_expr if_parsed xs min_bp
    | Match::xs -> 
            let (match_parsed, xs) = parse_match_expr xs in
            complete_expr match_parsed xs min_bp
    | _ -> 
            printf "Expected expression, got (%s)\n" (string_of_toks s);
            assert false

let parse_str s = parse (Scanner.scan s) 0
