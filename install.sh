#!/bin/sh
# このリポジトリの設定と自作コマンドを、このマシン（macOS / Linux）にまとめて入れる。
# 詳しい説明は README の「入れ方」「オプション」「モジュール」。
#
#   ./install.sh                  public（誰が使ってもよい設定だけ）。OS と GUI の有無に合わせて選ぶ
#   ./install.sh --private        個人用。public に private リポジトリ（DOTFILES_PRIVATE_REPO）を重ねる
#   ./install.sh --work           会社用。public に、会社のPCで事故を防ぐ設定を足す
#   ./install.sh nvim ghostty     名前を並べたものだけ（既定の一覧は使わない）
#
# オプション
#   --private / --work            公開範囲（どちらも付けなければ public。同時には付けられない）
#   --with <名前,...>             既定の一覧に足す（設定・モジュールのどちらの名前でもよい）
#   --without <名前,...>          既定の一覧から除く
#   --all                         入れられるものを全部入れる（CLI の環境では herdr とアプリを除く）
#   --gui / --no-gui              GUI の有無の自動判定を上書きする
#   --no-brew                     Homebrew を使わずに入れる（brew の代わりに tools apps fonts）
#   --no-modules                  モジュール（自作コマンドなどのリポジトリ）を clone しない
#   --dry-run                     何を入れるかを表示するだけで、何も変えない
#
# 設定の名前
#   brew      Homebrew と Brewfile のアプリ（macOS）
#   tools     Neovim・ripgrep・fd・lazygit・Node.js を ~/.local に入れる（Homebrew を使わない。管理者権限は要らない）
#   apps      Ghostty・WezTerm・Zed を ~/Applications に、herdr を ~/.local/bin に入れる（Homebrew を使わない）。
#             Linux では herdr だけ入れ、ターミナルアプリはパッケージで入れるコマンドを表示する
#   fonts     JetBrains Mono Nerd Font（macOS は ~/Library/Fonts、Linux は ~/.local/share/fonts）
#   zsh       ~/.zshrc（ZDOTDIR があればその下）
#   bash      ~/.bashrc / ~/.bash_profile
#   ghostty   ~/.config/ghostty
#   herdr     ~/.config/herdr/config.toml
#   nvim      ~/.config/nvim
#   wezterm   ~/.config/wezterm
#   zed       ~/.config/zed/settings.json / keymap.json と zed コマンド
#   terminfo  herdr の中の Neovim で取り消し線・波線を出すための terminfo を登録
#   claude    Claude Code の共通ルール・フック・スキル（~/.claude。既存の設定は置き換えずに足す）
#
# モジュールの名前は modules.tsv（と private リポジトリの modules.tsv）を参照。
#
# 設定はシンボリックリンクで置く。既にファイルがあれば <名前>.backup.<日時> に退避する。
# 何度実行しても同じ結果になる。
set -eu

DOTFILES_DIR=$(cd "$(dirname "$0")" && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
STAMP=$(date +%Y%m%d%H%M%S)
PRIVATE_DIR=$HOME/dotfiles-private
PRIVATE_REPO=${DOTFILES_PRIVATE_REPO:-git@github.com:YoshitoSuzuki/dotfiles-private.git}
BIN_DIR=$HOME/bin
BIN_SRC=$HOME/bin-src

head_() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }

case $(uname -s) in
  Darwin) OS=macos ;;
  *) OS=linux ;;
esac

# ---- 引数 ----

usage() {
  sed -n '2,/^set -eu/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

SCOPE=public
GUI=auto
WITH=
WITHOUT=
ALL=0
NO_BREW=0
NO_MODULES=0
DRY_RUN=0
NAMES=

while [ $# -gt 0 ]; do
  case $1 in
    --private | --work)
      s=${1#--}
      if [ $SCOPE != public ] && [ $SCOPE != "$s" ]; then
        echo "--private と --work は同時に指定できません" >&2
        exit 1
      fi
      SCOPE=$s
      ;;
    --with)
      [ $# -ge 2 ] || usage 1
      WITH="$WITH $(echo "$2" | tr ',' ' ')"
      shift
      ;;
    --with=*) WITH="$WITH $(echo "${1#*=}" | tr ',' ' ')" ;;
    --without)
      [ $# -ge 2 ] || usage 1
      WITHOUT="$WITHOUT $(echo "$2" | tr ',' ' ')"
      shift
      ;;
    --without=*) WITHOUT="$WITHOUT $(echo "${1#*=}" | tr ',' ' ')" ;;
    --all) ALL=1 ;;
    --gui) GUI=1 ;;
    --no-gui) GUI=0 ;;
    --no-brew) NO_BREW=1 ;;
    --no-modules) NO_MODULES=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h | --help) usage ;;
    -*)
      echo "不明なオプション: $1" >&2
      exit 1
      ;;
    *) NAMES="$NAMES $1" ;;
  esac
  shift
