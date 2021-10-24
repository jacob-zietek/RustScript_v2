open Base
open Stdio

type token =
    | True
    | False
    | Number of float
    | Ident of string
    | PrefixOperator of Types.prefix_operator
    | BinaryOperator of Types.binary_operator
    | Let
    | Equal
    | LParen
    | RParen
    | LBrace
    | RBrace
    | LBracket
    | RBracket
    | Fn
    | If
    | Then
    | Else
    | Arrow
    | Newline
    | Hashtag
    | VLine
    | Comma;;

let is_numeric d = Base.Char.is_digit d || phys_equal d '.';;
let is_identic c = Base.Char.is_alphanum c || phys_equal c '_';;

let rec scan_digit ls =
    let rec aux ls acc = match ls with
        | d::xs when is_numeric d -> aux xs (d::acc)
        | _ -> let f = (acc |> List.rev |> String.of_char_list |> Float.of_string)
                in (Number f)::(scan_ls ls)
    in aux ls []

and scan_ident ls =
    let rec aux ls acc = match ls with
        | c::xs when is_identic c -> aux xs (c::acc)
        | _ -> let n = (acc |> List.rev |> String.of_char_list)
                in (Ident n)::(scan_ls ls)
    in aux ls []

and scan_ls = function
    | [] -> []
    | (' '|'\t')::xs -> scan_ls xs
    | '\n'::xs -> Newline :: scan_ls xs
    | '='::'>'::xs -> Arrow :: scan_ls xs
    | '+'::xs -> BinaryOperator Add :: (scan_ls xs)
    | '-'::xs -> BinaryOperator Sub :: scan_ls xs
    | '*'::xs -> BinaryOperator Mul :: scan_ls xs
    | '/'::xs -> BinaryOperator Div :: scan_ls xs
    | '<'::xs -> BinaryOperator LT :: scan_ls xs
    | '>'::xs -> BinaryOperator GT :: scan_ls xs
    | '='::'='::xs -> BinaryOperator EQ :: scan_ls xs
    | '^'::xs -> PrefixOperator Head :: scan_ls xs
    | '$'::xs -> PrefixOperator Tail :: scan_ls xs
    | '~'::xs -> PrefixOperator Negate :: scan_ls xs
    | '('::xs -> LParen :: scan_ls xs
    | ')'::xs -> RParen :: scan_ls xs
    | '{'::xs -> LBrace :: scan_ls xs
    | '}'::xs -> RBrace :: scan_ls xs
    | '['::xs -> LBracket :: scan_ls xs
    | ']'::xs -> RBracket :: scan_ls xs
    | '='::xs -> Equal :: scan_ls xs
    | ','::xs -> Comma :: scan_ls xs
    | '|'::xs -> VLine :: scan_ls xs
    | '#'::xs -> Hashtag :: scan_ls xs
    | 'l'::'e'::'t'::xs -> Let :: scan_ls xs
    | 'f'::'n'::xs -> Fn :: scan_ls xs
    | 'i'::'f'::xs -> If :: scan_ls xs
    | 't'::'h'::'e'::'n'::xs -> Then :: scan_ls xs
    | 'e'::'l'::'s'::'e'::xs -> Else :: scan_ls xs
    | 'T'::xs -> True :: scan_ls xs
    | 'F'::xs -> False :: scan_ls xs
    | d::_ as ls when Base.Char.is_digit d -> scan_digit ls
    | i::_ as ls when not (Base.Char.is_digit i) -> scan_ident ls
    | _ as ls -> 
            printf "Scan Error: %s\n" (String.of_char_list ls); 
            assert false

and remove_comments ls =
    let rec skip_until_endline = function
        | [] -> []
        | Newline::xs -> remove_comments xs
        | _::xs -> skip_until_endline xs
    in match ls with
        | [] -> []
        | Hashtag::xs -> skip_until_endline xs
        | t::xs -> t :: (remove_comments xs)

let scan s = s |> String.to_list |> scan_ls |> remove_comments;;

let string_of_tok = function
    | Number f -> Float.to_string f
    | Ident s -> "(Ident " ^ s ^ ")"
    | PrefixOperator _ -> "PrefixOperator"
    | BinaryOperator _ -> "BinaryOperator"
    | Let -> "Let"
    | Equal -> "Equal"
    | LParen -> "LParen"
    | RParen -> "RParen"
    | LBrace -> "LBrace"
    | RBrace -> "RBrace"
    | LBracket -> "LBracket"
    | RBracket -> "RBracket"
    | Comma -> "Comma"
    | Fn -> "Fn"
    | Arrow -> "Arrow"
    | True -> "True"
    | False -> "False"
    | If -> "If"
    | Then -> "Then"
    | Else -> "Else"
    | Newline -> "Newline"
    | VLine -> "VLine"
    | Hashtag -> "Hashtag"

let string_of_toks ls = String.concat ~sep:" " (List.map ~f:string_of_tok ls)
let print_toks ls = ls |> string_of_toks |> printf "%s\n"

let toks_empty toks = List.for_all toks ~f:(fun tok -> phys_equal tok Newline)
let rec skip_newlines = function
    | Newline :: xs -> skip_newlines xs
    | ls -> ls
