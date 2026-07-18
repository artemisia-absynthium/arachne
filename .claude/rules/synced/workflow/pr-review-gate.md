---
description: No PR opens until four review passes run on the branch diff — design/SOLID, standard code review, security, concurrency (concrete lens per stack)
paths:
  - "**/*"
---

# Pre-PR Review Gate

No PR is opened until FOUR review passes have run on the full branch diff and their
findings are resolved. Run them unasked — a review the user has to request is a process
failure, and by the time they ask, findings are usually too large to fix in the same PR.
The passes are independent: run them in parallel as subagents.

1. **Design / SOLID review** — the Uncle Bob (Robert C. Martin) lens: type-level single
   responsibility, ownership, state lifetimes, dependency direction, the
   `design-principles.md` thresholds and its full design review lens (SOLID, Clean
   Architecture boundaries, GRASP, Clean Code hygiene, coupling laws). Explicit verdict on
   whether any type accumulated responsibilities over the branch.
2. **Standard code review** — correctness, project conventions, error handling, test
   coverage (use the code-reviewer agent where available).
3. **Security review** — adversarial pass over the diff: secrets/credentials in code or
   history, injection, unsafe file/archive/network handling (zip-slip, path traversal),
   authn/authz gaps, supply chain (dependency pins, mutable refs), sensitive data in logs.
4. **Concurrency review** — a dedicated pass, because concurrency bugs are the class most
   frequently introduced during development and least visible in a general review: shared
   mutable state across threads / isolation domains; state assumed unchanged across a
   suspension or callback boundary (reentrancy, TOCTOU); one-shot completion primitives
   (continuations, promises) resolved exactly once, never leaked, never assumed
   cancellation-aware; task lifecycle (cancellation propagation and checks, orphaned
   background work, polling loops racing terminal state); ordering assumptions between
   async callbacks arriving from different queues/executors; every "trust me"
   thread-safety annotation justified by immutability or internal synchronization.
   Stack-specific rules files supply the concrete lens (e.g. `swift/concurrency.md`).

Findings are fixed before the PR opens, or listed explicitly to the user with a
recommendation — never silently dropped. The PR-prep report includes one verdict line per
pass.
