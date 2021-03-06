(* This file has been generated from Why3 module Cubicle_BRAB *)

open Fol__FOL
module AQ = Abstract_queue__AbstractQueue

type result =
  | Safe
  | Unsafe

type kind =
  | Undef
  | Appr
  | Orig

let finite_model  : Fol__FOL.t = (* TODO: change this *)
  Fol__FOL.ffalse

exception Unsafe_trace

let visited  : (Fol__FOL.t Pervasives.ref) =
  ref ffalse



let bad  : (Fol__FOL.t Pervasives.ref) =
  ref ffalse



let faulty  : (Fol__FOL.t Pervasives.ref) =
  ref ffalse



let q  : Abstract_queue__AbstractQueue.t = AQ.create ()




let kind  : (((Fol__FOL.t, kind) Map__Map.map) Pervasives.ref) =
  ref Map__Map.empty



let from  : (((Fol__FOL.t, Fol__FOL.t) Map__Map.map) Pervasives.ref) =
  ref Map__Map.empty



(*-----------------  Begin manually edited ------------------*)
let cpt = ref 0
(*------------------  End manually edited -------------------*)


let approx (phi: Fol__FOL.t) : (Fol__FOL.t option) =
  (*-----------------  Begin manually edited ------------------*)
  if not Options.do_brab then None
  else
    let ls = Fol__FOL.fol_to_cubes phi in
    let la = List.fold_left (fun acc s ->
			     Brab.subsuming_candidate s @ acc) [] ls in
    match la with
    | [] -> None 
    |  _ ->
       decr cpt;
       let psi = Fol__FOL.cubes_to_fol la in
       if Why3.Term.t_equal psi phi then None else
       if List.exists (fun sbad -> 
                       Fol__FOL.infix_breqeq psi sbad
                      ) (Translation.dnf_to_conj_list !bad) then None
       else 
         begin
           Format.eprintf ">> %a APproximated BY %a@." 
	                  Fol__FOL.print phi Fol__FOL.print psi;
           Some psi
         end
  (*------------------  End manually edited -------------------*)

(* let approx2 phi = match approx phi with *)
(*   | None -> phi *)
(*   | (Some psi) -> *)
(*       begin let o = *)
(*               (let o1 = (Pervasives.(!) kind) in *)
(*               (Map__Map.mixfix_lblsmnrb o1 psi Appr)) in *)
(*       ((Pervasives.(:=) kind) o); *)
(*       begin if let o = *)
(*                  (let o1 = (Pervasives.(!) kind) in *)
(*                  (Map__Map.mixfix_lbrb o1 phi)) in *)
(*             ((o = Orig)) *)
(*             then let o = *)
(*                    (let o1 = (Pervasives.(!) from) in *)
(*                    (Map__Map.mixfix_lblsmnrb o1 psi psi)) in *)
(*               ((Pervasives.(:=) from) o) *)
(*             else begin let o = *)
(*                    (let o1 = *)
(*                       (let o2 = (Pervasives.(!) from) in *)
(*                       (Map__Map.mixfix_lbrb o2 phi)) in *)
(*                    let o2 = (Pervasives.(!) from) in *)
(*                    (Map__Map.mixfix_lblsmnrb o2 psi o1)) in *)
(*               ((Pervasives.(:=) from) o) end; *)
(*       psi end end *)


let pre_or_approx (phi: Fol__FOL.t) ((* ghost *)) ((* ghost *)) =
  (*-----------------  Begin manually edited ------------------*)
  incr cpt; Format.eprintf "\n%d@." !cpt;
  if Options.verbose > 0 then Format.eprintf "pre_or_approx %a@." Fol__FOL.print phi;
  (*------------------  End manually edited -------------------*)
  (match (approx phi) with
  | (Some psi) ->
      begin let o =
              (let o1 = (Pervasives.(!) kind) in
              (Map__Map.mixfix_lblsmnrb o1 psi Appr)) in
      ((Pervasives.(:=) kind) o);
      begin if let o =
                 (let o1 = (Pervasives.(!) kind) in
                 (Map__Map.mixfix_lbrb o1 phi)) in
            ((o = Orig))
            then let o =
                   (let o1 = (Pervasives.(!) from) in
                   (Map__Map.mixfix_lblsmnrb o1 psi psi)) in
              ((Pervasives.(:=) from) o)
            else begin let o =
                   (let o1 =
                      (let o2 = (Pervasives.(!) from) in
                      (Map__Map.mixfix_lbrb o2 phi)) in
                   let o2 = (Pervasives.(!) from) in
                   (Map__Map.mixfix_lblsmnrb o2 psi o1)) in
              ((Pervasives.(:=) from) o) end;
      psi end end
  | _ ->
      let psi = (Reachability__Reachability.pre phi) in
      begin ((* assert *));
      begin let o =
              (let o1 =
                 (let o2 = (Pervasives.(!) kind) in
                 (Map__Map.mixfix_lbrb o2 phi)) in
              let o2 = (Pervasives.(!) kind) in
              (Map__Map.mixfix_lblsmnrb o2 psi o1)) in
      ((Pervasives.(:=) kind) o);
      begin let o =
              (let o1 =
                 (let o2 = (Pervasives.(!) from) in
                 (Map__Map.mixfix_lbrb o2 phi)) in
              let o2 = (Pervasives.(!) from) in
              (Map__Map.mixfix_lblsmnrb o2 psi o1)) in
      ((Pervasives.(:=) from) o); psi end end end)