done

# GUI の有無: macOS は常にあり。Linux はデスクトップのセッションの変数で判定する
if [ $GUI = auto ]; then
  if [ $OS = macos ] || [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}${XDG_CURRENT_DESKTOP:-}" ]; then
    GUI=1
  else
    GUI=0
  fi
fi

have() { command -v "$1" >/dev/null 2>&1; }
has_word() { case " $1 " in *" $2 "*) return 0 ;; esac; return 1; }

# ---- 入れるものを決める ----

CONFIG_NAMES="brew tools apps fonts zsh bash ghostty herdr nvim wezterm zed terminfo claude"

# モジュールの一覧（名前 種類 OS 既定 リポジトリ 置き場所 コマンド）。同じ名前は private が優先
modules_table() {
  {
    grep -v '^#' "$DOTFILES_DIR/modules.tsv" | grep . | sed 's/^/1	/'
    if [ $SCOPE = private ] && [ -f "$PRIVATE_DIR/modules.tsv" ]; then
      grep -v '^#' "$PRIVATE_DIR/modules.tsv" | grep . | sed 's/^/2	/'
    fi
  } | awk -F'\t' -v os=$OS '
    $4 != "all" && $4 != os { next }
    { if (!($2 in row) || $1 >= layer[$2]) { if (!($2 in row)) order[++n] = $2; row[$2] = $0; layer[$2] = $1 } }
    END { for (i = 1; i <= n; i++) { sub(/^[0-9]\t/, "", row[order[i]]); print row[order[i]] } }'
}

resolve() {
  if [ -n "$NAMES" ]; then
    # 名前を並べたときは、その名前のものだけ
    targets=
    for n in $NAMES; do
      if has_word "$CONFIG_NAMES" "$n"; then targets="$targets $n"; fi
    done
    return 0
  fi
  if [ $GUI = 1 ]; then
    if [ $OS = macos ] && [ $NO_BREW = 0 ]; then
      targets="brew"
    else
      targets="tools apps fonts"
    fi
    targets="$targets zsh bash ghostty herdr nvim wezterm zed terminfo"
  else
    targets="zsh bash"
    [ $ALL = 1 ] && targets="tools zsh bash nvim terminfo"
  fi
  [ $SCOPE != public ] || [ $ALL = 1 ] && targets="$targets claude"
  for n in $WITH; do
    has_word "$CONFIG_NAMES" "$n" || continue
    # nvim だけ足すときは、Neovim 本体と検索ツールも要る
    [ "$n" = nvim ] && ! has_word "$targets" brew && ! has_word "$targets" tools && targets="tools $targets"
    has_word "$targets" "$n" || targets="$targets $n"
  done
  kept=
  for t in $targets; do
    has_word "$WITHOUT" "$t" && continue
    # Linux では zsh が入っていなければ zsh の設定は置かない（--with zsh なら置く）
    [ "$t" = zsh ] && [ $OS = linux ] && ! have zsh && ! has_word "$WITH" zsh && continue
    kept="$kept $t"
  done
  targets=$kept
}

module_selected() {  # module_selected <名前> <既定(yes/opt)>
  has_word "$WITHOUT" "$1" && return 1
  if [ -n "$NAMES" ]; then
    has_word "$NAMES" "$1"
    return
  fi
  [ $NO_MODULES = 1 ] && return 1
  [ "$2" = yes ] || [ $ALL = 1 ] || has_word "$WITH" "$1"
}

