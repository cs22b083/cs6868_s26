# Lecture Plan: Asynchronous IO (Lecture 10 extension)

## Prerequisites (already covered)

| Runtime variant | Key idea introduced |
|---|---|
| `golike_unicore` | Cooperative fibers via effect handlers; `Trigger.t` for blocking |
| `golike_multicore` | Shared work queue across OS domains (producer-consumer monitor) |
| `golike_unicore_select` | CML-style composable events: `Select.event`, `select`, `wrap` |
| `golike_multicore_select` | Multicore + composable events (mutex-per-sync-object, lock ordering) |

Students know: `Fork`/`Yield`/`Trigger.Await` effects, `Select.select`,
`Chan.recv_evt`/`send_evt`, `Select.wrap`, `Ivar.read_evt`, `Promise.async`/`await`.

---

## Part 1 — The Problem: Fibers vs. the Outside World (~25 min)

### Motivation

All runtimes so far only communicate between fibers.  Real programs need
network IO, file IO, and timers.  How do we talk to the outside world?

### Background: How does IO work?

**System calls.** User-space programs cannot touch hardware directly.  To
read from a socket or write to a file, the program asks the OS kernel via a
*system call* (`read`, `write`, `recv`, `send`, `accept`, …).

**Blocking IO (the default).**  When you call `read(fd, buf, n)`:

1. The kernel checks whether data is available on `fd`.
2. If yes → copy data to `buf`, return immediately.
3. If no → **the calling OS thread is suspended** (put to sleep by the
   kernel) until data arrives, a timeout expires, or the fd is closed.

The key point: the OS thread itself is blocked.  It cannot do anything else
while waiting.

**What does this mean for our fiber scheduler?**  Our scheduler runs many
cooperative fibers on a small number of OS threads (domains).  If a fiber
calls a blocking syscall:

- The OS thread running that fiber's domain is **stuck in the kernel**.
- Every other fiber on that domain is **starved** — no one can run them.
- The scheduler's `run_next` loop never gets control back until the
  syscall returns.

### Demo: blocking IO starves fibers

Runnable: `tests/golike_multicore_select/blocking_io_demo.ml`

```ocaml
let () =
  let rd, _wr = Unix.pipe () in   (* nobody writes to _wr *)
  Sched.run ~num_domains:1 (fun () ->
      (* Fiber 1: blocking read — freezes the OS thread *)
      Sched.fork (fun () ->
          Printf.printf "Fiber 1: about to do blocking read (will hang)...\n%!";
          let buf = Bytes.create 1024 in
          let n = Unix.read rd buf 0 1024 in  (* blocks OS thread! *)
          Printf.printf "Fiber 1: got %d bytes (you won't see this)\n%!" n);
      (* Fiber 2: cooperative ticker — yields between prints *)
      let rec ticker i =
        if i >= 5 then
          Printf.printf "Fiber 2: done (you won't see this either)\n%!"
        else begin
          Printf.printf "Fiber 2: tick %d\n%!" i;
          Sched.yield ();
          ticker (i + 1)
        end
      in
      ticker 0)
```

Run it:

```
dune exec lectures/10_lightweight_concurrency/code/tests/golike_multicore_select/blocking_io_demo.exe
```

You see one or two prints, then the program **hangs** — Ctrl-C to kill.
The `Unix.read` call blocks the OS thread inside the kernel.  Fiber 2's
`yield` never gets a chance to execute because `run_next` never regains
control.

With 4 domains you can block at most 4 pipes before the entire program
freezes.  This is unacceptable for a server handling thousands of
connections.

### Non-blocking IO

POSIX provides a flag (`O_NONBLOCK`) that changes the contract:

- `read(fd, buf, n)` returns **immediately** with `EAGAIN` (or
  `EWOULDBLOCK`) if no data is available, instead of sleeping.
- The program must decide when to retry.

This avoids blocking the OS thread, but raises a new question: **how do we
know when to retry?**

Busy-polling wastes CPU:

```ocaml
(* BAD: spin-wait — wastes CPU, poor latency *)
let rec busy_recv fd buf =
  try Unix.recv fd buf 0 1024 []
  with Unix.Unix_error (EAGAIN, _, _) ->
    Sched.yield ();       (* let other fibers run, but we'll be right back *)
    busy_recv fd buf      (* and waste a full scheduling round each time *)
```

We need the OS to tell us *when* a file descriptor is ready.

