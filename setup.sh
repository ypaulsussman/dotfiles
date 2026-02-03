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
sudo apt install -y -qq git jq curl software-properties-common gpg

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
  sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
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

# ----------------------------------------------------------------
# 6. Create target directories
# ----------------------------------------------------------------
mkdir -p "$HOME/.claude"
mkdir -p "$HOME/.config/Code/User"

# ----------------------------------------------------------------
# 7. Symlink dotfiles
# ----------------------------------------------------------------
link() {
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
    echo "   [ok]  $dest (already linked)"
  else
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
# 8. Install VSCode extensions (if code is available)
# ----------------------------------------------------------------
EXTENSIONS_FILE="$DOTFILES_DIR/vscode/extensions.txt"
if command -v code &>/dev/null && [ -f "$EXTENSIONS_FILE" ]; then
  echo "==> Installing VSCode extensions..."
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    code --install-extension "$ext" --force 2>/dev/null || true
  done < "$EXTENSIONS_FILE"
else
  echo "==> Skipping VSCode extensions (code not found or extensions.txt missing)."
fi

# ----------------------------------------------------------------
# 9. Summary
# ----------------------------------------------------------------
echo ""
echo "Done!"
echo ""
echo "  De-snapped apps: firefox, code, vlc"
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
echo "Next steps:"
echo "  - Run 'source ~/.bashrc' to reload shell config"
echo "  - Install Claude Code separately if needed"
