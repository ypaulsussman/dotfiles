#!/bin/bash
set -euo pipefail

# Bootstrap a fresh Ubuntu machine by symlinking dotfiles and installing basics.
# Idempotent — safe to re-run.

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ----------------------------------------------------------------
# 1. Install bootstrap prerequisites via apt
# ----------------------------------------------------------------
echo "==> Installing bootstrap prerequisites..."
sudo apt update -qq
sudo apt install -y -qq jq curl software-properties-common gpg \
  build-essential autoconf m4 libncurses-dev libssl-dev  # Erlang/OTP build deps

# Guard: gh (GitHub CLI) is required by steps 8 and 11
if ! command -v gh &>/dev/null; then
  echo "ERROR: 'gh' (GitHub CLI) is required but not installed."
  echo "       Install it with: sudo apt install -y gh"
  exit 1
fi

# ----------------------------------------------------------------
# 2. Install mise (if not already present)
# ----------------------------------------------------------------
if ! command -v mise &>/dev/null && [ ! -x "$HOME/.local/bin/mise" ]; then
  echo "==> Installing mise..."
  curl -fsSL https://mise.jdx.dev/install.sh | bash
else
  echo "==> mise already installed, skipping."
fi

# ----------------------------------------------------------------
# 3. Add apt repos for de-snapped apps
# ----------------------------------------------------------------

# Firefox — Mozilla PPA + apt pin to prevent Ubuntu snap redirect
echo "==> Setting up Firefox (Mozilla PPA)..."
if ! grep -rq "mozillateam" /etc/apt/sources.list.d/ 2>/dev/null; then
  sudo add-apt-repository -y ppa:mozillateam/ppa
fi
sudo tee /etc/apt/preferences.d/mozilla-firefox >/dev/null <<'EOF'
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: firefox*
Pin: release o=Ubuntu
Pin-Priority: -1
EOF

# VS Code — Microsoft signed repo
echo "==> Setting up VS Code (Microsoft repo)..."
sudo mkdir -p /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/packages.microsoft.gpg ]; then
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | sudo tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null
fi
if [ ! -f /etc/apt/sources.list.d/vscode.sources ]; then
  sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/packages.microsoft.gpg
EOF
fi

# ----------------------------------------------------------------
# 4. Remove snap versions of Firefox, Code, VLC (if installed)
# ----------------------------------------------------------------
echo "==> Removing snap versions of Firefox, Code, VLC (if present)..."
for pkg in firefox code vlc; do
  if snap list "$pkg" &>/dev/null; then
    echo "   Removing snap: $pkg"
    sudo snap remove --purge "$pkg"
  else
    echo "   [ok]  $pkg snap not installed"
  fi
done

# ----------------------------------------------------------------
# 5. Install apt packages (refresh after repo setup)
# ----------------------------------------------------------------
echo "==> Updating apt and installing packages..."
sudo apt update -qq
sudo apt install -y firefox code vlc

