#!/usr/bin/env bash
# Instalacja Alacritty, tmux i konfiguracji na nowym systemie (Debian/Ubuntu/Mint).
# Konfiguracja: katalog linux/ odwzorowuje $HOME (patrz linux/README.md).
#
# Użycie:
#   git clone git@github.com:kanaboid/konfiguracje.git && cd konfiguracje && ./install.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$REPO_DIR/linux"
ALACRITTY_VERSION="${ALACRITTY_VERSION:-0.14.0}"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!>\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31mERR:\033[0m %s\n' "$*" >&2; exit 1; }

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		die "Brak polecenia: $1"
	fi
}

install_apt_packages() {
	info "Instalacja pakietów systemowych..."
	sudo apt update
	sudo apt install -y \
		git curl build-essential \
		cmake pkg-config \
		libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev \
		python3 \
		tmux \
		xclip \
		fonts-jetbrains-mono
}

install_rust() {
	if command -v cargo >/dev/null 2>&1; then
		info "Rust/Cargo już zainstalowane: $(rustc --version)"
		return
	fi

	info "Instalacja Rust (rustup)..."
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
	# shellcheck disable=SC1091
	source "$HOME/.cargo/env"
}

install_alacritty() {
	if command -v alacritty >/dev/null 2>&1; then
		local current_version
		current_version="$(alacritty --version | awk '{print $2}')"
		info "Alacritty już zainstalowany (wersja $current_version)."
		return
	fi

	info "Instalacja Alacritty ${ALACRITTY_VERSION} przez cargo..."
	require_command cargo
	cargo install alacritty --version "$ALACRITTY_VERSION" --locked

	if [[ ! -d /tmp/alacritty-upstream ]]; then
		git clone --depth 1 --branch "v${ALACRITTY_VERSION}" \
			https://github.com/alacritty/alacritty.git /tmp/alacritty-upstream
	fi
	sudo tic -xe alacritty,alacritty-direct /tmp/alacritty-upstream/extra/alacritty.info

	install_desktop_entry
}

install_desktop_entry() {
	local alacritty_bin
	alacritty_bin="$(command -v alacritty)"

	mkdir -p "$HOME/.local/share/applications"

	cat >"$HOME/.local/share/applications/alacritty.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Alacritty
Comment=Terminal emulator
Exec=${alacritty_bin}
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
EOF

	update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
	info "Utworzono skrót: ~/.local/share/applications/alacritty.desktop"
}

install_tpm() {
	local tpm_dir="$HOME/.tmux/plugins/tpm"

	if [[ -d "$tpm_dir/.git" ]]; then
		info "TPM (tmux plugin manager) już zainstalowany."
		return
	fi

	info "Instalacja TPM dla tmux..."
	mkdir -p "$HOME/.tmux/plugins"
	git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
}

# Podpina pliki z linux/ do $HOME (linux/ = poziom katalogu domowego).
link_dotfiles() {
	[[ -d "$DOTFILES_DIR" ]] || die "Brak katalogu $DOTFILES_DIR"

	info "Podpinanie konfiguracji z $DOTFILES_DIR do \$HOME..."

	while IFS= read -r -d '' file; do
		local rel="${file#"$DOTFILES_DIR"/}"
		local target="$HOME/$rel"

		mkdir -p "$(dirname "$target")"
		ln -sf "$file" "$target"
		info "  ~/$rel"
	done < <(
		find "$DOTFILES_DIR" -mindepth 1 -type f \
			! -path '*/.git/*' \
			-print0
	)
}

install_tmux_plugins() {
	local tpm_install="$HOME/.tmux/plugins/tpm/bin/install_plugins"

	if [[ ! -x "$tpm_install" ]]; then
		warn "Brak skryptu TPM — pominięto instalację pluginów tmux."
		return
	fi

	if tmux list-sessions >/dev/null 2>&1; then
		warn "Aktywna sesja tmux — pominięto auto-instalację pluginów."
		warn "W tmux: Prefix + I  (domyślnie Ctrl+b, potem I)"
		return
	fi

	info "Instalacja pluginów tmux..."
	"$tpm_install"
}

setup_shell_path() {
	local cargo_bin="$HOME/.cargo/bin"
	local bashrc="$HOME/.bashrc"

	if [[ ":$PATH:" != *":$cargo_bin:"* ]]; then
		info "Dodaję ~/.cargo/bin do PATH w ~/.bashrc"
		cat >>"$bashrc" <<'EOF'

# Rust/Cargo (Alacritty)
export PATH="$HOME/.cargo/bin:$PATH"
EOF
	fi
}

setup_git_ssh() {
	if git config --global --get url."git@github.com:".insteadOf >/dev/null 2>&1; then
		return
	fi

	info "Ustawiam git: HTTPS GitHub -> SSH"
	git config --global url."git@github.com:".insteadOf "https://github.com/"
}

main() {
	info "Repo: $REPO_DIR"
	info "Dotfiles: $DOTFILES_DIR -> \$HOME"

	install_apt_packages
	install_rust
	# shellcheck disable=SC1091
	[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

	install_alacritty
	install_tpm
	link_dotfiles
	install_tmux_plugins
	setup_shell_path
	setup_git_ssh

	echo
	info "Gotowe."
	echo "  1. source ~/.bashrc   (lub nowy terminal)"
	echo "  2. alacritty"
	echo "  3. W tmux: Ctrl+b, I  (pluginy, jeśli nie zainstalowały się same)"
}

main "$@"
