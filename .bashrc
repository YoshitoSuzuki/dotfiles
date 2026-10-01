# bash の設定。zsh と共通の部分は shell/common.sh にある。
# macOS 標準の bash 3.2 でも動くように書いている。
#
# 人に見せたくない設定（ssh 先、ディレクトリの短縮名など）は次のファイルに書く。
# あれば読み込まれる:
#   ~/.config/shell/local.sh    … bash と zsh の両方で使うもの
#   ~/.config/shell/local.bash  … bash だけで使うもの

# 対話シェル以外（scp やスクリプト）では何もしない
case $- in *i*) ;; *) return ;; esac

# ~/.bashrc はシンボリックリンクなので、実体のある場所をたどる
_src=${BASH_SOURCE[0]}
while [ -L "$_src" ]; do
  _link=$(readlink "$_src")
  case $_link in
    /*) _src=$_link ;;
    *) _src=$(dirname "$_src")/$_link ;;
  esac
done
DOTFILES_DIR=$(cd "$(dirname "$_src")" && pwd)
unset _src _link
LOCAL_SHELL_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/shell

. "$DOTFILES_DIR/shell/common.sh"
[ -f "$LOCAL_SHELL_DIR/local.sh" ] && . "$LOCAL_SHELL_DIR/local.sh"


## History

# メモリに保存される履歴の件数
export HISTSIZE=1000000

# 履歴ファイルに保存される履歴の件数
export HISTFILESIZE=1000000

# 重複を保存しない
export HISTCONTROL=ignoredups

# コマンド実行時に即座に履歴ファイルへ追記する
shopt -s histappend
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"


## Alias

alias h='history 100'
alias hg='history 1000 | grep'

## bashrc
alias ebh="nvim $DOTFILES_DIR/.bashrc"
alias sbh="source $HOME/.bashrc"

# zsh の global alias（vim → nvim）の代わり。bash は行頭でしか展開しない
if command -v nvim >/dev/null 2>&1; then
  alias vim='nvim'
  alias vi='nvim'
fi


## Directory Hash

# bash には zsh の ~名前 が無いので、local.sh の NAMED_DIRS（"名前=パス" の配列）を
# 変数にする。cdable_vars で `cd p` のように変数名だけで移動でき、`$p/foo` とも書ける
for _d in "${NAMED_DIRS[@]}"; do
  declare "${_d%%=*}=${_d#*=}"
done
unset _d
shopt -s cdable_vars


## auto_cd（bash 4 以降。macOS 標準の 3.2 では使えない）

shopt -s autocd 2>/dev/null


## History Beginning Search

bind '"\C-p": history-search-backward'
bind '"\C-n": history-search-forward'


## Prompt

# zsh の %2~（~ を使った表記で末尾2階層）と同じものを作る。bash に右プロンプトは無い
_prompt_pwd() {
  local p=$PWD
  case $p in
    "$HOME") p='~' ;;
    "$HOME"/*) p="~${p#"$HOME"}" ;;
  esac
  local rest=${p%/*}
  if [ "$rest" = "$p" ] || [ -z "$rest" ]; then
    printf '%s' "$p"
  else
    printf '%s/%s' "${rest##*/}" "${p##*/}"
  fi
}
PS1='\[\e[36m\]$(_prompt_pwd)\[\e[0m\] $ '


[ -f "$LOCAL_SHELL_DIR/local.bash" ] && . "$LOCAL_SHELL_DIR/local.bash"
