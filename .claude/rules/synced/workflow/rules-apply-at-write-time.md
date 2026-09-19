---
description: A rule capable of failing a review is loaded and applied at the step that produces the artifact it governs, not only at the review step that can catch its absence
---

# Rules Apply at Write Time, Not Only at Review Time

Every rule a review pass can check for — a lint, a documentation convention, a test-quality
requirement, an architecture or design lens — is loaded as part of the specification *before*
the artifact that could violate it exists, not consulted for the first time when a reviewer runs
it as a checklist. "The review will catch it" is not a design: a rule that lives only in the
reviewer's frame of reference and not the writer's keeps getting violated and keeps getting
caught, which manufactures review findings instead of preventing them.

## Load the mechanism, not a list

Before producing any artifact a review pass would check — code, a test, a doc, a contract, a
comment, a plan — load every rule this project currently defines for that artifact type and
treat it as the specification the artifact must satisfy, not as a checklist run against the
finished thing afterwards.

This rule deliberately does not enumerate which files to load. Naming specific rules here would
go stale exactly the way line numbers do (see `docs-record-decisions.md`): a rule renamed, split,
or added after this one was written silently drops out of a fixed list, and nothing marks the
gap — a missing entry doesn't fail loudly the way a missing file or a broken build does. The
instruction is to load whatever currently governs the artifact being produced, not the set that
happened to exist when this was written.

That still cashes out as concrete habits, not an abstraction to admire:

- A design/architecture review lens is loaded before design-bearing code is written, and treated
  as its specification.
- A test-quality rule is loaded before a test is written, and the test is written to satisfy it.
- A documentation convention is loaded before a doc, contract, or `///` comment is written, and
  the text is written to it.
- Every brief handed to a delegated agent or subagent names the rules in force as acceptance
  criteria, not as an implicit expectation the agent is assumed to already share.

## Why

A review that finds a violation of a rule already in scope at write time is a **process gap**,
not a successful catch: the rule existed, it just wasn't loaded until it was too late to change
how the artifact was produced. The closing review still runs — but under this model its job is
to find nothing, because everything it would have caught was already prevented upstream. Treating
review as the first application of a rule is strictly worse than either applying the rule at
write time or not having the rule at all: it produces the same defect rate, plus a findings list
that reads as due diligence when it is actually evidence of a gap in the process — the rule not
being followed until something forced it.
