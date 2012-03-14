(**************************************************************************)
(*                                                                        *)
(*                                  Cubicle                               *)
(*             Combining model checking algorithms and SMT solvers        *)
(*                                                                        *)
(*                  Sylvain Conchon and Alain Mebsout                     *)
(*                  Universite Paris-Sud 11                               *)
(*                                                                        *)
(*  Copyright 2011. This file is distributed under the terms of the       *)
(*  Apache Software License version 2.0                                   *)
(*                                                                        *)
(**************************************************************************)

open Options

type op_comp = Eq | Lt | Le | Neq
type op_arith = Plus | Minus

type sort = Glob | Arr | Constr | Var

type const = ConstInt of Num.num | ConstReal of Num.num | ConstName of Hstring.t

let compare_const c1 c2 = match c1, c2 with
  | (ConstInt n1 | ConstReal n1), (ConstInt n2 | ConstReal n2) ->
      Num.compare_num n1 n2
  | (ConstInt _ | ConstReal _), _ -> -1
  | _, (ConstInt _ | ConstReal _) -> 1
  | ConstName h1, ConstName h2 -> Hstring.compare h1 h2

module MConst = struct 
  module M = Map.Make (struct type t = const let compare = compare_const end)
  include M

  exception Choose of const * int
  let choose m =
    try
      M.iter (fun c i -> raise (Choose (c, i))) m;
      raise Not_found
    with Choose (c, i) -> c, i

end

let compare_constants = MConst.compare Pervasives.compare 

type term = 
  | Const of int MConst.t
  | Elem of Hstring.t * sort
  | Access of Hstring.t * Hstring.t
  | Arith of Hstring.t * sort * int MConst.t

let rec compare_term t1 t2 = 
  match t1, t2 with
    | Const c1, Const c2 -> compare_constants c1 c2
    | Const _, _ -> -1 | _, Const _ -> 1
    | Elem (s1, _), Elem (s2, _) -> Hstring.compare s1 s2
    | Elem _, _ -> -1 | _, Elem _ -> 1
    | Access (a1, i1), Access (a2, i2) ->
	let c = Hstring.compare a1 a2 in
	if c<>0 then c else Hstring.compare i1 i2
    | Access _, _ -> -1 | _, Access _ -> 1 
    | Arith (t1, _, cs1), Arith (t2, _, cs2) ->
	let c = Hstring.compare t1 t2 in
	if c<>0 then c else compare_constants cs1 cs2

type acc_eq = { a : Hstring.t; i: Hstring.t; e: term }

module rec Atom : sig
  type t =
    | True
    | False
    | Comp of term * op_comp * term
    | Ite of SAtom.t * t * t

  val compare : t -> t -> int

end = struct
  
  type t =
    | True
    | False
    | Comp of term * op_comp * term
    | Ite of SAtom.t * t * t

  let rec compare a1 a2 = 
    match a1, a2 with
      | True, True -> 0
      | True, _ -> -1 | _, True -> 1
      | False, False -> 0
      | False, _ -> -1 | _, False -> 1
      | Comp (x1, op1, y1), Comp (x2, op2, y2) ->
	  let c1 = compare_term x1 x2 in
	  if c1 <> 0  then c1 
	  else 
	    let c0 = Pervasives.compare op1 op2 in
	    if c0 <> 0 then c0 
	    else 
	      let c2 = compare_term y1 y2 in c2
      | Comp _, _ -> -1 | _, Comp _ -> 1
      | Ite (sa1, a1, b1), Ite (sa2, a2, b2) ->
	  let c = SAtom.compare sa1 sa2 in
	  if c<>0 then c else 
	    let c = compare a1 a2 in
	    if c<>0 then c else compare b1 b2

end
and SAtom : Set.S with type elt = Atom.t = Set.Make(Atom)

