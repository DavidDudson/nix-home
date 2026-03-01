# Global Instructions

## Security

- NEVER commit secrets, API keys, tokens, passwords,
  or other sensitive information to any repository.
- If you encounter or are about to write sensitive
  values, stop and confirm with the user before
  proceeding.
- Use environment variables, secret managers
  (1Password CLI, agenix, sops-nix), or `.gitignore`d
  files for secrets.

## Prefer Modern CLI Tools

This system has modern replacements installed. Use them
instead of the traditional POSIX equivalents:

| Instead of | Use            | Notes                              |
|------------|----------------|------------------------------------|
| `cat`      | `bat`          | Syntax highlighting, paging        |
| `find`     | `fd`           | Simpler syntax, respects .gitignore |
| `grep`     | `rg` (ripgrep) | Faster, recursive by default       |
| `ps`       | `procs`        | Colored, human-readable output     |
| `du`       | `dust`         | Visual disk usage tree             |
| `cd`       | `z` (zoxide)   | Frecency-based directory jumping   |
| `ls`       | `eza`          | Git-aware, tree view, icons        |
| `make`     | `just`         | Simple task runner for project commands |
| fuzzy search | `fzf`        | Pipe any list through for fuzzy selection |
| git UI     | `lazygit`      | Terminal UI for git operations     |

## Communication Style

- Treat the user as an expert. Keep answers simple and concise.
- The user does not always suggest the best option
  and can get things wrong. Respectfully push back
  when you see a better approach.
- Always ask follow-up questions when requirements
  are ambiguous rather than assuming.
- During planning, confirm you have all relevant
  information before proceeding with implementation.
