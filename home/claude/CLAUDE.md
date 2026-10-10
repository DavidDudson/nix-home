# Global Instructions

> This file is managed by home-manager. Edit the source
> at `home/claude/CLAUDE.md` in the nix-home repo
> (`ws checkout nix-home <branch>`), not this file directly.

## Security

- NEVER commit secrets, API keys, tokens, passwords,
  or other sensitive information to any repository.
- If you encounter or are about to write sensitive
  values, stop and confirm with the user before
  proceeding.
- Use environment variables, secret managers
  (1Password CLI, agenix, sops-nix), or `.gitignore`d
  files for secrets.

## Shell

The user's shell is **Nushell**, not bash/zsh. When
suggesting commands for the user to run, always use
Nushell syntax. Do not recommend bash commands — pipes,
redirects, loops, and variable syntax all differ in
Nushell.

## Prefer Modern CLI Tools

This system has modern replacements installed. Use them
instead of the traditional POSIX equivalents:

| Instead of   | Use            | Notes                                     |
| ------------ | -------------- | ----------------------------------------- |
| `cat`        | `bat`          | Syntax highlighting, paging               |
| `find`       | `fd`           | Simpler syntax, respects .gitignore       |
| `grep`       | `rg` (ripgrep) | Faster, recursive by default              |
| `ps`         | `procs`        | Colored, human-readable output            |
| `du`         | `dust`         | Visual disk usage tree                    |
| `cd`         | `z` (zoxide)   | Frecency-based directory jumping          |
| `ls`         | `eza`          | Git-aware, tree view, icons               |
| `make`       | `just`         | Simple task runner for project commands   |
| fuzzy search | `fzf`          | Pipe any list through for fuzzy selection |
| git UI       | `lazygit`      | Terminal UI for git operations            |

## Communication Style

- Treat the user as an expert. Keep answers simple and concise.
- The user does not always suggest the best option
  and can get things wrong. Respectfully push back
  when you see a better approach.
- Always ask follow-up questions when requirements
  are ambiguous rather than assuming.
- During planning, confirm you have all relevant
  information before proceeding with implementation.
- Never refer to an issue, ticket, epic or PR by
  number alone; numbers mean nothing to the user.
  Always give the full title with it, e.g.
  "#32 Epic 4.3: Conditional adjustments".
- Always hyperlink what you mention in chat: issues,
  PRs, commits, CI runs, docs and artifacts. Use
  Markdown links to the URL, e.g.
  [#117 feat(dice): damage application](https://github.com/OWNER/REPO/pull/117),
  never a bare number or an unlinked name.
