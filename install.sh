#!/bin/sh
# このリポジトリの設定を、このMacにそのまま入れる。
#
#   ./install.sh                全部（下の順に実行）
#   ./install.sh nvim ghostty   一部だけ
#
#   brew      Homebrew と Brewfile のアプリ（Homebrew が無ければ入れる）
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

targets=${*:-brew zsh bash ghostty herdr nvim wezterm terminfo}
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
