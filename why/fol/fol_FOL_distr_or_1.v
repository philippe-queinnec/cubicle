(* This file is generated by Why3's Coq driver *)
(* Beware! Only edit allowed sections below    *)
Require Import BuiltIn.
Require BuiltIn.

Axiom t : Type.
Parameter t_WhyType : WhyType t.
Existing Instance t_WhyType.

Axiom structure : Type.
Parameter structure_WhyType : WhyType structure.
Existing Instance structure_WhyType.

Parameter infix_breq: structure -> t -> Prop.

Parameter ffalse: t.

Parameter ttrue: t.

Parameter neg: t -> t.

Parameter and: t -> t -> t.

Parameter or: t -> t -> t.

Axiom extensionality : forall (f1:t) (f2:t), (forall (m:structure),
  (infix_breq m f1) <-> (infix_breq m f2)) -> (f1 = f2).

Axiom structure_exists : exists m:structure, exists f:t, (infix_breq m f).

Axiom true_false : ~ (ttrue = ffalse).

Axiom model_true : forall (m:structure), (infix_breq m ttrue).

Axiom model_false : forall (m:structure), ~ (infix_breq m ffalse).

Axiom model_neg : forall (m:structure), forall (f:t), (infix_breq m
  (neg f)) <-> ~ (infix_breq m f).

Axiom model_and : forall (m:structure), forall (f1:t) (f2:t), (infix_breq m
  (and f1 f2)) <-> ((infix_breq m f1) /\ (infix_breq m f2)).

Axiom model_or : forall (m:structure), forall (f1:t) (f2:t), (infix_breq m
  (or f1 f2)) <-> ((infix_breq m f1) \/ (infix_breq m f2)).

(* Why3 assumption *)
Definition sat (f:t): Prop := exists m:structure, (infix_breq m f).

(* Why3 assumption *)
Definition valid (f:t): Prop := ~ (sat (neg f)).

Axiom valid_def : forall (f:t), (valid f) <-> forall (m:structure),
  (infix_breq m f).

Axiom negneg : forall (f:t), ((neg (neg f)) = f).

Axiom and_a : forall (f1:t) (f2:t) (f3:t), ((and (and f1 f2) f3) = (and f1
  (and f2 f3))).

Axiom and_c : forall (f1:t) (f2:t), ((and f1 f2) = (and f2 f1)).

Axiom or_a : forall (f1:t) (f2:t) (f3:t), ((or (or f1 f2) f3) = (or f1 (or f2
  f3))).

Axiom or_c : forall (f1:t) (f2:t), ((or f1 f2) = (or f2 f1)).

Axiom distr_and : forall (f1:t) (f2:t) (f3:t), ((and f1 (or f2
  f3)) = (or (and f1 f2) (and f1 f3))).

(* Why3 goal *)
Theorem distr_or : forall (f1:t) (f2:t) (f3:t), ((or f1 (and f2
  f3)) = (and (or f1 f2) (or f1 f3))).
intros f1 f2 f3.
apply extensionality; split.

intro.
apply model_or in H; destruct H.
apply model_and. split.
apply model_or; left; auto.
apply model_or; left; auto.
apply model_and in H; destruct H.
apply model_and. split.
apply model_or; right; auto.
apply model_or; right; auto.

intro.
apply model_and in H; destruct H.
apply model_or in H; destruct H.
apply model_or. left; auto.
apply model_or in H0; destruct H0.
apply model_or. left; auto.
apply model_or. right. apply model_and. split; [auto | auto].

Qed.