PACKAGES_FILE="$DOTFILES_DIR/packages.txt"
if [ -f "$PACKAGES_FILE" ]; then
  mapfile -t pkgs < <(grep -v '^#' "$PACKAGES_FILE" | grep -v '^$')
  if [ ${#pkgs[@]} -gt 0 ]; then
    echo "==> Installing ${#pkgs[@]} packages from packages.txt..."
    sudo apt install -y "${pkgs[@]}"
  fi
fi

# ----------------------------------------------------------------
# 6. Install Anki
# ----------------------------------------------------------------
if command -v anki &>/dev/null; then
  echo "==> Anki already installed, skipping."
else
  echo "==> Installing Anki (latest release from GitHub)..."
  ANKI_RELEASE_URL=$(curl -fsSL https://api.github.com/repos/ankitects/anki/releases \
    | jq -r '[.[] | select(.assets | length > 0)][0].assets[] | select(.name | test("linux.*\\.tar\\.zst$")) | .browser_download_url')
  if [ -n "$ANKI_RELEASE_URL" ]; then
    ANKI_TMP=$(mktemp -d)
    curl -fsSL -o "$ANKI_TMP/anki.tar.zst" "$ANKI_RELEASE_URL"
    tar --zstd -xf "$ANKI_TMP/anki.tar.zst" -C "$ANKI_TMP"
    ANKI_INSTALL_DIR=$(find "$ANKI_TMP" -maxdepth 1 -type d -name 'anki-*' | head -1)
    if [ -d "$ANKI_INSTALL_DIR" ] && [ -f "$ANKI_INSTALL_DIR/install.sh" ]; then
      sudo bash "$ANKI_INSTALL_DIR/install.sh"
      echo "   [ok]  Anki installed"
    else
      echo "   [WARN] Could not find install.sh in Anki archive — install manually"
    fi
    rm -rf "$ANKI_TMP"
  else
    echo "   [WARN] Could not determine Anki download URL — install manually"
  fi
fi

# ----------------------------------------------------------------
# 7. Install Talon
# ----------------------------------------------------------------
if [ -f "$HOME/talon/run.sh" ]; then
  echo "==> Talon already installed, skipping."
else
  echo "==> Installing Talon..."
  TALON_TMP=$(mktemp -d)
  HTTP_STATUS=$(curl -fsSL -o "$TALON_TMP/talon.tar.xz" -w "%{http_code}" \
    "https://talonvoice.com/dl/latest/talon-linux.tar.xz" 2>/dev/null) || true
  if [ -f "$TALON_TMP/talon.tar.xz" ] && [ "$HTTP_STATUS" = "200" ]; then
    tar -xJf "$TALON_TMP/talon.tar.xz" -C "$HOME"
    echo "   [ok]  Talon extracted to ~/talon/"
  else
    echo "   [WARN] Talon download failed (HTTP $HTTP_STATUS)."
    echo "          Talon may require beta access. Install manually:"
    echo "          https://talonvoice.com/"
  fi
  rm -rf "$TALON_TMP"
fi

# ----------------------------------------------------------------
# 8. GitHub authentication
# ----------------------------------------------------------------
echo "==> Authenticating with GitHub..."
if gh auth status &>/dev/null; then
  echo "   [ok]  Already authenticated with GitHub"
else
  gh auth login --web --git-protocol https
fi

# ----------------------------------------------------------------
# 9. Firefox Sync reminder
# ----------------------------------------------------------------
echo ""
echo "==> ACTION REQUIRED: Sign into Firefox Sync"
echo "   Open Firefox and sign in to sync your bookmarks, passwords, and settings."
echo "   (Your saved passwords will be needed for VS Code GitHub sign-in, etc.)"
read -rp "   Press Enter once Firefox Sync is complete (or 's' to skip)... " response
if [[ "$response" != "s" ]]; then
  echo "   [ok]  Firefox Sync acknowledged"
else
  echo "   [skip] Firefox Sync skipped"
fi

# ----------------------------------------------------------------
# 10. Install PostgreSQL and create wtp DB user
# ----------------------------------------------------------------
echo "==> Setting up PostgreSQL..."
sudo apt install -y -qq postgresql
if sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname = 'y'" | grep -q 1; then
  echo "   [ok]  PostgreSQL user 'y' already exists"
else
  sudo -u postgres psql -c "CREATE USER y WITH SUPERUSER PASSWORD 'ys_password'"
  echo "   [ok]  Created PostgreSQL user 'y'"
fi

# ----------------------------------------------------------------
# 11. Clone private repos
# ----------------------------------------------------------------
echo "==> Cloning private repos..."
for repo in rss-reader wtp yr_workspace; do
  if [ -d "$HOME/Desktop/$repo" ]; then
    echo "   [ok]  ~/Desktop/$repo already exists"
  else
    gh repo clone "ypaulsussman/$repo" "$HOME/Desktop/$repo"
    echo "   [ok]  Cloned $repo"
  fi
done

# ----------------------------------------------------------------
# 12. Install runtimes via mise and set up projects
# ----------------------------------------------------------------
echo "==> Installing runtimes via mise..."
MISE="$HOME/.local/bin/mise"

# bun (for rss-reader — installed globally since repo has no .tool-versions)
"$MISE" use --global bun@latest
# erlang + elixir (for wtp — reads .tool-versions in repo)
(cd "$HOME/Desktop/wtp" && "$MISE" install)

echo "==> Setting up rss-reader..."
(cd "$HOME/Desktop/rss-reader" && "$MISE" exec -- bun install)

echo "==> Setting up wtp..."
(cd "$HOME/Desktop/wtp" && "$MISE" exec -- mix local.hex --force && "$MISE" exec -- mix local.rebar --force && "$MISE" exec -- mix setup)

# ----------------------------------------------------------------
# 13. Create target directories
# ----------------------------------------------------------------
mkdir -p "$HOME/.claude"
mkdir -p "$HOME/.config/Code/User"

# ----------------------------------------------------------------
# 14. Symlink dotfiles
# ----------------------------------------------------------------
link() {
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
    echo "   [ok]  $dest (already linked)"
  else
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
      mv "$dest" "$dest.bak"
      echo "   [bak] $dest -> $dest.bak"
    fi
    ln -sf "$src" "$dest"
    echo "   [ln]  $dest -> $src"
  fi
}

echo "==> Linking dotfiles..."

link "$DOTFILES_DIR/.bashrc"                       "$HOME/.bashrc"
link "$DOTFILES_DIR/.psqlrc"                       "$HOME/.psqlrc"
link "$DOTFILES_DIR/.claude/settings.json"         "$HOME/.claude/settings.json"
link "$DOTFILES_DIR/.claude/CLAUDE.md"             "$HOME/.claude/CLAUDE.md"
link "$DOTFILES_DIR/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
link "$DOTFILES_DIR/vscode/settings.json"          "$HOME/.config/Code/User/settings.json"
link "$DOTFILES_DIR/vscode/keybindings.json"       "$HOME/.config/Code/User/keybindings.json"

# Make statusline script executable
chmod +x "$DOTFILES_DIR/.claude/statusline-command.sh"

# ----------------------------------------------------------------
# 15. Install VSCode extensions (if code is available)
# ----------------------------------------------------------------
EXTENSIONS_FILE="$DOTFILES_DIR/vscode/extensions.txt"
if command -v code &>/dev/null && [ -f "$EXTENSIONS_FILE" ]; then
  echo "==> Installing VSCode extensions..."
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    [[ "$ext" != *.* ]] && continue  # skip comments and non-extension lines
    code --install-extension "$ext" --force 2>/dev/null || true
  done < "$EXTENSIONS_FILE"
else
  echo "==> Skipping VSCode extensions (code not found or extensions.txt missing)."
fi

# ----------------------------------------------------------------
# 16. Summary
# ----------------------------------------------------------------
echo ""
echo "Done!"
echo ""
echo "  De-snapped apps: firefox, code, vlc"
PACKAGES_FILE="$DOTFILES_DIR/packages.txt"
if [ -f "$PACKAGES_FILE" ]; then
  PKG_COUNT=$(grep -v '^#' "$PACKAGES_FILE" | grep -cv '^$' || true)
  echo "  Extra apt pkgs:  $PKG_COUNT (from packages.txt)"
fi
echo "  Desktop apps:    anki, talon"
echo "  Cloned repos:    ~/Desktop/rss-reader, ~/Desktop/wtp, ~/Desktop/yr_workspace"
echo ""
echo "  Linked files:"
echo "    ~/.bashrc"
echo "    ~/.psqlrc"
echo "    ~/.claude/settings.json"
echo "    ~/.claude/CLAUDE.md"
echo "    ~/.claude/statusline-command.sh"
echo "    ~/.config/Code/User/settings.json"
echo "    ~/.config/Code/User/keybindings.json"
echo ""
echo "Manual next steps:"
echo "  - Run 'source ~/.bashrc' to reload shell config"
echo "  - Open VS Code and sign into GitHub (for Settings Sync, extensions, etc.)"
echo "  - Sign into Anki (for syncing decks across devices)"
echo "  - Install Claude Code separately if needed"
