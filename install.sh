#!/bin/sh
# このリポジトリの設定を、このMacにそのまま入れる。
#
#   ./install.sh                全部（下の順に実行）
#   ./install.sh --no-brew      全部。ただしアプリは Homebrew を使わずに入れる（brew の代わりに tools）
#   ./install.sh nvim ghostty   一部だけ
#
#   brew      Homebrew と Brewfile のアプリ（Homebrew が無ければ入れる）
#   tools     Homebrew を使わずにアプリを公式の配布物から入れる。管理者権限は要らない
#             （コマンドは ~/.local/bin、アプリは ~/Applications、フォントは ~/Library/Fonts）
#   zsh       ~/.zshrc（ZDOTDIR があればその下）
#   bash      ~/.bashrc / ~/.bash_profile
#   ghostty   ~/.config/ghostty
#   herdr     ~/.config/herdr/config.toml
#   nvim      ~/.config/nvim
#   wezterm   ~/.config/wezterm
#   terminfo  herdr の中の Neovim で取り消し線・波線を出すための terminfo を登録
#
# 設定はシンボリックリンクで置く。既にファイルがあれば <名前>.backup.<日時> に退避する。
# 何度実行しても同じ結果になる。
set -eu

DOTFILES_DIR=$(cd "$(dirname "$0")" && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
STAMP=$(date +%Y%m%d%H%M%S)

head_() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

# ---- tools（Homebrew を使わない導入）----

LOCAL_BIN=$HOME/.local/bin
LOCAL_OPT=$HOME/.local/opt

case $(uname -m) in
  arm64) ARCH_GNU=aarch64 ARCH_GO=arm64 ARCH_NODE=arm64 ;;
  *) ARCH_GNU=x86_64 ARCH_GO=x86_64 ARCH_NODE=x64 ;;
esac

have() { command -v "$1" >/dev/null 2>&1; }

gh_asset() {  # gh_asset <owner/repo> <ファイル名の末尾の正規表現> → 最新リリースの URL
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
    grep -o "\"browser_download_url\": *\"[^\"]*$2\"" | head -1 | sed 's/.*"\(http[^"]*\)"$/\1/'
}

install_tar() {  # install_tar <コマンド名> <URL> <展開先から見たコマンドのパス...>
  name=$1 url=$2
  shift 2
  if have "$name"; then
    echo "  - ${name}（導入済み: $(command -v "$name")）"
    return
  fi
  rm -rf "${LOCAL_OPT:?}/$name"
  mkdir -p "$LOCAL_OPT/$name" "$LOCAL_BIN"
  curl -fsSL "$url" | tar xz -C "$LOCAL_OPT/$name"
  for pattern in "$@"; do
    for path in "$LOCAL_OPT/$name"/$pattern; do
      ln -sfn "$path" "$LOCAL_BIN/$(basename "$path")"
    done
  done
  echo "  ✓ $name"
}

install_app() {  # install_app <アプリ名> <URL（.dmg か .zip）>
  if [ -d "/Applications/$1.app" ] || [ -d "$HOME/Applications/$1.app" ]; then
    echo "  - $1.app（導入済み）"
    return
  fi
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/download" "$2"
  mkdir -p "$HOME/Applications"
  case $2 in
    *.dmg)
      hdiutil attach -nobrowse -quiet -mountpoint "$tmp/mnt" "$tmp/download"
      cp -R "$tmp/mnt/$1.app" "$HOME/Applications/"
      hdiutil detach -quiet "$tmp/mnt"
      ;;
    *.zip)
      ditto -x -k "$tmp/download" "$tmp/x"
      cp -R "$(find "$tmp/x" -maxdepth 2 -name "$1.app" | head -1)" "$HOME/Applications/"
      ;;
  esac
  rm -rf "$tmp"
  echo "  ✓ ~/Applications/$1.app"
}

