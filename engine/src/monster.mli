(** Monster behaviors; see {!Monster_intf} for the interface they implement
    and how to add new ones. *)

open! Core

include Monster_intf.Monster (** @inline *)