expand_home() { case $1 in "~") echo "$HOME" ;; "~/"*) echo "$HOME/${1#\~/}" ;; *) echo "$1" ;; esac; }

module_dest() {  # module_dest <名前> <種類> <置き場所>
  if [ "$3" = - ]; then
    echo "$BIN_SRC/$1"
  else
    expand_home "$3"
  fi
}

for n in $WITH $WITHOUT $NAMES; do
  has_word "$CONFIG_NAMES" "$n" && continue
  grep -q "^$n	" "$DOTFILES_DIR/modules.tsv" && continue
  [ -f "$PRIVATE_DIR/modules.tsv" ] && grep -q "^$n	" "$PRIVATE_DIR/modules.tsv" && continue
  [ $SCOPE = private ] && [ ! -f "$PRIVATE_DIR/modules.tsv" ] && continue  # private の一覧はまだ clone していない
  echo "不明な名前: $n" >&2
  exit 1
done

resolve

if [ $DRY_RUN = 1 ]; then
  echo "OS:       $OS"
  echo "GUI:      $([ $GUI = 1 ] && echo あり || echo なし)"
  echo "公開範囲: $SCOPE"
  echo "設定:    $targets"
  if [ $SCOPE = private ]; then
    echo "private:  $PRIVATE_REPO -> $PRIVATE_DIR$([ -d "$PRIVATE_DIR/.git" ] || echo '（まだ無いので、モジュールは public の一覧だけを表示）')"
  fi
  echo "モジュール:"
  modules_table | while IFS='	' read -r name kind mos def repo dest cmds; do
    module_selected "$name" "$def" || continue
    printf '  %-12s %-5s %s -> %s\n' "$name" "$kind" "$repo" "$(module_dest "$name" "$kind" "$dest")"
  done
  exit 0
fi

# ---- tools / apps / fonts（Homebrew を使わない導入）----

LOCAL_BIN=$HOME/.local/bin
LOCAL_OPT=$HOME/.local/opt

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
  head_ "コマンド（~/.local/bin）"
  # Neovim はプラグインの取得に git、構文解析器のビルドに C コンパイラを使う
  if [ $OS = linux ] && { ! have git || ! have cc; }; then
    warn "git か C コンパイラが無い。Neovim のプラグインが入らないので先に入れる（Debian / Ubuntu なら sudo apt install git build-essential）"
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
}

install_apps() {
  PATH="$LOCAL_BIN:$PATH"
  head_ "アプリ（Homebrew を使わない）"
  if have herdr; then
    echo "  - herdr（導入済み: $(command -v herdr)）"
  else
    curl -fsSL https://herdr.dev/install.sh | sh >/dev/null && echo "  ✓ herdr"
  fi
  if [ $OS = macos ]; then
    install_app Ghostty "$(curl -fsSL https://ghostty.org/download |
      grep -oE 'https://release.files.ghostty.org/[0-9.]+/Ghostty.dmg' | head -1)"
    install_app WezTerm "$(gh_asset wezterm/wezterm 'WezTerm-macos-[^"]*\.zip')"
    install_app Zed "https://zed.dev/api/releases/stable/latest/Zed-$ARCH_GNU.dmg"
  else
    # Linux のターミナルアプリは、ディストリビューションのパッケージで入れる（管理者権限が要るので自動では入れない）
    for app in ghostty wezterm zed; do
      have "$app" || warn "$app が無い。ディストリビューションのパッケージか公式の手順で入れる（README の「Linux（GUI）」）"
    done
  fi
}

