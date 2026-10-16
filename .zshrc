# zsh の設定。bash と共通の部分は shell/common.sh にある。
#
# 人に見せたくない設定（ssh 先、ディレクトリの短縮名など）は次のファイルに書く。
# あれば読み込まれる:
#   ~/.config/shell/local.sh   … bash と zsh の両方で使うもの
#   ~/.config/shell/local.zsh  … zsh だけで使うもの

DOTFILES_DIR=${${(%):-%x}:A:h}
LOCAL_SHELL_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/shell

source "$DOTFILES_DIR/shell/common.sh"
[ -f "$LOCAL_SHELL_DIR/local.sh" ] && source "$LOCAL_SHELL_DIR/local.sh"


## History

# .zsh_historyの保存場所
export HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"

# メモリに保存される履歴の件数
export HISTSIZE=1000000

# 履歴ファイルに保存される履歴の件数
export SAVEHIST=1000000

# 重複を保存しない
setopt hist_ignore_dups

# コマンド実行時に即座に履歴ファイルへ追記する
setopt inc_append_history


## Alias

alias h='history -100'
alias hg='history -1000|grep'

## zshrc
alias ezh="nvim $DOTFILES_DIR/.zshrc"
alias szh="source ${ZDOTDIR:-$HOME}/.zshrc"


## Global Alias

alias -g G='| grep'
alias -g L='| wc -l'
alias -g A='&&'
if (( $+commands[nvim] )); then
  alias -g vim='nvim'
  alias -g vi='nvim'
fi


## Directory Hash

# local.sh の NAMED_DIRS（"名前=パス" の配列）を ~名前 で使えるようにする
for _d in "${NAMED_DIRS[@]}"; do
  hash -d "$_d"
done
unset _d


## auto_cd

setopt auto_cd


## History Beginning Search

bindkey '^P' history-beginning-search-backward
bindkey '^N' history-beginning-search-forward


## Prompt

PROMPT='%F{cyan}%2~%f $ '
RPROMPT=' ###'


## herdr のスペース名

# サイドバーのスペース名を、プロンプトと同じく1つ上のディレクトリまで（%2~）出す。
# herdr にはその設定が無いので、プロンプトのたびにスペースの代表ペイン（最初のタブの
# 最初のペイン）の場所を $dir として herdr に送り、config.toml の [ui.sidebar.spaces] で
# workspace の代わりに表示している。自分で名前を付けたスペースはその名前を送る。
_herdr_space_dir() {
  local ws=${1:-$HERDR_WORKSPACE_ID} tab cwd label name dir
  tab=$(herdr tab list --workspace $ws | jq -r '.result.tabs[0].tab_id')
  cwd=$(herdr pane list | jq -r --arg t $tab 'first(.result.panes[] | select(.tab_id == $t)) | .cwd')
  label=$(herdr workspace get $ws | jq -r '.result.workspace.label')
  [[ -d $cwd ]] || return
  # herdr が自動で付ける名前（git リポジトリならその名前、それ以外はディレクトリ名）
  name=$(git -C $cwd rev-parse --show-toplevel 2>/dev/null) || name=$cwd
  [[ $name == $HOME ]] && name='~' || name=${name:t}
  if [[ $label == $name ]]; then
    dir=$(cd -q $cwd && print -P '%2~')
  else
    dir=$label
  fi
  herdr workspace report-metadata $ws --source zsh --token "dir=$dir" >/dev/null
}
if [[ -n $HERDR_WORKSPACE_ID ]] && (( $+commands[herdr] && $+commands[jq] )); then
  autoload -Uz add-zsh-hook
  _herdr_space_dir_precmd() { _herdr_space_dir &>/dev/null &! }
  add-zsh-hook precmd _herdr_space_dir_precmd
fi


[ -f "$LOCAL_SHELL_DIR/local.zsh" ] && source "$LOCAL_SHELL_DIR/local.zsh"