let bwd (init: Fol__FOL.t) (theta: Fol__FOL.t) =
  begin let o = (Fol__FOL.ffalse) in
  ((Pervasives.(:=) visited) o);
  begin (Abstract_queue__AbstractQueue.clear q);
  (try begin ((Pervasives.(:=) faulty) theta);
       begin let o =
               (let o1 = (Pervasives.(!) from) in
               (Map__Map.mixfix_lblsmnrb o1 theta theta)) in
       ((Pervasives.(:=) from) o);
       begin let o =
               (let o1 = (Pervasives.(!) kind) in
               (Map__Map.mixfix_lblsmnrb o1 theta Orig)) in
       ((Pervasives.(:=) kind) o);
       begin if (Fol__FOL.sat (Fol__FOL.infix_et init theta))
             then raise Unsafe_trace
             else (());
       begin let o =
               (let o1 = (Pervasives.(!) visited) in
               (Fol__FOL.infix_plpl theta o1)) in
       ((Pervasives.(:=) visited) o);
       let pre_theta = (Reachability__Reachability.pre theta) in
       begin let o =
               (let o1 = (Pervasives.(!) from) in
               (Map__Map.mixfix_lblsmnrb o1 pre_theta theta)) in
       ((Pervasives.(:=) from) o);
       begin let o =
               (let o1 = (Pervasives.(!) kind) in
               (Map__Map.mixfix_lblsmnrb o1 pre_theta Orig)) in
       ((Pervasives.(:=) kind) o);
       begin ((Abstract_queue__AbstractQueue.push pre_theta) q);
       begin (try while true do
                  if let o = (Abstract_queue__AbstractQueue.is_empty q) in
                  (not (o = true))
                  then let phi1 = (Abstract_queue__AbstractQueue.pop q) in
                       (* let phi1 = approx2 phi1 in *)
                    begin if (Fol__FOL.sat (Fol__FOL.infix_et init phi1))
                          then begin ((Pervasives.(:=) faulty) phi1);
				     (*-----------------  Begin manually edited ------------------*)
				     Format.eprintf "unsafe %a@." Fol__FOL.print !faulty;
				     (*------------------  End manually edited -------------------*)
                               raise Unsafe_trace end
                          else (());
                    if let o =
                         (let o1 = (Pervasives.(!) visited) in
                         (Fol__FOL.infix_breqeq phi1 o1)) in
                    (not (o = true))
                    then begin let o =
                                 (let o1 = (Pervasives.(!) visited) in
                                 (Fol__FOL.infix_plpl phi1 o1)) in
                         ((Pervasives.(:=) visited) o);
                         let poa = (((pre_or_approx phi1) ((* ghost o *)))
                           ((* ghost o1 *))) in
                         (* if Map__Map.mixfix_lbrb (!kind) poa = Appr && *)
                         (*      Map__Map.mixfix_lbrb (!from) poa == poa then visited := o; *)
                         begin ((Abstract_queue__AbstractQueue.push poa) q);
                         ((* assert *)) end end
                    else ((* assert *)) end
                  else raise Why3__Prelude.PcExit done with
             | Why3__Prelude.PcExit -> (()));
       (Safe) end end end end end end end end end with
  | Unsafe_trace -> (Unsafe)
  | Abstract_queue__AbstractQueue.Empty -> assert false (* absurd *)) end end

let reset_maps (theta1: Fol__FOL.t) : unit =
  kind := Map__Map.empty;
  kind := Map__Map.empty;
  from := Map__Map.empty
  


let bwd_res  : (result Pervasives.ref) =
  ref Unsafe



let brab (init1: Fol__FOL.t) (theta1: Fol__FOL.t) =
  begin let o2 = (Fol__FOL.ffalse) in
  ((Pervasives.(:=) bad) o2);
  (try begin let o2 = ((bwd init1) theta1) in
       ((Pervasives.(:=) bwd_res) o2);
       begin (try while true do
                  if let o2 = (Pervasives.(!) bwd_res) in
                  ((o2 = Unsafe))
                  then begin 
		 (*-----------------  Begin manually edited ------------------*)
                  Format.eprintf "unsafe %a@." Fol__FOL.print !faulty;
 		 (*------------------  End manually edited -------------------*)
                             if let o2 =
                                  (let o3 = (Pervasives.(!) faulty) in
                                  let o4 = (Pervasives.(!) kind) in
                                  (Map__Map.mixfix_lbrb o4 o3)) in
                             ((o2 = Orig))
                             then 
			       (raise Unsafe_trace)
                             else (());
                       begin let o2 =
                               (let o3 = (Pervasives.(!) bad) in
                               let o4 =
                                 (let o5 = (Pervasives.(!) faulty) in
                                 let o6 = (Pervasives.(!) from) in
                                 (Map__Map.mixfix_lbrb o6 o5)) in
                               (Fol__FOL.infix_plpl o4 o3)) in
                       ((Pervasives.(:=) bad) o2);
                       begin (reset_maps theta1);
                       let o2 = ((bwd init1) theta1) in
                       ((Pervasives.(:=) bwd_res) o2) end end;
		       (*-----------------  Begin manually edited ------------------*)
		       Format.eprintf "\n---------------BACKTRACKING---------------@.";
		       (*------------------  End manually edited -------------------*)
		       end
                  else raise Why3__Prelude.PcExit done with
             | Why3__Prelude.PcExit -> (()));
       (Safe) end end with
  | Unsafe_trace -> (Unsafe)) end
