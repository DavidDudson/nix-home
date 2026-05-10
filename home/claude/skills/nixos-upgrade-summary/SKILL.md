---
name: nixos-upgrade-summary
description: >
  Summarize a NixOS system upgrade. Diffs two system profile generations
  (default: last two on /nix/var/nix/profiles), or parses output of
  `nh os switch --upgrade` / `nixos-rebuild switch --upgrade`. Lists each
  changed package with From → To version and a brief feature summary.
  Use when user says "summarize my nixos upgrade", "what changed in this
  switch", "explain the diff", "what's new in my last rebuild", or invokes
  /nixos-upgrade-summary.
---

# nixos-upgrade-summary

Summarize NixOS system upgrades. Show package version deltas plus a
brief "what's new" per upgraded package.

## Inputs

Accept any of:

1. **No args** — diff last two system generations under
   `/nix/var/nix/profiles/`.
2. **Two paths/numbers** — explicit generations, e.g. `170 171` or two
   profile links.
3. **Pasted output** — user pasted output from `nh os switch`,
   `nixos-rebuild`, or `nvd diff`. Parse directly, skip step 1.

## Workflow

### Step 1 — Get the diff

Prefer `nvd` (Nix Version Diff). Run via Nushell:

```nu
nix run nixpkgs#nvd -- diff \
  /nix/var/nix/profiles/system-{from}-link \
  /nix/var/nix/profiles/system-{to}-link
```

Default `from` / `to`: pick two highest `system-N-link` numbers under
`/nix/var/nix/profiles/`. Use
`ls /nix/var/nix/profiles/ | where name =~ 'system-\d+-link'` then sort
numerically.

If `nvd` is not on PATH, `nix run nixpkgs#nvd` works on any NixOS host.

If the user pasted output, skip — go to step 2.

### Step 2 — Parse the diff

`nvd` output sections of interest:

- `Version changes:` — package version updates (the main signal)
- `Added packages:` — newly added
- `Removed packages:` — gone
- `Closure size: X -> Y (+Z)` — size delta

Each `Version changes:` line looks like:

```text
[U.]  #001  firefox       120.0   -> 121.0
[C.]  #002  linux         6.1.50  -> 6.1.55
```

Extract: name, from-version, to-version. Drop store-hash suffixes if
present.

Filter low-signal noise: ignore changes where only the hash differs
(no version bump), unless user asks for full detail. Group by
importance: kernel, desktop env, browser, shell, dev tools first;
libraries last.

### Step 3 — Fetch summaries

For each upgraded package, get a 1–2 sentence "what's new". Strategy
in order:

1. **Linux kernel** — fetch from kernelnewbies.org or check changelog
   notes. For point releases, just say "stable patches; security +
   bugfixes" unless user asks for detail.
2. **Major projects (firefox, chromium, neovim, hyprland, etc.)** —
   WebFetch the release notes page or GitHub releases.
3. **GitHub-hosted** —
   `https://github.com/<owner>/<repo>/releases/tag/<version>` or
   compare URL.
4. **Unknown / niche** — WebSearch
   `"<pkg> <to-version> release notes"`. If nothing found in one
   shot, mark as `(no release notes located)` and move on. Don't
   burn tool calls.

Batch independent fetches in parallel.

Keep summaries short — one line each, two max if breaking change or
notable feature.

### Step 4 — Output

Format:

```text
NixOS upgrade: gen <from> → <to>
Closure: <X> → <Y> (<delta>)

## Upgraded (<count>)

### <package>: <from-ver> → <to-ver>
<1-2 line summary; flag breaking changes>

### <package>: ...

## Added (<count>)
- <pkg> <version> — <one-line purpose>

## Removed (<count>)
- <pkg> <version>
```

Order upgraded packages by impact (kernel/DE/browser top, libs
bottom). Collapse minor lib bumps under "## Library bumps" if >10 of
them — name plus version delta only, no summary.

## Rules

- Never invent release notes. If summary not found, say so.
- Quote breaking-change warnings exactly as upstream wrote them.
- Don't run `nh os switch` / `nixos-rebuild` yourself — read-only
  analysis. The user has already switched (or will).
- Don't fetch 50 changelogs in serial. Cap at ~15 fetches; for the
  rest, list version delta only with a note that summaries were
  skipped for brevity.
- Nushell syntax for any commands suggested to the user.

## Boundaries

Read-only. No system mutation. Output is a summary; user decides
what to do with it.
