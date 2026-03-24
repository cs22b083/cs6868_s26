(** A single-assignment variable (multicore-safe).

    An IVar is either empty or filled with a value. Once filled, it
    cannot be changed. Multiple readers can wait on the same IVar;
    all are woken when it is filled.

    Uses a [Mutex] to protect the trigger list. The state field is
    stored in an [Atomic.t] so that the read after wakeup needs no lock
    (once filled, the state is immutable). *)

type 'a t

val create : unit -> 'a t
(** Create a new empty IVar. *)

val fill : 'a t -> 'a -> unit
(** [fill ivar v] fills the IVar with [v] and wakes all waiting readers.
    @raise Failure if the IVar is already filled. *)

val read : 'a t -> 'a
(** [read ivar] returns the value if filled, or blocks until it is. *)

val readEvt : 'a t -> 'a Select.event
(** [readEvt ivar] is an event that, when synchronised on, reads from [ivar]. *)
