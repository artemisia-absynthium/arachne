---
description: A version bump goes to the latest available version; an intermediate one needs a stated reason
---

# Version bumps go to the latest

When a version moves — a dependency, a toolchain, a package manifest's tools version, a deployment
or SDK floor — it moves to the **latest available** version. An intermediate version is chosen only
for a strong reason, and the reason is written where the version is: a comment at the pin, or the
commit message that moves it.

"The minimum that unlocks what I need" is not a reason. It picks a number by the feature that
prompted the bump, so the number records no decision, and the next reader cannot tell a deliberate
pin from an arbitrary one. A reason names a constraint:

- a consumer that cannot take the newer version — a test host running an older OS keeps that
  platform's floor where the host is;
- a dependency that does not support it yet, and cannot be isolated from it;
- a known regression in the latest release, cited.

"Latest available" means available to the project's selected toolchain, not the newest announced
anywhere. When a manifest's format version is tied to the toolchain, the format version is the one
the selected toolchain ships, not the lowest one that accepts the setting being raised:

```
# Raising a platform floor that the manifest format accepts from format version N on,
# built with a toolchain whose latest format version is N+2:
format-version: N      ❌ chosen by the feature that prompted the bump, not by a reason
format-version: N+2    ✅ the selected toolchain's latest
```
