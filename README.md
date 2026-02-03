# dotfiles

Bootstrap a fresh Ubuntu laptop from an already-set-up machine: install packages, de-snap apps, clone repos, symlink configs.

## Quickstart

On the fresh machine:

```bash
sudo apt install -y git gh
git clone https://github.com/ypaulsussman/dotfiles ~/Desktop/dotfiles
cd ~/Desktop/dotfiles && bash setup.sh
```

> `gh` is needed by steps 6 and 9 but isn't installed by the script's bootstrap step, so install it before running `setup.sh`.

## What `setup.sh` does

The script has 14 sections. Each is idempotent — safe to re-run.

**System packages (1-5)**

1. Install bootstrap prerequisites (`jq`, `curl`, `gpg`, etc.) and Erlang/OTP build dependencies
2. Install [mise](https://mise.jdx.dev/) runtime manager
3. Add apt repos for de-snapped apps (Mozilla PPA for Firefox, Microsoft repo for VS Code)
4. Remove snap versions of Firefox, VS Code, VLC
5. `apt install` Firefox, VS Code, VLC from the new repos

**Auth & sync (6-7)**

6. Authenticate with GitHub via `gh auth login`
7. Prompt to sign into Firefox Sync (passwords needed for later steps)

**Project infra (8-10)**

8. Install PostgreSQL and create superuser `y`
9. Clone `rss-reader` and `wtp` to `~/Desktop/`
10. Install runtimes via mise (bun globally; Erlang + Elixir per wtp's `.tool-versions`) and set up each project

**Dotfiles (11-13)**

11. Create target directories (`~/.claude`, `~/.config/Code/User`)
12. Symlink config files (see table below)
13. Install VS Code extensions from `vscode/extensions.txt`

**Summary (14)**

14. Print status and manual next steps

## What gets symlinked

| Source | Destination | What it configures |
|---|---|---|
| `.bashrc` | `~/.bashrc` | Shell aliases, mise activation, git shortcuts, project commands |
| `.psqlrc` | `~/.psqlrc` | psql extended display, NULL rendering, custom prompt |
| `.claude/settings.json` | `~/.claude/settings.json` | Claude Code permissions, thinking mode, status line |
| `.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Claude Code behavioral guidelines |
| `.claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | Status line: dir, branch, context % |
| `vscode/settings.json` | `~/.config/Code/User/settings.json` | Editor prefs, formatters, theme, Copilot |
| `vscode/keybindings.json` | `~/.config/Code/User/keybindings.json` | Ctrl+Tab nav, swapped Ctrl+O/P, terminal focus |

## Projects set up by the script

| Project | Stack | Run alias | Verify |
|---|---|---|---|
| `rss-reader` | Bun / TypeScript | `rss` | `cd ~/Desktop/rss-reader && bun run dev` |
| `wtp` | Elixir / Phoenix / PostgreSQL | `wtpserve` | `cd ~/Desktop/wtp && mix phx.server` |

## Manual steps after the script

- [ ] `source ~/.bashrc`
- [ ] VS Code: sign into GitHub (Settings Sync, extensions)
- [ ] Install Claude Code (`npm install -g @anthropic-ai/claude-code` or via separate installer)

## Other files in this repo

| File | Purpose |
|---|---|
| `snaps.txt` | Inventory of default Ubuntu snaps and which ones get replaced |
| `vscode/extensions.txt` | VS Code extensions installed by step 13 |
| `.bashrc.bak` | Pre-dotfiles-repo backup of `.bashrc` |

## Re-running

The script is idempotent. Each section checks for existing state (installed packages, existing symlinks, cloned repos, created DB users) before acting. Re-running skips what's already done.