### IO multiplexing: the OS can watch file descriptors for us

The idea: hand the OS a *set of file descriptors* and ask "wake me up when
**any** of these are ready for reading or writing."

This is called **IO multiplexing**, and every major OS provides it:

| Mechanism | OS | Notes |
|---|---|---|
| `select` | POSIX (everywhere) | Oldest; simple API; O(n) scan; `FD_SETSIZE` limit (typically 1024) |
| `poll` | POSIX | Removes `FD_SETSIZE` limit; still O(n) per call |
| `epoll` | Linux | O(1) readiness notification; edge- or level-triggered |
| `kqueue` | macOS, BSDs | Similar to epoll; unified file/socket/signal/timer/process events |
| GCD / dispatch sources | macOS | Integrates with Grand Central Dispatch |
| IOCP | Windows | Completion-based (not readiness-based); different paradigm |
| `io_uring` | Linux (5.1+) | Async submission/completion rings; can avoid syscalls entirely |

All of these solve the same core problem: **wait for multiple IO sources
without blocking a thread per source.**

**In this lecture we will use `select`** — it is the simplest, available on
every platform, and sufficient to demonstrate the architecture.  The design
we build generalizes straightforwardly to `epoll`/`kqueue`/`io_uring` (swap
out the multiplexing call, keep everything else).

### How `select` works

```
Unix.select : file_descr list -> file_descr list -> file_descr list
            -> float -> file_descr list * file_descr list * file_descr list
```

`Unix.select read_fds write_fds _ timeout` takes lists of file descriptors
to watch for reading and writing, plus a timeout (in seconds; negative means
block forever).  It **blocks the calling thread** until at least one fd is
ready, or the timeout expires.  It returns the subsets of fds that are
ready.

Two key properties:

1. **It only reports readiness** — `select` does not perform any IO itself.
   It tells you *which* fds are ready; you still have to call `read`,
   `recv`, `accept`, etc. yourself afterward.

2. **It blocks the calling thread** — while waiting, the OS thread is
   suspended in the kernel, just like a blocking `read`.

This creates the integration challenge: we want to use `select` to watch
many fds at once, but calling it from a fiber would block the entire domain
and starve all other fibers on it — the same problem we started with.

### Straw-man approaches

| Approach | Problem |
|---|---|
| Blocking `Unix.recv` inside a fiber | Blocks the OS thread; starves co-located fibers |
| Non-blocking IO + busy-poll with `Sched.yield` | Wastes CPU; poor latency |
| `Unix.select` inside a fiber | Still blocks the OS thread — same problem |

### Key insight

Run `Unix.select` on a dedicated OS thread — the **IO thread** — which is
not a fiber domain.  This thread can block in the kernel all it wants; it's
not running any fibers.  When `select` returns with ready fds, the IO
thread signals the waiting fibers through the existing `Trigger.t`
mechanism.  **No new effects needed.**

The fiber domains keep running the scheduler as before.  The IO thread
blocks in `select` (which is fine — it runs no fibers).  When a file
descriptor becomes ready, the IO thread signals the waiting fiber's
trigger, and the scheduler picks it up on the next
scheduling round.

---

## Part 2 — Architecture: The IO Thread (~20 min)

### Diagram

```
  Fiber domains (run scheduler)          IO system thread
  ┌─────────────────────────┐            ┌──────────────────┐
  │ Io.read fd buf pos len  │            │                  │
  │          │               │            │                  │
  │   wait_readable fd      │ register   │  fd_table        │
  │     create Trigger.t    │ ────────>  │  timers          │
  │     register in table   │ poke pipe  │                  │
  │     Trigger.await       │ ────────>  │  Unix.select ..  │
  │          │               │            │       │          │
  │   trigger fires ◄───────│────────────│  Trigger.signal  │
  │   fiber resumes          │            │                  │
  │   Unix.read fd buf ...  │            │                  │
  └─────────────────────────┘            └──────────────────┘
```

The key idea: the **fiber** creates a `Trigger.t`, registers it with the IO
thread, and suspends via `Trigger.await`.  When readiness is detected, the
IO thread's `Trigger.signal` wakes the fiber through the scheduler.  Then
the fiber performs the actual syscall directly.

