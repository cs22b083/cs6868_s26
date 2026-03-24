(** Asynchronous IO for fibers.

    A dedicated system thread runs a {!Unix.select} loop.  Fibers
    register interest in file-descriptor readiness or timers, suspend
    via {!Trigger.await}, and are woken when the condition is met.
    The fiber then performs the actual syscall — which is expected to
    succeed immediately since readiness was just reported.

    {b Note:} there is a small window between the readiness notification
    and the syscall during which another thread could consume the data.
    In practice this is harmless for our single-reader-per-fd usage. *)

type file_descr = Unix.file_descr

type sockaddr = Unix.sockaddr

type msg_flag = Unix.msg_flag

val sleep : float -> unit
(** [sleep d] suspends the current fiber for [d] seconds. *)

val read : file_descr -> bytes -> int -> int -> int
(** [read fd buf pos len] waits until [fd] is readable, then reads. *)

val write : file_descr -> bytes -> int -> int -> int
(** [write fd buf pos len] waits until [fd] is writable, then writes. *)

val recv : file_descr -> bytes -> int -> int -> msg_flag list -> int
(** [recv fd buf pos len flags] waits until [fd] is readable, then receives. *)

val send : file_descr -> bytes -> int -> int -> msg_flag list -> int
(** [send fd buf pos len flags] waits until [fd] is writable, then sends. *)

val accept : file_descr -> file_descr * sockaddr
(** [accept fd] waits until [fd] is readable, then accepts a connection.
    The returned socket is set to non-blocking mode. *)

val connect : file_descr -> sockaddr -> unit
(** [connect fd addr] initiates a connection on a non-blocking socket and
    waits until the handshake completes. *)
