open Base
open Printf
open Stdio

type operator =
    | Add
    | Sub
    | Mul
    | Div
    | LT
    | GT
    | EQ
    | NEQ
    | And
    | Or
    | Mod

type value =
    | Number of float
    | Boolean of bool
    | Tuple of value list
    | Lambda of lambda
    | Thunk of {thunk_fn: lambda; thunk_args: value; thunk_fn_name: string}
    | Dictionary of (int, (value * value) list, Int.comparator_witness) Map.t

and pattern =
    | SinglePat of string
    | NumberPat of float
    | TuplePat of pattern list
    | WildcardPat

and state = (string, value, String.comparator_witness) Map.t

and lambda = {lambda_expr: expr; lambda_args: pattern; enclosed_state: state}
and lambda_call = {callee: string; call_args: expr}
and if_expr = {cond: expr; then_expr: expr; else_expr: expr}

and expr =
    | Atomic of value
    | Ident of string
    | Binary of {lhs: expr; op: operator; rhs: expr}
    | Let of {assignee: pattern; assigned_expr: expr}
    | LambdaDef of {lambda_def_expr: expr; lambda_def_args: pattern}
    | LambdaCall of lambda_call
    | IfExpr of  if_expr
    | TupleExpr of expr list
    | BlockExpr of expr list
    | MatchExpr of {match_val: expr; match_arms: (pattern * expr * expr option) list}
    | MapExpr of (expr * expr) list

let rec string_of_val = function
    | Number n -> Float.to_string n
    | Boolean b -> Bool.to_string b
    | Tuple ls -> "(" ^ String.concat ~sep:", " (List.map ~f:string_of_val ls) ^ ")"
    | Lambda _ -> "Lambda"
    | Thunk _ -> "Thunk"
    | Dictionary  _ -> "Map"

let rec string_of_expr = function
    | Atomic v -> string_of_val v
    | Ident s -> s
    | Binary (_ as b) -> sprintf "{lhs: %s, rhs: %s}" (string_of_expr b.lhs) (string_of_expr b.rhs)
    | Let (_ as l) -> sprintf "Let %s = %s" (string_of_pat l.assignee) (string_of_expr l.assigned_expr)
    | LambdaDef _ -> "Lambda"
    | LambdaCall call -> sprintf "{Call: %s, args: %s}" call.callee (string_of_expr call.call_args)
    | TupleExpr ls -> sprintf "(%s)" (String.concat ~sep:", " (List.map ~f:string_of_expr ls))
    | IfExpr _ -> "IfExpr"
    | BlockExpr ls -> sprintf "{\n\t%s\n}" (String.concat ~sep:"\n\t" (List.map ~f:string_of_expr ls))
    | MatchExpr _ -> "MatchExpr"
    | MapExpr _ -> "Map"

and string_of_pat = function
    | SinglePat s -> s
    | NumberPat f -> Float.to_string f
    | TuplePat ls -> sprintf "(%s)" (String.concat ~sep:", " (List.map ~f:string_of_pat ls))
    | WildcardPat -> "_"

let rec hash_value = function
    | Number f -> Hashtbl.hash (0, f)
    | Boolean b -> Hashtbl.hash (1, b)
    | Tuple ls -> Hashtbl.hash (List.map ~f:hash_value ls)
    | _ ->
        printf "Tried to hash an unhashable type";
        assert false
