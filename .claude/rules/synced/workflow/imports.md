---
description: Import the least the code needs, from the narrowest public entry point — where an import runs the module, a top-level entry point loads everything it re-exports, on every process, whether the code uses it or not
---

# Imports — the least the code needs

Import only what the file uses, from the narrowest entry point the dependency publishes: the
submodule that holds the symbol, not the top-level entry point that re-exports the whole package.

**Why.** Where importing a module executes it — runtimes that run a module's body when it is first
loaded — a top-level entry point that re-exports a package loads every module it re-exports, called
or not. The cost is memory and startup time on every process, and in a memory-capped or per-instance
billed deployment that is the budget the process is killed by. One measured case, a serverless HTTP
function after an SDK upgrade: importing the SDK's top-level entry point loaded twice the modules the
function needed and took startup memory past the instance's limit; importing only the three
submodules it used stayed a third below it. The code importing the SDK had not changed — the upgrade
grew what the top-level entry point loads.

```
import package                        ❌ runs every module the package re-exports
import package.http    (handler)      ✅ runs the http module and what it depends on
import package.options (configure)
```

- **Public entry points only.** The narrowest entry point is one the dependency declares or
  documents as public — never an internal file path, which can move in any release.
- **Shared state survives the split only through the same module.** When configuration set through
  one entry point is read through another, confirm both reach the same loaded module instance before
  narrowing: where the loader keeps one instance per module they share it; where two copies of the
  module are loaded, configuration set on one is invisible to the other.
- **Measure, don't assume.** Load the top-level entry point and the narrowed set alone and compare
  memory and module count. The difference is the reason for the change, recorded where the import is:
  a comment at the import, or the commit message that narrows it.
- **Where an import executes nothing** — resolved at compile time — narrowing changes nothing at run
  time; the language's own import granularity satisfies this rule, and nothing beyond it is asked.