This is essentially the approach taken by
[`aio.ml`](https://github.com/ocaml-multicore/effects-examples/blob/master/aio/aio.ml)
from the `effects-examples` repository.

### Shared state

All IO state lives in a single record:

```ocaml
type fd_waiters = {
  rd : Trigger.t Queue.t;    (* fibers waiting for read-readiness  *)
  wr : Trigger.t Queue.t;    (* fibers waiting for write-readiness *)
}

type state = {
  mutex : Mutex.t;            (* protects all mutable fields below *)
  cond : Condition.t;         (* IO thread waits here when idle    *)
  fd_table : (file_descr, fd_waiters) Hashtbl.t;
  timers : (float * Trigger.t) list ref;
  started : bool Atomic.t;   (* gates lazy initialization         *)
  wakeup_r : file_descr;     (* self-pipe read end                *)
  wakeup_w : file_descr;     (* self-pipe write end               *)
}
```

The self-pipe is created at module initialization time.  The mutable
fields — `fd_table`, `timers` — are protected by `mutex`.

Each fd maps to a pair of `Trigger.t` queues (read-waiters and
write-waiters).  When the IO thread detects readiness, it calls
`Trigger.signal` on every trigger in the relevant queue.  The trigger
mechanism is already wired into the scheduler (`Trigger.Await` effect),
so the fiber resumes on the next scheduling round.

### Concepts to walk through

1. **Self-pipe trick** — Created once at module init via `Unix.pipe` with
   both ends nonblocking.  When a fiber registers a new fd or timer, it
   writes one byte (`poke_wakeup`) to kick the IO thread out of
   `Unix.select`.

2. **Lazy startup** — `ensure_started` uses a double-checked lock
   (`Atomic.t` fast path + `Mutex` slow path).  The IO thread is spawned on
   first use, not at `Sched.run` time.  (The pipe already exists; only the
   thread creation is deferred.)

3. **The IO loop** (`io_loop`):
   - Idle: `Condition.wait` when nothing is registered.
   - Lock → collect fds from `fd_table`, compute timer timeout → unlock.
   - `Unix.select` (can block without stalling any fiber domain).
   - Lock → signal triggers for ready fds + fire due timers → unlock.
   - Tail-recurse.

4. **`Trigger.signal` is systhread-safe** — `Trigger.signal` does an
   atomic CAS (no effects performed).  This means the IO system thread can
   safely signal a fiber domain's trigger.

5. **EBADF handling** — If a monitored fd is closed, `Unix.select` raises
   `EBADF`.  The IO loop catches this, scans `fd_table` to find stale fds
   via `fstat`, wakes all their waiters, and removes the entries.

---

## Part 3 — Direct-Style IO API (~15 min)

### The internal helpers: `wait_readable` / `wait_writable`

```ocaml
let wait_readable fd =
  ensure_started ();
  let trigger = Trigger.create () in
  Mutex.lock st.mutex;
  let w = get_fd_waiters fd in
  Queue.push trigger w.rd;
  Condition.signal st.cond;
  poke_wakeup ();
  Mutex.unlock st.mutex;
  Trigger.await trigger    (* ← suspends the fiber *)
```

Three steps: create a trigger, register it with the IO thread, and await.
`wait_writable` is identical but uses `w.wr`.

### The public API: attempt first, wait-and-retry on EAGAIN

```ocaml
let read fd buf pos len =
  let rec loop () =
    match Unix.read fd buf pos len with
    | n -> n
    | exception Unix.Unix_error ((Unix.EAGAIN | Unix.EWOULDBLOCK), _, _) ->
        wait_readable fd; loop ()
  in
  loop ()

let recv fd buf pos len flags =
  let rec loop () =
    match Unix.recv fd buf pos len flags with
    | n -> n
    | exception Unix.Unix_error ((Unix.EAGAIN | Unix.EWOULDBLOCK), _, _) ->
        wait_readable fd; loop ()
  in
  loop ()

let accept fd =
  let rec loop () =
    match Unix.accept ~cloexec:true fd with
    | (cfd, addr) -> Unix.set_nonblock cfd; (cfd, addr)
    | exception Unix.Unix_error ((Unix.EAGAIN | Unix.EWOULDBLOCK), _, _) ->
        wait_readable fd; loop ()
  in
  loop ()
```

The pattern: **attempt the syscall; if `EAGAIN`/`EWOULDBLOCK` wait for
readiness and retry**.  The fd must be in non-blocking mode — otherwise
the syscall blocks the OS thread before `EAGAIN` can be raised, stalling
the entire domain.

### Points to emphasize

- **No new effects** — purely library code on top of the existing `Trigger`
  mechanism.
- Callers write `Io.recv` exactly like blocking `Unix.recv` — **direct
  style**.
- The fd **must** be in non-blocking mode (`Unix.set_nonblock`) — this is
  the caller's responsibility.  Sockets from `Io.accept` are handled
  automatically.  For externally-created fds, call `Unix.set_nonblock`
  before passing them to `Io` functions.
- **Fast path**: if data is already buffered the syscall returns immediately
  without ever suspending.
- `connect` is the interesting case: `EINPROGRESS` → `wait_writable` →
  `getsockopt_error` to check success.

### Stale readiness

With non-blocking fds there is no stale-readiness problem: if readiness
becomes stale between the `select` notification and the retry, the syscall
raises `EAGAIN` again and the loop simply waits again.  The retry loop is
correct regardless.

### Full API surface

| Function | Waits on | Then calls |
|---|---|---|
| `sleep` | timer trigger | *(nothing — just resumes)* |
| `read` / `write` | `wait_readable` / `wait_writable` | `Unix.read` / `Unix.write` |
| `recv` / `send` | `wait_readable` / `wait_writable` | `Unix.recv` / `Unix.send` |
| `accept` | `wait_readable` | `Unix.accept` |
| `connect` | `wait_writable` | `getsockopt_error` |

---

## Part 4 — Composable Timeouts (~10 min)

### The question

The `Io` module provides direct-style functions, not `Select.event` values.
So how do we compose IO timeouts with `Select.select`?

### Solution: native `Io.timeout_evt`

We make timeout a **native event** whose timer only starts when `select`
enters its offer phase:

```ocaml
let timeout_evt delay : unit Select.event = Select.Evt {
  try_complete = (fun () -> if delay <= 0. then Some () else None);
  offer = (fun _slot trigger ->
    let proxy = Trigger.create () in
    ignore (Trigger.on_signal proxy (fun () ->
      slot := Some ();
      if not (Trigger.signal trigger) then
        slot := None) : bool);
    register_timer delay proxy);
  mutex = timeout_mutex;
  wrap = Fun.id;
}
```

Key points:

- **`try_complete`** — only fires immediately if `delay <= 0`.
- **`offer`** — called by `select` under lock.  Creates a *proxy trigger*
  that, when the IO thread fires it, writes `slot := Some ()` and then
  signals the shared select trigger.  If another event already won the
  race (`Trigger.signal` returns `false`), the slot is cleared.
- **`register_timer`** — registers the deadline with the IO thread.  The
  timer starts here, not at event creation time.
- **`timeout_mutex`** — a single shared mutex satisfies the `Select.event`
  protocol.  Timeout events have no external sync object, so the mutex
  does no real work.

This makes `Io.timeout_evt` a true latent event: you can create it once and
reuse it in multiple selects, each starting its own independent timer.

### Usage

```ocaml
Select.select [
  Chan.recv_evt ch     |> Select.wrap (fun v  -> `Msg v);
  Io.timeout_evt 0.5   |> Select.wrap (fun () -> `Timeout);
]
```

### Runnable demo: `select_recv_timeout_test`

A sender fiber sends an integer message on a channel every 1 second,
forever.  The main fiber loops `n` times, each time racing a receive against
a 0.5 s timeout:

```ocaml
let sender ch =
  let i = ref 0 in
  while true do
    Io.sleep 1.0;
    Chan.send ch !i;
    incr i
  done

let receiver ch n =
  let received = ref 0 in
  while !received < n do
    match
      Select.select
        [ Chan.recv_evt ch       |> Select.wrap (fun v  -> `Msg v)
        ; Io.timeout_evt 0.5    |> Select.wrap (fun () -> `Timeout)
        ]
    with
    | `Msg v   -> Printf.printf "[receiver] msg %d\n%!" v; incr received
    | `Timeout -> Printf.printf "[receiver] timeout\n%!"
  done
```

Run it:

```
dune exec lectures/10_lightweight_concurrency/code/tests/golike_multicore_select/select_recv_timeout_test.exe
```

Expected output (timing-dependent, but the alternating pattern is stable):

```
[receiver] timeout
[receiver] msg 0
[receiver] timeout
[receiver] msg 1
[receiver] timeout
[receiver] msg 2
```

The timeout fires every 0.5 s; the sender fires every 1 s.  So roughly
one timeout appears between each message.

---

## Part 5 — Live Demo: Echo Server (~15 min)

Walk through `echo_server.ml`:

### Server side

```ocaml
let echo_handler cfd =
  let buf = Bytes.create 1024 in
  let rec loop () =
    let n = Io.recv cfd buf 0 (Bytes.length buf) [] in
    if n > 0 then begin
      (* send_all: loop until all n bytes are written *)
      send_all 0 n;
      loop ()
    end
  in
  (try loop () with Unix.Unix_error _ -> ());
  Unix.close cfd
```

Looks like sequential blocking code.  But `Io.recv` and `Io.send` suspend
the *fiber*, not the OS thread.

### Accept loop

```ocaml
Sched.fork (fun () ->
    let cfd, _addr = Io.accept server in
    Sched.fork (fun () -> echo_handler cfd));
```

One fiber per connection — goroutine style.

### Multi-client test

Two clients connect concurrently; a rendezvous channel synchronizes
shutdown.  Run it:

```
dune exec lectures/10_lightweight_concurrency/code/tests/golike_multicore_select/echo_server.exe
```

### Discussion questions

- How many OS threads? *(Domain pool + 1 IO thread)*
- 1000 clients → 1000 fibers, still few OS threads.
- How does this compare to Go's netpoller? *(Same idea, much simpler — Go
  integrates the poller into the runtime; we keep it as a library module)*

