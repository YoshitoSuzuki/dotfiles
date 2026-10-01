#!/bin/sh
# このリポジトリの rc ファイルをホームディレクトリにシンボリックリンクで置く。
#
#   ./install.sh          zsh と bash の両方
#   ./install.sh zsh      zsh だけ
#   ./install.sh bash     bash だけ
#
# 既にファイルがあれば <名前>.backup.<日時> に退避してから置き換える。
# 何度実行しても同じ結果になる。
set -eu

DOTFILES_DIR=$(cd "$(dirname "$0")" && pwd)
STAMP=$(date +%Y%m%d%H%M%S)

link() {  # link <リポジトリ内のファイル> <置き場所>
  src="$DOTFILES_DIR/$1" dest=$2
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "  - $dest（設定済み）"
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

targets=${*:-zsh bash}
for t in $targets; do
  case $t in
    zsh)
      link .zshrc "${ZDOTDIR:-$HOME}/.zshrc"
      ;;
    bash)
      link .bashrc "$HOME/.bashrc"
      link .bash_profile "$HOME/.bash_profile"
      ;;
    *)
      echo "不明な指定: $t（zsh か bash）" >&2
      exit 1
      ;;
  esac
done

LOCAL_SHELL_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/shell
if [ ! -f "$LOCAL_SHELL_DIR/local.sh" ]; then
  mkdir -p "$LOCAL_SHELL_DIR"
  cp "$DOTFILES_DIR/local.sh.example" "$LOCAL_SHELL_DIR/local.sh"
  echo "  ✓ $LOCAL_SHELL_DIR/local.sh を作成（自分用の設定はここに書く）"
fi

echo "完了。新しいターミナルを開くか exec \$SHELL で反映される"
