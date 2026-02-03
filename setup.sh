#!/bin/bash
set -euo pipefail

# Bootstrap a fresh Ubuntu machine by symlinking dotfiles and installing basics.
# Idempotent — safe to re-run.

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ----------------------------------------------------------------
# 1. Install prerequisites via apt
# ----------------------------------------------------------------
echo "==> Installing apt prerequisites..."
sudo apt update -qq
sudo apt install -y -qq git jq curl

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
# 3. Create target directories
# ----------------------------------------------------------------
mkdir -p "$HOME/.claude"
mkdir -p "$HOME/.config/Code/User"

# ----------------------------------------------------------------
# 4. Symlink dotfiles
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
# 5. Install VSCode extensions (if code is available)
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
# 6. Summary
# ----------------------------------------------------------------
echo ""
echo "Done! Linked files:"
echo "  ~/.bashrc"
echo "  ~/.psqlrc"
echo "  ~/.claude/settings.json"
echo "  ~/.claude/CLAUDE.md"
echo "  ~/.claude/statusline-command.sh"
echo "  ~/.config/Code/User/settings.json"
echo "  ~/.config/Code/User/keybindings.json"
echo ""
echo "Next steps:"
echo "  - Run 'source ~/.bashrc' to reload shell config"
echo "  - Install Claude Code separately if needed"
