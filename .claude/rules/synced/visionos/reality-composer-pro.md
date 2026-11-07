---
description: Tell a Reality Composer Pro 3 project from an RCP 2 one before judging it — RCP 2's .rkassets compile into a .reality at every Xcode build, while RCP 3 is a standalone editor whose bundle store is the project and whose .reality is exported outside the build and committed; both load through Entity(named:), so RCP 2 conclusions about loose USD, caches and the pipeline do not carry over
---

# Reality Composer Pro — Identify the Version Before Judging a Project

Reality Composer Pro 3 is not an update of RCP 2 but a different editor, with a different project
model and a different route into the app; Apple: "This release fully deprecates and removes the
previous version of Reality Composer Pro." A judgment made on the RCP 2 model — which files are
source and which are caches, what the build compiles, what the app loads — is wrong for an RCP 3
project, and the reverse. Identify the version from the files first, before reviewing, editing or
advising on either.

## Telling them apart

| | RCP 2 | RCP 3 |
|---|---|---|
| Project | `Package.realitycomposerpro/` at the root of a content Swift package | a `<Name>.realitycomposerpro` bundle, in the same repository as the Xcode project |
| Marker | `ProjectData/main.json`: `.rkassets` scene paths mapped to IDs | `project.rcp`, with `rcp_original` and `rcp_version` keys |
| Project state | the USD scenes in `Sources/<Name>/<Name>.rkassets` | the bundle's store: `tm_*` text files, plus binaries in `*.tm_buffers/` |
| Imported content | edited in place, as USD | `<asset>.import/` folders: the converted entity, its geometry, meshes and materials, and `settings.tm_usd` |
| Default content | none | `core.lib/`, and a `world.tm_entity` in a new project |
| Compiled to `.reality` | by Xcode, at every build: `.rkassets` in, `<Name>.reality` inside `<Name>_<Name>.bundle` out | by RCP 3, outside Xcode's build — Export To > Reality, or a linked project's automatic export — and again after each content change |
| Versioned | the `.rkassets`; the `.reality` is a build product | the project and the exported `.reality`, both committed |
| Load call | `Entity(named: "<path in .rkassets>", in: <name>Bundle)`, the package's `Bundle.module` constant | `Entity(named: "<scene name>")`, from the app's own bundle |

The initializer is the same — `Entity(named:in:)` loads "The base name of the file to load …, or
scene name if loading from a `.reality` file" — so its symbol never tells the two apart; its
arguments and the target's sources do: a package bundle constant, a file path and an `.rkassets`
folder are RCP 2; a scene name and an exported `.reality` are RCP 3.

`project.rcp` is the RCP 3 marker, whatever the bundle is called or where it sits. What its two
keys record is not documented: a new project and a migrated one can both read `"3.0"` for each,
so the pair does not tell them apart.

Sources (2026-11): Apple's *Reality Composer Pro* documentation (*Migrating older projects to
Reality Composer Pro 3*, *Adding entities and assets to a scene*, *Linking an Xcode project*);
WWDC26 session 281, *Extend Reality Composer Pro 3 functionality with Xcode*; Apple's sample
*Designing no-code games with Reality Composer Pro 3* for the RCP 3 layout; Xcode 27's
`RealityAssets.xcspec` and `realitytool compile --help` for what the build compiles; RCP 2
content packages and their built resource bundles for the RCP 2 column.

## How RCP 3 works

- **The bundle's store is the project.** Documented: its state "lives in this store rather than
  in loose USD files", and "A Reality Composer Pro 3 project is a database of assets"; WWDC26-281:
  an imported file "gets converted to an internal data format and saved on disk as JSON files".
  Nothing in it is documented as derived or regenerable, so none of it is a cache.
- **Xcode never builds the project.** Its only Reality asset rule takes `.rkassets` input, so an
  RCP 3 project reaches an app solely as the `.reality` RCP 3 exports. WWDC26-281: "the scenes
  created in Reality Composer Pro 3 are exported to a Reality File which is linked into and loaded
  by the app", and "When the content is changed, a new reality file is exported". The exported
  file is a plain resource of the app target, not a package resource bundle.
- **Imports are read-only conversions that keep a link to their source.** Documented: RCP 3
  "treats all imported assets as read-only files" and "Imported assets also include their
  dependencies"; it can re-import when the source changes. Each `<asset>.import/settings.tm_usd`
  records `source_path`, relative to the `.import` folder. A path that leaves the repository is
  normal — Apple's sample ships several — and re-import from it works only where it resolves.
- **The project is versioned whole, next to the app.** WWDC26-281: "The editor project and the
  Xcode project live together in the same git repository", and "the editor also comes with a
  custom merge tool that can merge files with fewer conflicts than standard git merge". Apple's
  sample commits every file in the bundle and the exported `.reality`, as plain git blobs.
- **A linked Xcode project is recorded by path.** Documented: "If you move or rename the
  `.xcodeproj`, or open it on another Mac where the path is different, Reality Composer Pro 3
  treats the project as unlinked". Apple's sample stores it relative to the project settings file.

Some RCP 3 pages still carry RCP 2 text — the `realityKitContentBundle` loading example in
*Previewing content and running simulations*, and "Xcode still compiles these assets into your
app" in *Adding entities and assets to a scene*. Xcode's build rule contradicts both; do not cite
them as RCP 3 behaviour.

## Checks for an RCP 3 project in a repository

- **The app loads a `.reality` exported from this project.** An RCP 3 project whose app target
  still ships an `.rkassets` folder, loaded with `Entity(named:in: <name>Bundle)`, is on the RCP 2
  pipeline: Xcode compiles the `.rkassets` at every build, edits in the project reach no build, and
  the two sources drift apart. Ask which one is the source.
- **The exported `.reality` moves with the content.** Nothing in Xcode's build re-exports it, so a
  change to the project's store without a new `.reality` ships the old content.
- **Size is a repository decision.** Committed whole, as Apple does, one project is hundreds of MB
  (Apple's sample: a 715 MB bundle, `core.lib/` 88 MB, and a 172 MB `.reality`). Whether those
  blobs go to LFS is the repository's policy, not Apple's guidance. If they do:
  - Track the binaries by folder, not extension: most `*.tm_buffers/` entries are named
    `<uuid>.<hex>` with no media extension, so extension patterns (`*.png`, `*.usdc`) miss them.
  - Lead the pattern with `**/`. A pattern containing a slash is anchored to the directory of its
    `.gitattributes`, so `*.tm_buffers/**` matches only a bundle at that level and misses every
    buffer below it — measured with `git check-attr`:

    ```
    **/*.tm_buffers/** filter=lfs diff=lfs merge=lfs -text
    **/*.reality filter=lfs diff=lfs merge=lfs -text
    ```

  - Keep the `tm_*` text files (`project.rcp`, `*.tm_entity`, `*.tm_material`, `*.tm_meta`,
    `settings.tm_usd`) in plain git: an LFS file cannot be merged as text, and RCP 3's merge tool
    exists for these.
  - Blobs already committed move only by a history rewrite: `git lfs migrate import` with the same
    patterns in `--include`, scoped to the topic branch with `--include-ref` and an
    `--exclude-ref` on the remote integration branch, so shared history is left alone.
- **Exclude nothing from the bundle on assumption.** Apple commits it whole, and which store files
  a fresh clone can do without is not documented.
