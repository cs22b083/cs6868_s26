# Part 5: TSAN Verification

## Command Used
`dune exec ./test_manual.exe`

## Test 1: Non-Atomic Implementation (`ref`) - Expected Races

### Observation
TSAN reports data races on unsynchronized register access.

### Findings
- Total warnings reported: `8`
- Pattern: concurrent read and write on the same memory location by different threads

### Why Races Occur
- Registers are plain `ref`, shared across domains.
- Reads (`scan`/`collect`) and writes (`update`) are unsynchronized.
- No atomic operations or locks are used.
- Therefore, concurrent accesses produce data races.

### Example TSAN warning( only first given here)
```text
WARNING: ThreadSanitizer: data race
Read of size 8 ... by thread T14
Previous write of size 8 ... by thread T10
SUMMARY: ThreadSanitizer: data race ... in camlSnapshot$fun_366
```

### Screenshot
![TSAN non-atomic output](image.png)

---

## Test 2: Atomic Implementation (`Atomic.t`) - Expected Clean

### Observation
No data race found. Clean run with no TSAN warnings.

### Why Races Are Avoided
- `Atomic.get` and `Atomic.set` provide synchronized atomic access.
- Operations have proper memory-ordering semantics.
- TSAN does not report data races for the atomic implementation.

### Screenshot
![TSAN atomic output](image-1.png)


## Bonus 
- wait free : ore memory traffic (stores stamps + embedded snapshot arrays).
- Better progress guarantees, but typically slower in raw throughput than double-collect.
### Conclusions : 
- for speed : snapshot.ml
