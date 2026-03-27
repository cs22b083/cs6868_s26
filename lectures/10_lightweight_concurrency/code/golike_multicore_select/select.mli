(** CML-style composable events and select (multicore-safe).

    Sync objects (channels, IVars, …) expose events via functions such
    as {!Chan.recv_evt} and {!Ivar.read_evt}.  {!select} acquires
    all involved locks in mutex-address order, scans for an immediately
    ready case, and if none is found, offers a single shared {!Trigger.t}
    to all cases before blocking.

    {[
      Select.select [
        Chan.recv_evt ch1 |> Select.wrap (fun v -> `Ch1 v);
        Chan.recv_evt ch2 |> Select.wrap (fun v -> `Ch2 v);
        Ivar.read_evt iv  |> Select.wrap (fun v -> `Iv v);
      ]
    ]} *)

(** An event that, when synchronised on, produces a value of type ['b]. *)
type 'b event = Evt : {
  try_complete : unit -> 'a option;
  (** Non-blocking attempt (called under lock). *)
  offer : 'a option ref -> Trigger.t -> unit;
  (** Enqueue a waiter (called under lock). *)
  mutex : Mutex.t;
  (** The sync object's mutex. *)
  wrap : 'a -> 'b;
  (** Post-processing applied to the raw result. *)
} -> 'b event

val wrap : ('b -> 'c) -> 'b event -> 'c event
(** [wrap f evt] transforms the result of [evt] by applying [f]. *)

val select : 'b event list -> 'b
(** [select events] blocks until one event completes and returns its
    (wrapped) result.  At most one event fires.
    @raise Invalid_argument if [events] is empty. *)