install_fonts() {
  head_ "フォント（${FONT_DIR}）"
  if ls "$FONT_DIR"/JetBrainsMonoNerdFont-* >/dev/null 2>&1; then
    echo "  - JetBrainsMono Nerd Font（導入済み）"
    return
  fi
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/font.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  unzip_ "$tmp/font.zip" "$tmp/font"
  mkdir -p "$FONT_DIR"
  cp "$tmp/font"/*.ttf "$FONT_DIR/"
  rm -rf "$tmp"
  have fc-cache && fc-cache -f "$FONT_DIR" >/dev/null
  echo "  ✓ JetBrainsMono Nerd Font"
}

# ---- 設定ファイル ----

link_abs() {  # link_abs <実体> <置き場所>
  src=$1 dest=$2
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

link() { link_abs "$DOTFILES_DIR/$1" "$2"; }  # link <リポジトリ内のパス> <置き場所>

install_claude() {
  claude_dir=$HOME/.claude
  link claude "$claude_dir/dotfiles"

  # CLAUDE.md は置き換えない。共通ルールの読み込み行が無いときだけ先頭に足す
  memo=$claude_dir/CLAUDE.md
  import='@~/.claude/dotfiles/CLAUDE.md'
  if [ ! -f "$memo" ]; then
    printf '%s\n\n## このマシン固有\n\n' "$import" >"$memo"
    echo "  ✓ $memo を作成（このマシンだけの指示はここに書く）"
  elif grep -qxF "$import" "$memo"; then
    echo "  - ${memo}（共通ルールを読み込み済み）"
  else
    cp "$memo" "$memo.backup.$STAMP"
    { printf '%s\n\n' "$import"; cat "$memo.backup.$STAMP"; } >"$memo"
    echo "  ✓ $memo の先頭に共通ルールの読み込みを追加（元は $memo.backup.${STAMP}）"
  fi

  # フックはリンクではなくコピーする（dotfiles が壊れていても動くように）
  mkdir -p "$claude_dir/hooks"
  for f in "$DOTFILES_DIR"/claude/hooks/*; do
    dest=$claude_dir/hooks/$(basename "$f")
    if cmp -s "$f" "$dest"; then
      echo "  - ${dest}（設定済み）"
      continue
    fi
    if [ -e "$dest" ]; then
      mv "$dest" "$dest.backup.$STAMP"
      echo "  ! 既存の $dest を $dest.backup.$STAMP に退避"
    fi
    cp "$f" "$dest"
    echo "  ✓ $dest"
  done

  # スキルは同じ名前のものが無いときだけ置く（そのマシンで手を入れたものは残す）
  for d in "$DOTFILES_DIR"/claude/skills/*/; do
    name=$(basename "$d")
    dest=$claude_dir/skills/$name
    if { [ -e "$dest" ] || [ -L "$dest" ]; } && [ "$(readlink "$dest")" != "$DOTFILES_DIR/claude/skills/$name" ]; then
      echo "  - ${dest}（既にあるので置かない）"
    else
      link "claude/skills/$name" "$dest"
    fi
  done

  if have python3; then
    python3 "$DOTFILES_DIR/claude/settings-merge.py"
  else
    warn "python3 が無いので ~/.claude/settings.json にフックを登録しない（python3 を入れてから install.sh claude）"
  fi
}

# ---- モジュール（自作コマンドなどのリポジトリ）----

same_repo() {  # same_repo <URL> <URL>  … ssh と https の違いは無視して owner/name で比べる
  a=$(echo "$1" | sed -E 's#^(git@[^:]+:|https?://[^/]+/)##; s#\.git$##')
  b=$(echo "$2" | sed -E 's#^(git@[^:]+:|https?://[^/]+/)##; s#\.git$##')
  [ "$a" = "$b" ]
}

sync_repo() {  # sync_repo <リポジトリ> <置き場所>。clone するか pull する。使えない状態なら 1 を返す
  repo=$1 dest=$2
  if [ -d "$dest/.git" ]; then
    current=$(git -C "$dest" remote get-url origin 2>/dev/null || echo)
    if ! same_repo "$current" "$repo"; then
      warn "$dest は別のリポジトリ（${current:-remote 無し}）なので触らない。入れ替えるなら手で退避してから実行し直す"
      return 1
    fi
    if git -C "$dest" pull -q --ff-only 2>/dev/null; then
      echo "  - ${dest}（pull 済み）"
    else
      warn "$dest は pull できなかった（未コミットの変更か、分岐した履歴がある）。そのまま使う"
    fi
    return 0
  fi
  if [ -e "$dest" ] && [ -n "$(ls -A "$dest" 2>/dev/null)" ]; then
    adopt_repo "$repo" "$dest"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  git clone -q "$repo" "$dest"
  echo "  ✓ $dest <- $repo"
}

