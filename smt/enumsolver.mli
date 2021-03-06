(**************************************************************************)
(*                                                                        *)
(*                              Cubicle                                   *)
(*                                                                        *)
(*                       Copyright (C) 2011-2014                          *)
(*                                                                        *)
(*                  Sylvain Conchon and Alain Mebsout                     *)
(*                       Universite Paris-Sud 11                          *)
(*                                                                        *)
(*                                                                        *)
(*  This file is distributed under the terms of the Apache Software       *)
(*  License version 2.0                                                   *)
(*                                                                        *)
(**************************************************************************)

exception Sat
exception Unsat of Enumsolver_types.clause list

module Make (Dummy : sig end) : sig
  type state

  val solve : unit -> unit
  val assume : (Hstring.t * int * int) list list -> cnumber : int -> unit
  val clear : unit -> unit

  val save : unit -> state
  val restore : state -> unit

end