let gen_vars s n = 
  let l = ref [] in
  for i = 1 to max_proc do
    l := Hstring.make (s^(string_of_int i)) :: !l
  done;
  List.rev !l

let alpha_vars = gen_vars "$" max_proc
let proc_vars = gen_vars "#" max_proc
let fresh_vars = gen_vars "?" max_proc

let add a s = 
  match a with
    | Atom.True -> s
    | Atom.False -> SAtom.singleton Atom.False
    | _ -> if SAtom.mem Atom.False s then s else SAtom.add a s

  (* Substitute an indice variable j by i in a set of atoms *)

let svar sigma v = try Hstring.list_assoc v sigma with Not_found -> v
    
let subst_term sigma t = 
  match t with
    | Elem (x, s) -> 
	(try Elem (svar sigma x, s) with Not_found -> t)
    | Access (a, z) -> 
	(try Access (a, svar sigma z) with Not_found -> t)
    | _ -> t
	

module TimerSubset = Timer.Make (struct end)

module TimerApply = Timer.Make (struct end)

open Atom

let rec subst_atoms sigma sa = 
  SAtom.fold (fun a -> add (subst_atom sigma a)) sa SAtom.empty
and subst_atom sigma a = 
  match a with
    | Ite (sa, a1, a2) -> 
	Ite(subst_atoms sigma sa, subst_atom sigma a1, subst_atom sigma a2)
    | Comp (x, op, y) -> 
	let sx = subst_term sigma x in
	let sy = subst_term sigma y in
	Comp(sx, op, sy)
    | _ -> a


let build_subst args a_args =
  let rec a_subst acc args a_args =
    match args, a_args with
      | [], _ -> acc
      | x::args, ax::a_args ->
	a_subst ((x, ax)::acc) args a_args
      | _ -> assert false
  in
  a_subst [] args a_args


module ArrayAtom = struct

  type t = Atom.t array

  let equal a1 a2 =
    let n = Array.length a1 in
    let n2 = Array.length a2 in
    if n <> n2 then false
    else
      let res = ref true in
      let i = ref 0 in 
      while !res && !i < n  do
	res := (Atom.compare a1.(!i) a2.(!i) = 0);
	incr i
      done;
      !res

  let subset a1 a2 =
    if profiling then TimerSubset.start ();
    let n1 = Array.length a1 in
    let n2 = Array.length a2 in
    let s = 
      if n1 > n2 then false
      else
	let i1 = ref 0 in 
	let i2 = ref 0 in
	while !i1 < n1 && !i2 < n2 do
	  let c = Atom.compare a1.(!i1) a2.(!i2) in
	  if c = 0 then (incr i1; incr i2)
	  else if c < 0 then i2 := n2
	  else incr i2
	done;
	!i1 = n1
    in
    if profiling then TimerSubset.pause ();
    s

  let of_satom s =
    Array.of_list (SAtom.elements s)

  let union = Array.append 
    (* let a = Array.append a1 a2 in *)
    (* Array.fast_sort Atom.compare a; a *)

  let apply_subst sigma a =
    if profiling then TimerApply.start ();
    let a' = Array.init (Array.length a) (fun i -> subst_atom sigma a.(i)) in
    Array.fast_sort Atom.compare a';
    if profiling then TimerApply.pause ();
    a'

  let nb_diff a1 a2 =
    let cpt = ref 0 in
    let n1 = Array.length a1 in
    let n2 = Array.length a2 in
    let i1 = ref 0 in 
    let i2 = ref 0 in
    while !i1 < n1 && !i2 < n2 do
      let c = Atom.compare a1.(!i1) a2.(!i2) in
      if c = 0 then (incr i1; incr i2)
      else if c < 0 then (incr cpt; incr i1)
      else incr i2
    done;
    !cpt + (n1 - !i1)

  let diff a1 a2 =
    let n1 = Array.length a1 in
    let n2 = Array.length a2 in
    let i1 = ref 0 in 
    let i2 = ref 0 in
    let cpt = ref 0 in
    let d = Array.copy a1 in
    while !i1 < n1 && !i2 < n2 do
      let ai1 = a1.(!i1) in
      let c = Atom.compare ai1 a2.(!i2) in
      if c = 0 then (incr i1; incr i2)
      else if c < 0 then begin
	d.(!cpt) <- ai1;
	incr cpt;
	incr i1
      end
      else incr i2
    done;
    while !i1 < n1 do
      d.(!cpt) <- a1.(!i1);
      incr cpt;
      incr i1
    done;
    Array.sub d 0 !cpt

  let alpha atoms args =
    let subst = build_subst args alpha_vars in
    List.map snd subst, apply_subst subst atoms