# 既にファイルがある場所（Claude Code が先に作った ~/.claude など）にリポジトリを重ねる。
# リポジトリと同じ名前のファイルは .backup.<日時> に退避してから、リポジトリの内容にする
adopt_repo() {
  repo=$1 dest=$2
  tmp=$(mktemp -d)
  git clone -q --no-checkout "$repo" "$tmp/r"
  git -C "$tmp/r" ls-tree -r --name-only HEAD | while read -r f; do
    if [ -e "$dest/$f" ] || [ -L "$dest/$f" ]; then
      mv "$dest/$f" "$dest/$f.backup.$STAMP"
      echo "  ! 既存の $dest/$f を $dest/$f.backup.$STAMP に退避"
    fi
  done
  mv "$tmp/r/.git" "$dest/.git"
  rm -rf "$tmp"
  git -C "$dest" checkout -q HEAD -- .
  echo "  ✓ $dest <- ${repo}（既存のファイルの上に重ねた）"
}

EXCLUDE_BEGIN='# >>> dotfiles modules（install.sh が管理する。この範囲は手で書き換えない）'
EXCLUDE_END='# <<< dotfiles modules'

# ~/bin が Git のリポジトリなら、install.sh が張ったリンクの名前を .git/info/exclude の管理範囲に書く。
# .gitignore は公開されるので、リンクの名前はそこには書かない
write_bin_exclude() {  # write_bin_exclude <名前...>
  [ -d "$BIN_DIR/.git" ] || return 0
  exclude=$BIN_DIR/.git/info/exclude
  mkdir -p "$(dirname "$exclude")"
  touch "$exclude"
  old=$(sed -n "/^$EXCLUDE_BEGIN\$/,/^$EXCLUDE_END\$/p" "$exclude" | sed '1d;$d' | sed 's#^/##')
  {
    sed "/^$EXCLUDE_BEGIN\$/,/^$EXCLUDE_END\$/d" "$exclude"
    if [ $# -gt 0 ]; then
      echo "$EXCLUDE_BEGIN"
      for n in "$@"; do echo "/$n"; done
      echo "$EXCLUDE_END"
    fi
  } >"$exclude.tmp"
  mv "$exclude.tmp" "$exclude"
  for n in $old; do
    has_word "$*" "$n" || { [ -L "$BIN_DIR/$n" ] && warn "~/bin/$n はどのモジュールにも属さなくなった（不要なら消す）"; }
  done
  return 0
}

install_modules() {
  head_ "モジュール"
  linked=
  tab=$(printf '\t')
  list=$(mktemp)
  modules_table >"$list"
  while IFS=$tab read -r name kind mos def repo dest cmds; do
    module_selected "$name" "$def" || continue
    dest=$(module_dest "$name" "$kind" "$dest")
    sync_repo "$repo" "$dest" </dev/null || continue
    if [ "$kind" = tool ] && [ "$cmds" != - ]; then
      mkdir -p "$BIN_DIR"
      for c in $cmds; do
        target=$BIN_DIR/$(basename "$c")
        if [ -e "$target" ] && [ ! -L "$target" ]; then
          warn "$target は実体のファイルなのでリンクを張らない（$name の $c と名前がぶつかっている）"
          continue
        fi
        ln -sfn "$dest/$c" "$target"
        echo "  ✓ $target -> $dest/$c"
        linked="$linked $(basename "$c")"
      done
    fi
    if [ -f "$dest/install.sh" ]; then
      echo "  → $dest/install.sh"
      sh "$dest/install.sh" </dev/null || warn "$dest/install.sh が失敗した"
    fi
  done <"$list"
  rm -f "$list"
  # shellcheck disable=SC2086
  write_bin_exclude $linked
}

# ---- 公開範囲ごとの準備 ----

check_github_ssh() {
  reply=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -T git@github.com 2>&1 || true)
  case $reply in
    *"successfully authenticated"*) return 0 ;;
  esac
  echo "--private には ssh で GitHub に接続できることが必要（private リポジトリを clone するため）。" >&2
  echo "鍵を作って GitHub に登録してから実行し直す:" >&2
  echo "  ssh-keygen -t ed25519 && cat ~/.ssh/id_ed25519.pub   # 表示された公開鍵を https://github.com/settings/keys に登録" >&2
  echo "（gh が使えるなら: gh auth login && gh ssh-key add ~/.ssh/id_ed25519.pub）" >&2
  exit 1
}

