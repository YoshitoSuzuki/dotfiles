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


[ -f "$LOCAL_SHELL_DIR/local.zsh" ] && source "$LOCAL_SHELL_DIR/local.zsh"