end


type update = {
  up_arr : Hstring.t;
  up_arg : Hstring.t;
  up_swts : (SAtom.t * term) list;
}

type transition = {
  tr_name : Hstring.t;
  tr_args : Hstring.t list;
  tr_reqs : SAtom.t;
  tr_ureq : (Hstring.t * SAtom.t list) list;
  tr_assigns : (Hstring.t * term) list;
  tr_upds : update list;
  tr_nondets : Hstring.t list;
}

type elem = Hstring.t * (Hstring.t list)

type system = {
  globals : (Hstring.t * Hstring.t) list;
  consts : (Hstring.t * Hstring.t) list;
  arrays : (Hstring.t * (Hstring.t * Hstring.t)) list;
  type_defs : elem list;
  init : Hstring.t option * SAtom.t;
  invs : (Hstring.t list * SAtom.t) list;
  unsafe : (Hstring.t list * SAtom.t) list;
  trans : transition list
}

module STerm = Set.Make (struct type t = term let compare = compare_term end)

(* Types AST *)

type t_system = {
  t_from : (transition * Hstring.t list * t_system) list;
  t_init : Hstring.t option * SAtom.t;
  t_invs : (Hstring.t list * SAtom.t) list;
  t_unsafe : Hstring.t list * SAtom.t;
  t_arru : ArrayAtom.t;
  t_alpha : Hstring.t list * ArrayAtom.t;
  t_trans : transition list;
  mutable t_deleted : bool;
  t_nb : int;
  t_nb_father : int;
  t_abstract_signature : STerm.t;
}


let rec subst_from sigma = function
  | [] -> []
  | (tr, args, s)::l ->
    (tr, List.map (svar sigma) args, subst_system sigma s)::(subst_from sigma l)

and subst_system sigma s =
  let args, sa = s.t_unsafe in
  { s with
    t_from = subst_from sigma s.t_from;
    t_unsafe = List.map (svar sigma) args, subst_atoms sigma sa;
    t_arru = ArrayAtom.apply_subst sigma s.t_arru;
    t_abstract_signature = 
      STerm.fold 
	(fun t acc -> STerm.add (subst_term sigma t) acc)
	s.t_abstract_signature STerm.empty;
  }


let variables_term t acc = match t with
  | Elem (a, Glob) | Access (a, _) -> STerm.add t acc
  | Arith (a, Glob, _) -> STerm.add (Elem (a, Glob)) acc
  | _ -> acc

let rec variables_atom a acc = match a with
  | True | False -> acc
  | Comp (t1, _, t2) -> variables_term t1 (variables_term t2 acc) 
  | Ite (sa, a1, a2) -> 
    STerm.union (variables_of sa) (variables_atom a1 (variables_atom a2 acc))

and variables_of sa = SAtom.fold variables_atom sa STerm.empty


let declared_term x =
  match x with
    | Elem (_, Var) -> true
    | Elem (s, _) | Access (s, _) -> Smt.Typing.declared s
    | _ -> true

let declared_terms ar =
  Array.fold_left
  (fun acc -> function
    | Comp (t1, _ , t2) -> acc && declared_term t1 && declared_term t2
    | _ -> acc) true ar