install_work() {
  head_ "会社のPC"
  # Claude に会社のPCであることを知らせる（共通ルールの「会社のマシンでは〜」が働くように）
  memo=$HOME/.claude/CLAUDE.md
  if [ -f "$memo" ] && ! grep -q '^## 会社のPC' "$memo"; then
    printf '\n## 会社のPC\n\nこのマシンは会社のPC。共通ルールの「会社のマシンでは」の項目に従う（dotfiles は pull だけ、業務の情報を外に出さない）。\n' >>"$memo"
    echo "  ✓ $memo に「会社のPC」を追加"
  else
    echo "  - ${memo}（設定済み）"
  fi
  # 会社用の git の設定（メール・プロキシ・社内の証明書など）はこのPCの中だけに書く
  work_git=$CONFIG_HOME/git/work.gitconfig
  if [ ! -f "$work_git" ]; then
    mkdir -p "$(dirname "$work_git")"
    printf '%s\n' '# 会社用の git の設定。このPCの中だけに置く（どのリポジトリにも入れない）' \
      '# [user]' '# 	email = name@example.com' '# [http]' '# 	proxy = http://proxy.example.com:8080' >"$work_git"
    echo "  ✓ $work_git を作成（会社のメールなどを書く）"
  fi
  if git config --global --get-all include.path 2>/dev/null | grep -qxF "$work_git"; then
    echo "  - git の include（設定済み）"
  else
    git config --global --add include.path "$work_git"
    echo "  ✓ git の設定から $work_git を読み込む"
  fi
  # 会社のメールで public の dotfiles にコミット・push してしまわないように、push 先を無効にする
  if git -C "$DOTFILES_DIR" remote get-url origin >/dev/null 2>&1; then
    git -C "$DOTFILES_DIR" remote set-url --push origin no-push
    echo "  ✓ dotfiles の push を無効にした（pull はできる）"
  fi
}

# ---- 実行 ----

if [ $SCOPE = private ]; then
  check_github_ssh
  head_ "private リポジトリ"
  sync_repo "$PRIVATE_REPO" "$PRIVATE_DIR"
fi

if [ $NO_MODULES = 0 ] || [ -n "$NAMES" ]; then
  install_modules
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
    tools) install_tools ;;
    apps) install_apps ;;
    fonts) install_fonts ;;
    zsh)
      head_ "zsh"
      zshrc=${ZDOTDIR:-$HOME}/.zshrc
      # 自分の .zshrc（private リポジトリへのリンクを含む）からこのリポジトリの .zshrc を読み込んでいる場合は置き換えない
      if [ -f "$zshrc" ] && [ "$(readlink "$zshrc" 2>/dev/null)" != "$DOTFILES_DIR/.zshrc" ] &&
        grep -q 'dotfiles/\.zshrc' "$zshrc"; then
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
      if have tic; then
        tic -x -o "$HOME/.terminfo" "$DOTFILES_DIR/config/terminfo/herdr.terminfo"
        echo "  ✓ xterm-256color-herdr を登録"
      else
        warn "tic が無いので terminfo を登録しない（ncurses を入れてから install.sh terminfo）"
      fi
      ;;
    claude)
      head_ "Claude Code"
      install_claude
      ;;
  esac
done

[ $SCOPE = work ] && install_work

# private の設定（~/.config の個人の設定、Mac の設定など）は private リポジトリの install.sh が入れる
if [ $SCOPE = private ] && [ -f "$PRIVATE_DIR/install.sh" ]; then
  head_ "private の設定"
  sh "$PRIVATE_DIR/install.sh"
fi

if [ ! -f "$CONFIG_HOME/shell/local.sh" ]; then
  mkdir -p "$CONFIG_HOME/shell"
  cp "$DOTFILES_DIR/local.sh.example" "$CONFIG_HOME/shell/local.sh"
  echo
  echo "  ✓ $CONFIG_HOME/shell/local.sh を作成（自分用の設定はここに書く）"
fi

echo
echo "完了。README の「入れたあとにやること」に進む"
