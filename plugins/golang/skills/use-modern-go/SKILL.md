---
name: use-modern-go
description: Apply modern Go syntax based on project's Go version. Use when asked for modern Go code guidelines.
---

# Modern Go Guidelines

## Detected Go Version

!`grep -rh "^go " --include="go.mod" . 2>/dev/null | cut -d' ' -f2 | sort | uniq -c | sort -nr | head -1 | xargs | cut -d' ' -f2 | grep . || echo unknown`

**If detected:** Say "This project uses Go X.XX; I'll use features up to this version. Let me know if you prefer a different target." Use features accordingly — do not list them, do not ask for confirmation.
**If unknown:** Use AskUserQuestion: "Which Go version should I target?" → [1.23] / [1.24] / [1.25] / [1.26]

Use ALL applicable features up to the target version. Never use newer features; never use outdated patterns when a modern alternative exists.

---

## Features by Version

**1.0+** `time.Since(t)` not `time.Now().Sub(t)`
**1.8+** `time.Until(t)` not `t.Sub(time.Now())`
**1.13+** `errors.Is(err, target)` not `err == target`
**1.18+** `any` not `interface{}`; `strings.Cut`/`bytes.Cut(s, sep)` → `before, after, found`
**1.19+** `fmt.Appendf(buf, "x=%d", x)` not `[]byte(fmt.Sprintf(...))`; `atomic.Bool`/`atomic.Int64`/`atomic.Pointer[T]`
**1.20+** `strings.Clone`/`bytes.Clone`; `strings.CutPrefix`/`CutSuffix`; `errors.Join(e1, e2)`; `context.WithCancelCause` + `context.Cause`
**1.21+** `min`/`max`/`clear` builtins; `slices`: `Contains`, `Index`, `IndexFunc`, `Sort`, `SortFunc`, `Max`, `Min`, `Reverse`, `Compact`, `Clip`, `Clone`; `maps`: `Clone`, `Copy`, `DeleteFunc`; `sync.OnceFunc`/`OnceValue`; `context.AfterFunc`
**1.22+** `for i := range n`; loop vars goroutine-safe; `cmp.Or(a, b, "default")`; `reflect.TypeFor[T]()`; `mux.HandleFunc("GET /api/{id}", h)` + `r.PathValue("id")`
**1.23+** `maps.Keys`/`maps.Values` return iterators; `slices.Collect(iter)`, `slices.Sorted(iter)`; `time.Tick` is GC-safe (no need for `NewTicker`)
**1.24+** `t.Context()` in tests (not manual ctx+cancel); `omitzero` JSON tag (not `omitempty` for Duration/Time/structs); `b.Loop()` in benchmarks (not `for i:=0; i<b.N; i++`); `strings.SplitSeq`/`FieldsSeq` when iterating (not `strings.Split`)
**1.25+** `wg.Go(fn)` not `wg.Add(1)` + `go func() { defer wg.Done() }()`
**1.26+** `new(val)` not `x:=val; &x` — e.g. `new(30)` → `*int`, `new(true)` → `*bool`; `errors.AsType[T](err)` not `errors.As(err, &target)`