### Runnable tests

All under `tests/golike_multicore_select/`:

| Test | What it exercises |
|---|---|
| `select_timeout_test` | `Chan.recv_evt` vs `timeout_evt` — composable timeout via channel+sleep |
| `select_recv_timeout_test` | Sender every 1 s; receiver races recv vs native `Io.timeout_evt 0.5`; prints `msg`/`timeout` |
| `io_readable_test` | Pipe fd readiness via `Io.read` |
| `io_direct_test` | `Io.send` / `Io.recv` over a socketpair |
| `accept_test` | `Io.accept` with channel+sleep timeout |
| `echo_server` | Single-client and multi-client echo server/client |

---

## Part 6 — Reflection (~10 min)

### What changed?

| Component | Modified? |
|---|---|
| `Sched` (scheduler) | No |
| `Trigger` | No |
| `Select` | No |
| `Chan`, `Ivar`, `Promise` | No |
| `dune` | Yes — add `unix threads` |
| New: `Io` | Yes — IO thread + `Trigger.t` based waiting + direct syscalls + native `timeout_evt` |

**Zero lines changed in existing code.**

### The design principles

1. **Reuse `Trigger.t`** — The same mechanism that powers `Chan` and `Ivar`
   also powers IO.  The IO system thread can safely call `Trigger.signal`
   (it's an atomic CAS, no effects needed).

2. **Native timeout events** — `Io.timeout_evt` is a proper latent
   `Select.event`: the timer only starts when `select` synchronises on it.
   This avoids the eager-start problem of the fiber+channel approach, where
   the timer ticks from event creation rather than from synchronisation.
   The implementation uses a proxy `Trigger.t` to bridge the IO thread's
   signal into the `Select` slot protocol.

3. **Direct-style IO + composable events** — The `Io` module provides both
   direct-style blocking functions (`Io.read`, `Io.recv`, etc.) and a
   native `Select.event` for timeouts.  Other blocking operations can still
   be turned into `Select.event` values by running them in a fiber that
   writes to a channel — the fiber+channel pattern remains useful as a
   general composition tool.

### Comparison with real systems

| System | IO integration | Approach |
|---|---|---|
| Our runtime | `Io` module, `Trigger.t` signaling | Wait for readiness → direct syscall |
| Go | Netpoller baked into runtime | Readiness-based (integrated into goroutine scheduler) |
| Haskell/GHC | IO manager thread | Similar to our IO thread (`threadWaitRead`) |
| OCaml Eio | `rcfd` + event loop | Readiness + direct-style, production-grade |
| OCaml Lwt/Async | Monadic; callback-based IO loop | N/A (different paradigm) |
| `aio.ml` (effects-examples) | IO thread + effects | Our direct inspiration |

### Takeaway

> Adding async IO required zero changes to the scheduler, trigger
> mechanism, or channel/event machinery — only a new module that uses the
> existing `Trigger.t` to bridge between a dedicated IO thread and the
> fiber scheduler.  Timeouts are a native `Select.event` (`Io.timeout_evt`)
> whose timer starts only at synchronisation time, not at creation time.
