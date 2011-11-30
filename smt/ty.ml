
open Format

type ty= 
  | Tint
  | Tbool
  | Tabstract of Hstring.t
  | Tsum of Hstring.t * Hstring.t list

let hash t =
  match t with
    | Tabstract s -> Hstring.hash s
    | Tsum (s, l) -> 
	let h = 
	  List.fold_left 
	    (fun h x -> 13 * h + Hstring.hash x) (Hstring.hash s) l
	in
	abs h
    | _ -> Hashtbl.hash t

let equal t1 t2 = 
  match t1, t2 with
    | Tabstract s1, Tabstract s2 
    | Tsum (s1, _), Tsum (s2, _) ->
	Hstring.equal s1 s2
    | Tint, Tint | Tbool, Tbool -> true
    | _ -> false
	
let compare t1 t2 = 
  match t1, t2 with
    | Tabstract s1, Tabstract s2 ->
	Hstring.compare s1 s2 
    | Tabstract _, _ -> -1 | _ , Tabstract _ -> 1
    | Tsum (s1, _), Tsum(s2, _) ->
	Hstring.compare s1 s2
    | Tsum _, _ -> -1 | _ , Tsum _ -> 1
    | t1, t2 -> Pervasives.compare t1 t2

let print fmt ty = 
  match ty with
    | Tint -> fprintf fmt "int"
    | Tbool -> fprintf fmt "bool"
    | Tabstract s -> fprintf fmt "%s" (Hstring.view s)
    | Tsum (s, _) -> fprintf fmt "%s" (Hstring.view s)