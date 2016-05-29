(**************************************************************************)
(*                                                                        *)
(*                              Cubicle                                   *)
(*                                                                        *)
(*                       Copyright (C) 2011-2015                          *)
(*                                                                        *)
(*                  Sylvain Conchon and Alain Mebsout                     *)
(*                       Universite Paris-Sud 11                          *)
(*                                                                        *)
(*                                                                        *)
(*  This file is distributed under the terms of the Apache Software       *)
(*  License version 2.0                                                   *)
(*                                                                        *)
(**************************************************************************)


open Types
open Util

type var = Variable.t 

type term_info = Term.t * info


type term =
  | TVar of Variable.t * info
  | TTerm of Term.t * info
    
type atom =
  | AVar of Variable.t * info
  | AAtom of Atom.t * info 
  | AEq of term * term * info 
  | ANeq of term * term * info 
  | ALe of term * term * info
  | ALt of term * term * info
    
type formula =
  | PAtom of atom 
  | PNot of formula * info
  | PAnd of formula list * info
  | POr of formula list * info 
  | PImp of formula * formula * info 
  | PEquiv of formula * formula * info 
  | PIte of formula * formula * formula * info
  | PForall of Variable.t list * formula * info  
  | PExists of Variable.t list * formula * info  
  | PForall_other of Variable.t list * formula * info 
  | PExists_other of Variable.t list * formula * info


type term_or_formula = PF of formula | PT of term


type cformula = formula
  
(* type atom = [ PAtom of Atom.t ] *)

(* type clause = [atom | POr of atom list] *)

(* type conj = [atom | PAnd of atom list] *)

(* type cnf = [clause | PAnd of clause list] *)

(* type dnf = [conj | POr of conj list] *)

(* type uguard = [PForall_other of Variable.t list * dnf] *)

(* type guard = [dnf | uguard] *)

(* type prenex_forall_dnf = [dnf | PForall of Variable.t list * dnf] *)

(* type cube = [conj | PExists of Variable.t list * conj] *)



type pswts  =  (cformula * term * info) list

type pglob_update = PUTerm of (term) | PUCase of (pswts)


type pupdate = {
  pup_loc : info;
  pup_arr : Hstring.t;
  pup_arg : var list;
  pup_swts : pswts ;
  pup_info : (Hstring.t * var list * term)  option;
}


type ptrans_pupdate = { p : pupdate list; i : info}


type ptrans_req = { r_f : cformula ; r_i : info }

type ptrans_assign = { a_n : Hstring.t ; a_p : pglob_update ; a_i : info } 

type ptrans_nondet = { n_n : Hstring.t ; n_i : info}

type ptrans_s = { ptr_assigns : ptrans_assign list; ptr_upds : ptrans_pupdate ; 
                  ptr_nondets : ptrans_nondet list; i : info}
type ptransition = {
  ptr_name : Hstring.t ;
  ptr_args : var list;
  ptr_reqs : ptrans_req ;
  ptr_s : ptrans_s;
  ptr_loc : info;
}

type unsafe = { i : info; vl : var list ; cf : cformula }

type psystem = {
  pglobals : (info * Hstring.t * Smt.Type.t) list;
  pconsts : (info * Hstring.t * Smt.Type.t) list;
  parrays : (info * Hstring.t  * (Smt.Type.t list * Smt.Type.t)) list;
  ptype_defs : (info * Ast.type_constructors) list;
  pinit : info * Variable.t list * cformula;
  pinvs : (info * var list * cformula) list;
  punsafe : (info * var list * cformula) list;
  ptrans : ptransition list;
}


type pdecl =
  | PInit of (info * var list * cformula)
  | PInv of (info * var list * cformula)
  | PUnsafe of (info * var list * cformula)
  | PTrans of ptransition
  | PFun

val add_fun_def : Hstring.t-> Smt.Type.t list -> formula -> unit

val app_fun : Hstring.t -> term_or_formula list -> formula

(* val encode_psystem : psystem -> Ast.system *)

val psystem_of_decls:
  pglobals : (info * Hstring.t * Smt.Type.t) list ->
  pconsts : (info * Hstring.t * Smt.Type.t) list ->
  parrays : (info * Hstring.t  * (Smt.Type.t  list * Smt.Type.t)) list ->
  ptype_defs : (info * Ast.type_constructors) list ->
  pdecl list -> psystem
