---
name: upgrade-os
description: >
  Upgrade this NixOS machine end to end. Updates flake inputs (nixpkgs,
  home-manager, and friends), re-checks every package override to see if
  it is still needed, builds without activating, diagnoses failures,
  audits the diff for breaking changes against the actual config, then
  recommends `nh os boot` vs `nh os switch`. Use when the user says
  "upgrade this machine", "upgrade my system", "update nixos", "bump the
  flake", "upgrade home-manager", or invokes /upgrade-os.
---

# upgrade-os

Full NixOS upgrade run for `~/repos/nix-home`. Build first, activate
last. The user always runs the privileged step themselves.

## Ground rules

- **Never run `nh os switch` / `nh os boot` / GC yourself.** They need
  sudo, and sudo needs a password here. Hand the command to the user and
  tell them to prefix it with a bang so the output lands in the session.
- **Build, don't activate.** Everything up to activation is safe and
  reversible. Do all of it before asking for anything.
- Nushell is the shell. Any command handed to the user must be Nushell
  syntax.
- Read-only until proven necessary. Do not delete generations, do not
  `git checkout --`, do not stash the user's work.

## Step 1 — Recon

Run in parallel:

```sh
git -C ~/repos/nix-home status
git -C ~/repos/nix-home log --oneline -10
nix flake metadata ~/repos/nix-home
```

Note the lock date vs today. That gap sets expectations for how big the
rebuild is and how likely breakage becomes.

**Flag uncommitted work immediately.** Whatever is dirty in the tree gets
built and activated along with the upgrade. Tell the user what is staged
and unstaged, and confirm they want it included. Do not stash or revert
it.

## Step 2 — Inventory overrides before touching anything

```sh
rg -n "overrideAttrs|mkForce|fetchFromGitHub|packageOverrides" \
  --glob '*.nix' ~/repos/nix-home
```

Also check for `.override`, `permittedInsecurePackages`, and
`nixpkgs.overlays`.

For each hit, read the surrounding comment. A well-written override says
*why* it exists: a version incompatibility, an upstream bug, an unmerged
PR. That reason is the thing you are about to re-test.

Build a short list of override mapped to the condition that justified it.

## Step 3 — Update inputs

```sh
cd ~/repos/nix-home; nix flake update
```

`home-manager` is a flake input with `inputs.nixpkgs.follows =
"nixpkgs"`, so this upgrades home-manager too. There is no separate
home-manager step.

Report the per-input date deltas from the update output.

## Step 4 — Re-test every override against the new inputs

This is the part that actually earns the run. For each override from
step 2, determine whether its justifying condition still holds.

What rev does nixpkgs now ship?

```sh
nix eval --raw --impure --expr 'let
  f = builtins.getFlake "/home/ddudson/repos/nix-home";
  p = f.inputs.nixpkgs.legacyPackages.x86_64-linux;
in p.ATTR.src.rev'
```

Did the upstream fix land?

```sh
gh pr view N --repo OWNER/REPO --json state,title,mergedAt
gh api repos/OWNER/REPO/commits \
  --jq '.[0:8] | .[] | "\(.sha[0:8]) \(.commit.author.date)"'
```

Did home-manager or a module upstream absorb the workaround? Resolve the
input's store path and grep it:

```sh
nix eval --raw --impure --expr 'toString (builtins.getFlake
  "/home/ddudson/repos/nix-home").inputs.home-manager'
rg -n "THE_THING_YOU_FORCED" -B4 -A8 THAT_PATH/modules/
```

Three outcomes per override:

- Fix landed upstream, or the nixpkgs rev is now a superset of the pin:
  delete the override, and drop any argument it left unused, such as
  `lib`.
- Still broken for the same reason: keep it as-is.
- Still broken, but the pin itself has gone stale: repoint it at a
  current fork or PR rather than deleting it.

Do not assume "newer nixpkgs means override obsolete". A plugin pinned
for compatibility with compositor version N can break *harder* at N+1 if
upstream went unmaintained. Verify by building, not by reading version
numbers.

To test a candidate rev without editing files, get the hash first:

```sh
nix flake prefetch --json github:OWNER/REPO/REV
```

Then build the override expression directly:

```sh
nix build --no-link -L --impure --expr 'let
  f = builtins.getFlake "/home/ddudson/repos/nix-home";
  pkgs = f.inputs.nixpkgs.legacyPackages.x86_64-linux;
in pkgs.ATTR.overrideAttrs (_: {
  src = pkgs.fetchFromGitHub {
    owner = "OWNER"; repo = "REPO"; rev = "REV"; hash = "HASH";
  };
})'
```

## Step 5 — Build without activating

```sh
cd ~/repos/nix-home
nix build --no-link --print-out-paths \
  '.#nixosConfigurations.DavidDudsonPC.config.system.build.toplevel' \
  > /tmp/nixbuild.out 2>&1
```

