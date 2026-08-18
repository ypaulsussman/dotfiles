# dotfiles

Bootstrap a fresh Ubuntu laptop from an already-set-up machine: install packages, de-snap apps, clone repos, symlink configs.

## Quickstart

On the fresh machine:

```bash
sudo apt install -y git gh
git clone https://github.com/ypaulsussman/dotfiles ~/Desktop/dotfiles
cd ~/Desktop/dotfiles && bash setup.sh
```

> `gh` is needed by steps 8 and 11 but isn't installed by the script's bootstrap step, so install it before running `setup.sh`.

## What `setup.sh` does

The script has 16 sections. Each is idempotent — safe to re-run.

**System packages (1-5)**

1. Install bootstrap prerequisites (`jq`, `curl`, `gpg`, etc.) and Erlang/OTP build dependencies
2. Install [mise](https://mise.jdx.dev/) runtime manager
3. Add apt repos for de-snapped apps (Mozilla PPA for Firefox, Microsoft repo for VS Code)
4. Remove snap versions of Firefox, VS Code, VLC
5. `apt install` Firefox, VS Code, VLC from the new repos + all packages from `packages.txt`

**Desktop apps (6-7)**

6. Install [Anki](https://apps.ankiweb.net/) (latest release from GitHub)
7. Install [Talon](https://talonvoice.com/) voice control (extracted to `~/talon/`)

**Auth & sync (8-9)**

8. Authenticate with GitHub via `gh auth login`
9. Prompt to sign into Firefox Sync (passwords needed for later steps)

**Project infra (10-12)**

10. Install PostgreSQL and create superuser `y`
11. Clone `rss-reader` and `wtp` to `~/Desktop/`
12. Install runtimes via mise (bun globally; Erlang + Elixir per wtp's `.tool-versions`) and set up each project

**Dotfiles (13-15)**

13. Create target directories (`~/.claude`, `~/.config/Code/User`)
14. Symlink config files (see table below)
15. Install VS Code extensions from `vscode/extensions.txt`

**Summary (16)**

16. Print status and manual next steps

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
| `autostart/startup-windows.desktop` | `~/.config/autostart/startup-windows.desktop` | Four windows opened automatically at login |

## Login autostart

**What it does.** Opens the four windows wanted on every login, so a machine
restart doesn't mean four manual launches:

1. **Dev services** — one `gnome-terminal` window with three tabs: `talon`,
   `wtp` (Phoenix), and `hanzi-expand`. Each tab runs the matching alias from
   `.bashrc` and drops to a live shell if the service exits, so a crash leaves
   the error on screen instead of closing the tab.
2. **Files** — a Nautilus window at `~/Desktop`.
3. **Settings** — `gnome-control-center` on the Sound panel.
4. **System Monitor**.

**Where it lives.**

| File | Role |
|---|---|
| `autostart/startup-windows.desktop` | Symlinked into `~/.config/autostart/`, where GNOME looks for login entries. Sets `X-GNOME-Autostart-Delay=5` so GNOME Shell is up before the windows open. |
| `autostart/startup-windows.sh` | The launcher the `.desktop` calls. **Not symlinked** — the `Exec=` line runs it in place inside this repo. |

**How the terminal tabs work.** The `.desktop` can only run one command, hence
the launcher script. The script calls `bash -ic 'startupservices'`; the `-i`
makes bash source `~/.bashrc`, which is where `startupservices` and the aliases
it invokes (`tln`, `wtpserve`, `hzaserve`) are defined. Keeping the aliases as
the single source of truth means editing an alias updates the login behavior
too, with nothing to keep in sync.

Multi-tab requires one `gnome-terminal` invocation using the
`--window … --tab … --tab …` form. Because `--` swallows everything after it, it
can only describe one terminal, so each tab's command is passed with the
deprecated `-e` instead. If `-e` is ever removed, `startupwindows` in `.bashrc`
does the same thing as three separate windows.

**Debugging.** The script redirects all output to
`~/.cache/startup-windows.log`. Check there first if a window doesn't appear.

**Disabling.** Delete `~/.config/autostart/startup-windows.desktop`, or flip
`X-GNOME-Autostart-enabled` to `false` in the repo copy.

**Window placement.** Each window is moved to its own half-monitor:

| Window | Monitor | Position |
|---|---|---|
| Settings (Sound) | left external, `DP-1-0.3` | top half |
| System Monitor | left external, `DP-1-0.3` | bottom half |
| Terminal (3 tabs) | right external, `DP-1-0.2` | top half |
| Files (`~/Desktop`) | right external, `DP-1-0.2` | bottom half |

Only `gnome-terminal` has a `--geometry` flag, so placement goes through
**`wmctrl`** (in `packages.txt`) for uniformity. Without it the four windows
still open, just unplaced, and the log says so.

The coordinates are hardcoded constants at the top of `startup-windows.sh`,
derived from `xrandr --query` plus the 32px the GNOME top bar reserves via
`_NET_WORKAREA`. **Replugging or rearranging monitors means redoing that
arithmetic** — the comment block above the constants shows the working.

Identifying which window to move is the fiddly part. All `gnome-terminal`
windows share one `gnome-terminal-server` process and therefore one `WM_CLASS`,
so the script snapshots the matching window IDs *before* launching each app and
moves whichever ID is new. Failing that (Files, Settings, and System Monitor are
single-instance, so launching an already-running one just raises it), it falls
back to the most recent matching window.


## Projects set up by the script

| Project | Stack | Run alias | Verify |
|---|---|---|---|
| `rss-reader` | Bun / TypeScript | `rss` | `cd ~/Desktop/rss-reader && bun run dev` |
| `wtp` | Elixir / Phoenix / PostgreSQL | `wtpserve` | `cd ~/Desktop/wtp && mix phx.server` |

## Manual steps after the script

- [ ] `source ~/.bashrc`
- [ ] VS Code: sign into GitHub (Settings Sync, extensions)
- [ ] Sign into Anki (for syncing decks across devices)
- [ ] Install Claude Code (`npm install -g @anthropic-ai/claude-code` or via separate installer)

## Other files in this repo

| File | Purpose |
|---|---|
| `packages.txt` | Apt packages installed by step 5 (Chinese input, CLI tools, Erlang build deps, etc.) |
| `snaps.txt` | Inventory of default Ubuntu snaps and which ones get replaced |
| `vscode/extensions.txt` | VS Code extensions installed by step 15 |
| `.bashrc.bak` | Pre-dotfiles-repo backup of `.bashrc` |

## Re-running

The script is idempotent. Each section checks for existing state (installed packages, existing symlinks, cloned repos, created DB users) before acting. Re-running skips what's already done.
