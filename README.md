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

**Dotfiles (13-14)**

13. Create target directories (`~/.claude`, `~/.config/Code/User`)
14. Symlink config files (see table below)

**Summary (15)**

16. Print status and manual next steps

## What gets symlinked

| Source | Destination | What it configures |
|---|---|---|
| `.bashrc` | `~/.bashrc` | Shell aliases, mise activation, git shortcuts, project commands |
| `.psqlrc` | `~/.psqlrc` | psql extended display, NULL rendering, custom prompt |
| `.claude/settings.json` | `~/.claude/settings.json` | Claude Code permissions, thinking mode, status line |
| `.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Claude Code behavioral guidelines |
| `.claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | Status line: dir, branch, context % |
| `.claude/hooks/session-checklist.sh` | `~/.claude/hooks/session-checklist.sh` | SessionStart hook: injects a pre-flight checklist |
| `vscode/settings.json` | `~/.config/Code/User/settings.json` | Editor prefs, formatters, theme, Copilot |
| `vscode/keybindings.json` | `~/.config/Code/User/keybindings.json` | Ctrl+Tab nav, swapped Ctrl+O/P, terminal focus |
| `autostart/startup-windows.desktop` | `~/.config/autostart/startup-windows.desktop` | Four windows opened automatically at login |

### Checking for drift

Every destination above is a *symlink into this repo*, so editing the file on
the machine edits the repo — that's the whole point, and it's why there's no
copy step to remember.

A symlink can quietly stop being one: an editor that writes-and-renames, a
restore from backup, or a `cp` over the destination all leave a regular file
behind. From then on the machine and the repo drift silently, and nothing warns
you. Check them all:

```bash
for f in ~/.bashrc ~/.psqlrc ~/.claude/settings.json ~/.claude/CLAUDE.md \
         ~/.claude/statusline-command.sh ~/.claude/hooks/session-checklist.sh \
         ~/.config/Code/User/settings.json ~/.config/Code/User/keybindings.json \
         ~/.config/autostart/startup-windows.desktop; do
  [ -L "$f" ] && echo "  ok     $f" || echo "  DRIFT  $f"
done
```

### Re-linking a drifted file

**Reconcile before you link.** `ln -sf` overwrites the destination, so the
machine's version — which is the newer one, by definition, since that's how it
drifted — is gone the moment you link. Keep it, diff it, fold what you want
into the repo copy, *then* link:

```bash
cp ~/.bashrc ~/.bashrc.pre-symlink                     # 1. preserve the live version
diff ~/.bashrc.pre-symlink .bashrc                     # 2. reconcile into the repo copy
ln -sf "$PWD/.bashrc" ~/.bashrc                        # 3. now it's safe to link
```

`setup.sh` step 14 does the same thing automatically on a fresh machine, moving
any regular file it finds to `<dest>.bak` before linking. That backup is worth
reading rather than deleting — it's the drifted content.


## Login autostart

**What it does.** Opens the five windows wanted on every login, so a machine
restart doesn't mean five manual launches:

1. **Dev services** — one `gnome-terminal` window with two tabs: `talon` and
   `wtp` (Phoenix). The `talon` tab only opens in an X11 session (Talon is
   X11-only and crashes under Wayland); under GNOME/Wayland it's just `wtp`.
   Each tab runs the matching alias from `.bashrc` and drops
   to a live shell if the service exits, so a crash leaves the error on screen
   instead of closing the tab. (`hanzi-expand` used to be a third tab; it's now
   started by hand with `hzaserve`.)
2. **Files** — a Nautilus window at `~/Desktop`.
3. **Settings** — `gnome-control-center` on the Sound panel.
4. **Resources** — replaced System Monitor in Ubuntu 26.04.
5. **Claude Desktop** — on the *second* workspace, so `Super+PageDown` after
   login lands on it.

**Where it lives.**

| File | Role |
|---|---|
| `autostart/startup-windows.desktop` | Symlinked into `~/.config/autostart/`, where GNOME looks for login entries. Sets `X-GNOME-Autostart-Delay=5` so GNOME Shell is up before the windows open. |
| `autostart/startup-windows.sh` | The launcher the `.desktop` calls. **Not symlinked** — the `Exec=` line runs it in place inside this repo. |

**How the terminal tabs work.** The `.desktop` can only run one command, hence
the launcher script. The script calls `bash -ic 'startupservices'`; the `-i`
makes bash source `~/.bashrc`, which is where `startupservices` and the aliases
it invokes (`tln`, `wtpserve`) are defined. Keeping the aliases as
the single source of truth means editing an alias updates the login behavior
too, with nothing to keep in sync.

Multi-tab requires one `gnome-terminal` invocation using the
`--window … --tab …` form. Because `--` swallows everything after it, it
can only describe one terminal, so each tab's command is passed with the
deprecated `-e` instead. If `-e` is ever removed, `startupwindows` in `.bashrc`
does the same thing as two separate windows.

**Debugging.** The script redirects all output to
`~/.cache/startup-windows.log`. Check there first if a window doesn't appear.

**Disabling.** Delete `~/.config/autostart/startup-windows.desktop`, or flip
`X-GNOME-Autostart-enabled` to `false` in the repo copy.

**Window placement.** None, since the Ubuntu 26.04 upgrade (2026-11-05).
GNOME 50 is Wayland-only, and on Wayland `wmctrl` can't see or move native
windows, so the old per-monitor placement silently did nothing (git history
has it if an X11 session ever needs it back). The windows open wherever GNOME
puts them.

Claude Desktop still lands on the second workspace, through GNOME's
**Auto Move Windows** extension (`gnome-shell-extension-auto-move-windows`
in `packages.txt`) rather than the script:

```bash
gnome-extensions enable auto-move-windows@gnome-shell-extensions.gcampax.github.com
gsettings set org.gnome.shell.extensions.auto-move-windows application-list "['com.anthropic.Claude.desktop:2']"
```

That rule applies whenever Claude opens a window, not just at login. It
relies on dynamic workspaces (`org.gnome.mutter dynamic-workspaces true`, so a
second workspace exists) and `workspaces-only-on-primary false` (so it spans
all three monitors), both current on this machine.


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
| `.bashrc.bak` | Pre-dotfiles-repo backup of `.bashrc` |

## Re-running

The script is idempotent. Each section checks for existing state (installed packages, existing symlinks, cloned repos, created DB users) before acting. Re-running skips what's already done.
