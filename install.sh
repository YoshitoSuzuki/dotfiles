#!/bin/sh
# このリポジトリの設定を、このマシン（macOS / Linux）にそのまま入れる。
#
#   ./install.sh                全部（下の順に実行）。Linux では bash だけ
#   ./install.sh --no-brew      全部。ただしアプリは Homebrew を使わずに入れる（brew の代わりに tools）
#   ./install.sh nvim ghostty   一部だけ
#
#   brew      Homebrew と Brewfile のアプリ（Homebrew が無ければ入れる）
#   tools     Homebrew を使わずにアプリを公式の配布物から入れる。管理者権限は要らない
#             （コマンドは ~/.local/bin、アプリは ~/Applications、フォントは ~/Library/Fonts。
#             Linux ではフォントは ~/.local/share/fonts、Ghostty / WezTerm / Zed は入れない）
#   zsh       ~/.zshrc（ZDOTDIR があればその下）
#   bash      ~/.bashrc / ~/.bash_profile
#   ghostty   ~/.config/ghostty
#   herdr     ~/.config/herdr/config.toml
#   nvim      ~/.config/nvim
#   wezterm   ~/.config/wezterm
#   zed       ~/.config/zed/settings.json / keymap.json と zed コマンド
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

case $(uname -s) in
  Darwin) OS=macos ;;
  *) OS=linux ;;
esac

case $(uname -m) in
  arm64 | aarch64) ARCH_GNU=aarch64 ARCH_GO=arm64 ARCH_NODE=arm64 ;;
  *) ARCH_GNU=x86_64 ARCH_GO=x86_64 ARCH_NODE=x64 ;;
esac

# 各リリースのファイル名に入る OS 名
if [ $OS = macos ]; then
  TRIPLE=$ARCH_GNU-apple-darwin NVIM_OS=macos-$ARCH_GO LAZYGIT_OS=darwin_$ARCH_GO NODE_OS=darwin-$ARCH_NODE
  FONT_DIR=$HOME/Library/Fonts
else
  TRIPLE=$ARCH_GNU-unknown-linux-musl NVIM_OS=linux-$ARCH_GO LAZYGIT_OS=linux_$ARCH_GNU NODE_OS=linux-$ARCH_NODE
  [ $ARCH_GNU = aarch64 ] && LAZYGIT_OS=linux_arm64
  FONT_DIR=$HOME/.local/share/fonts
fi

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

unzip_() {  # unzip_ <zip> <展開先>
  if [ $OS = macos ]; then
    ditto -x -k "$1" "$2"
  else
    unzip -q -o "$1" -d "$2"
  fi
}

install_tools() {
  PATH="$LOCAL_BIN:$PATH"

  # Linux のターミナルアプリはディストリビューションのパッケージで入れる（README）。
  # サーバーでは不要なので、ここでは入れない
  if [ $OS = macos ]; then
    head_ "アプリ（Homebrew を使わない）"
    install_app Ghostty "$(curl -fsSL https://ghostty.org/download |
      grep -oE 'https://release.files.ghostty.org/[0-9.]+/Ghostty.dmg' | head -1)"
    install_app WezTerm "$(gh_asset wezterm/wezterm 'WezTerm-macos-[^"]*\.zip')"
    install_app Zed "https://zed.dev/api/releases/stable/latest/Zed-$ARCH_GNU.dmg"
  fi

  head_ "コマンド（~/.local/bin）"
  if have herdr; then
    echo "  - herdr（導入済み: $(command -v herdr)）"
  else
    curl -fsSL https://herdr.dev/install.sh | sh >/dev/null && echo "  ✓ herdr"
  fi
  install_tar nvim "https://github.com/neovim/neovim/releases/latest/download/nvim-$NVIM_OS.tar.gz" '*/bin/nvim'
  install_tar rg "$(gh_asset BurntSushi/ripgrep "$TRIPLE\.tar\.gz")" '*/rg'
  install_tar fd "$(gh_asset sharkdp/fd "$TRIPLE\.tar\.gz")" '*/fd'
  install_tar lazygit "$(gh_asset jesseduffield/lazygit "${LAZYGIT_OS}\.tar\.gz")" lazygit
  # Node.js は LTS の最新版
  node_version=$(curl -fsSL https://nodejs.org/dist/index.json 2>/dev/null | grep -o '"version":"[^"]*"[^}]*"lts":"' |
    head -1 | sed 's/"version":"\([^"]*\)".*/\1/')
  install_tar node "https://nodejs.org/dist/$node_version/node-$node_version-$NODE_OS.tar.gz" \
    '*/bin/node' '*/bin/npm' '*/bin/npx'

  head_ "フォント（$FONT_DIR）"
  if ls "$FONT_DIR"/JetBrainsMonoNerdFont-* >/dev/null 2>&1; then
    echo "  - JetBrainsMono Nerd Font（導入済み）"
  else
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/font.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip_ "$tmp/font.zip" "$tmp/font"
    mkdir -p "$FONT_DIR"
    cp "$tmp/font"/*.ttf "$FONT_DIR/"
    rm -rf "$tmp"
    have fc-cache && fc-cache -f "$FONT_DIR" >/dev/null
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

ALL="brew zsh bash ghostty herdr nvim wezterm zed terminfo"
# Linux（ssh で入るサーバー）ではシェルの設定だけを入れる。
# Neovim などの見た目はターミナルや screen の色の扱いに左右されるので、macOS だけで使う
if [ $# = 0 ] && [ $OS = linux ]; then
  targets=bash
elif [ "${1:-}" = --no-brew ]; then
  targets=$(echo "$ALL" | sed 's/^brew/tools/')
else
  targets=${*:-$ALL}
fi
for t in $targets; do
  case $t in
    brew)
      head_ "Homebrew と Brewfile のアプリ"
      if ! command -v brew >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/brew ] &&
        [ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      for b in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        if [ -x "$b" ]; then eval "$("$b" shellenv)"; fi
      done
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
    zed)
      # settings.json と keymap.json だけ置く（同じ場所に Zed の実行時ファイルができるため）
      head_ "zed"
      link config/zed/settings.json "$CONFIG_HOME/zed/settings.json"
      link config/zed/keymap.json "$CONFIG_HOME/zed/keymap.json"
      for app in /Applications/Zed.app "$HOME/Applications/Zed.app"; do
        if [ -x "$app/Contents/MacOS/cli" ]; then
          mkdir -p "$LOCAL_BIN"
          ln -sfn "$app/Contents/MacOS/cli" "$LOCAL_BIN/zed"
          echo "  ✓ $LOCAL_BIN/zed -> $app/Contents/MacOS/cli"
          break
        fi
      done
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