**Redirect the full log to a file. Never pipe to `tail`.** Nix prints the
root cause early and the cascade of dependent failures last. A `tail`
throws away the only line that matters and costs a full rebuild to
recover.

Run it in the background. A three month jump is a long build.

## Step 6 — Diagnose failures

Find the root, not the cascade:

```sh
rg -n "^error|builder failed|note:" /tmp/nixbuild.out | head -30
```

The *first* error is the real one. Everything after it is `Build failed
due to failed dependency`.

**Check disk before believing a build error.** `/` here is around 197G
and fills up. A full store surfaces as an ordinary looking package build
failure with `No space left on device` buried in the log, plus a trailing
`note: build failure may have been caused by lack of free disk space`.

```sh
df -h /
du -sh /nix/store
```

If space is the problem, hand the user the command below. It is
destructive, so state plainly that it deletes old generations and their
rollback targets:

```nu
nh clean all --keep 3 --keep-since 7d
```

For a genuine build failure, get the real compiler error:

```sh
nix build --no-link -L \
  '.#nixosConfigurations.DavidDudsonPC.pkgs.ATTR' 2>&1 | tail -40
```

Then go back to step 4 for that package. A build break usually means an
override needs repointing, not deleting.

## Step 7 — Lint

Per repo convention, before any commit:

```sh
cd ~/repos/nix-home
nix-shell --run 'nixfmt CHANGED.nix && deadnix CHANGED.nix \
  && statix check . && echo LINT_OK'
```

`statix check` takes a single target, so pass `.` rather than a file
list. Run `shellcheck` on any changed `.sh`, and `markdownlint` on any
changed `.md` — this repo lints markdown at 80 columns and requires a
language on every fence.

## Step 8 — Audit the diff for breaking changes

Diff the *running* system against the built toplevel. Nothing is
activated yet, so there is no new generation to compare against:

```sh
nix run nixpkgs#nvd -- diff /nix/var/nix/profiles/system BUILT_PATH \
  > /tmp/nvd.out 2>&1
```

It runs to a thousand plus lines. Pull out the `Version changes:`,
`Added packages:`, `Removed packages:` and `Closure size:` sections.

Grep the version change block for what matters rather than reading all
of it:

```sh
rg -i "linux|nvidia|mesa|systemd|glibc|gcc|hyprland|aquamarine|python3 \
|nushell|pipewire|firefox|chromium|zed|ollama|vicinae" /tmp/nvd.out
```

Fetch release notes for the high impact bumps. Delegate to a subagent to
keep context small, cap it around 15 fetches, and instruct it explicitly
to write "(no release notes located)" rather than invent changelog
content.

**Then close the loop against the actual config.** A generic changelog is
noise. The value is knowing whether *this* machine is exposed. Checks
worth running:

- Login shell (Nushell) breaking syntax changes: grep
  `home/programs/nushell/*.nu` for the affected constructs.
- Hyprland Lua config changes: grep `home/desktop/hyprland/*.lua`.
- Any deprecated NixOS option named in a release note: grep `modules/`.

Report "verified clean" or "you are exposed here", not just the upstream
text.

## Step 9 — Recommend boot vs switch

Decide from the diff, and say why.

Use **`nh os boot` plus a reboot** when any of these moved:

- kernel (`linux`, `initrd-linux`)
- graphics driver (`nvidia-x11`, `nvidia-open`, `mesa`)
- `systemd` or `glibc`
- an ABI breaking compositor lib such as `aquamarine`, since plugins must
  load against the matching build

Rationale to give the user: activating a new driver under a live session
leaves the old kernel module loaded, so userspace and kernel module
versions diverge until reboot. `boot` skips that window entirely.

```nu
nh os boot
```

```nu
sudo reboot
```

Use **`nh os switch`** when the diff is userspace only: apps, CLI tools,
and libraries with no kernel or compositor involvement.

```nu
nh os switch
```

Always name the tradeoff of the option you did not pick.

## Step 10 — Commit and push

Once the build is green and linted, commit the upgrade and push it. Keep
the upgrade changes in their own commit. Stage files by name so any pre
existing uncommitted work found in step 1 stays out of it.

Shape: one commit covering `flake.lock` plus the override changes, whose
message explains *why* each override was removed, kept, or repointed.
Then `git push`.

Do this without waiting to be asked, but never sweep unrelated dirty
files into the commit to get there.

## Failure modes to avoid

- Piping `nix build` through `tail` and losing the root error.
- Reading a disk full error as a package incompatibility.
- Deleting an override because nixpkgs got newer, without building it.
- Recommending `switch` after a kernel or driver bump.
- Trying to run sudo commands yourself instead of handing them over.
- Stashing, reverting, or committing the user's in progress work.