install_tools() {
  PATH="$LOCAL_BIN:$PATH"

  head_ "アプリ（Homebrew を使わない）"
  install_app Ghostty "$(curl -fsSL https://ghostty.org/download |
    grep -oE 'https://release.files.ghostty.org/[0-9.]+/Ghostty.dmg' | head -1)"
  install_app WezTerm "$(gh_asset wezterm/wezterm 'WezTerm-macos-[^"]*\.zip')"

  head_ "コマンド（~/.local/bin）"
  if have herdr; then
    echo "  - herdr（導入済み: $(command -v herdr)）"
  else
    curl -fsSL https://herdr.dev/install.sh | sh >/dev/null && echo "  ✓ herdr"
  fi
  install_tar nvim "https://github.com/neovim/neovim/releases/latest/download/nvim-macos-$ARCH_GO.tar.gz" '*/bin/nvim'
  install_tar rg "$(gh_asset BurntSushi/ripgrep "$ARCH_GNU-apple-darwin\.tar\.gz")" '*/rg'
  install_tar fd "$(gh_asset sharkdp/fd "$ARCH_GNU-apple-darwin\.tar\.gz")" '*/fd'
  install_tar lazygit "$(gh_asset jesseduffield/lazygit "darwin_$ARCH_GO\.tar\.gz")" lazygit
  # Node.js は LTS の最新版
  node_version=$(curl -fsSL https://nodejs.org/dist/index.json 2>/dev/null | grep -o '"version":"[^"]*"[^}]*"lts":"' |
    head -1 | sed 's/"version":"\([^"]*\)".*/\1/')
  install_tar node "https://nodejs.org/dist/$node_version/node-$node_version-darwin-$ARCH_NODE.tar.gz" \
    '*/bin/node' '*/bin/npm' '*/bin/npx'

  head_ "フォント（~/Library/Fonts）"
  if ls "$HOME/Library/Fonts"/JetBrainsMonoNerdFont-* >/dev/null 2>&1; then
    echo "  - JetBrainsMono Nerd Font（導入済み）"
  else
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/font.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    ditto -x -k "$tmp/font.zip" "$tmp/font"
    mkdir -p "$HOME/Library/Fonts"
    cp "$tmp/font"/*.ttf "$HOME/Library/Fonts/"
    rm -rf "$tmp"
    echo "  ✓ JetBrainsMono Nerd Font"
  fi
}

# ---- 設定ファイル ----

link() {  # link <リポジトリ内のパス> <置き場所>
  src="$DOTFILES_DIR/$1" dest=$2
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "  - ${dest}（設定済み）"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.backup.$STAMP"
    echo "  ! 既存の $dest を $dest.backup.$STAMP に退避"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "  ✓ $dest -> $src"
}

ALL="brew zsh bash ghostty herdr nvim wezterm terminfo"
if [ "${1:-}" = --no-brew ]; then
  targets=$(echo "$ALL" | sed 's/^brew/tools/')
else
  targets=${*:-$ALL}
fi
for t in $targets; do
  case $t in
    brew)
      head_ "Homebrew と Brewfile のアプリ"
      if ! command -v brew >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/brew ]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
      brew bundle --file="$DOTFILES_DIR/Brewfile"
      ;;
    tools)
      install_tools
      ;;
    zsh)
      head_ "zsh"
      zshrc=${ZDOTDIR:-$HOME}/.zshrc
      # 自分の .zshrc からこのリポジトリの .zshrc を読み込んでいる場合は置き換えない
      if [ -f "$zshrc" ] && [ ! -L "$zshrc" ] && grep -q 'dotfiles/\.zshrc' "$zshrc"; then
        echo "  - ${zshrc}（dotfiles を読み込み済み）"
      else
        link .zshrc "$zshrc"
      fi
      ;;
    bash)
      head_ "bash"
      link .bashrc "$HOME/.bashrc"
      link .bash_profile "$HOME/.bash_profile"
      ;;
    ghostty | nvim | wezterm)
      head_ "$t"
      link "config/$t" "$CONFIG_HOME/$t"
      ;;
    herdr)
      # ディレクトリごとではなく config.toml だけ置く（同じ場所に herdr の実行時ファイルができるため）
      head_ "herdr"
      link config/herdr/config.toml "$CONFIG_HOME/herdr/config.toml"
      ;;
    terminfo)
      head_ "terminfo"
      tic -x -o "$HOME/.terminfo" "$DOTFILES_DIR/config/terminfo/herdr.terminfo"
      echo "  ✓ xterm-256color-herdr を登録"
      ;;
    *)
      echo "不明な指定: $t" >&2
      exit 1
      ;;
  esac
done

if [ ! -f "$CONFIG_HOME/shell/local.sh" ]; then
  mkdir -p "$CONFIG_HOME/shell"
  cp "$DOTFILES_DIR/local.sh.example" "$CONFIG_HOME/shell/local.sh"
  echo
  echo "  ✓ $CONFIG_HOME/shell/local.sh を作成（自分用の設定はここに書く）"
fi

echo
echo "完了。README の「入れたあとにやること」に進む"
