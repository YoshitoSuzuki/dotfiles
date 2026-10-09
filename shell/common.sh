# bash と zsh の両方から読み込まれる共通設定。
# 両方のシェルで同じ意味になる書き方だけを置く（シェル固有の設定は .zshrc / .bashrc）。

_path_prepend() { [ -d "$1" ] && PATH="$1:$PATH"; }

## PATH

# PostgreSQL 17
_path_prepend /opt/homebrew/opt/postgresql@17/bin

# macOS標準
_path_prepend /usr/bin

# Homebrew の通常パス（Linux では /home/linuxbrew）
_path_prepend /home/linuxbrew/.linuxbrew/bin
_path_prepend /opt/homebrew/bin

# python3
_path_prepend /Library/Frameworks/Python.framework/Versions/3.14/bin

# java 25
if [ -x /usr/libexec/java_home ] && _java_home=$(/usr/libexec/java_home -v 25 2>/dev/null); then
  export JAVA_HOME=$_java_home
  _path_prepend "$JAVA_HOME/bin"
fi
unset _java_home

# 自作コマンド
_path_prepend "$HOME/bin"

# TeX
_path_prepend /Library/TeX/texbin

# antigravity
_path_prepend "$HOME/.local/bin"

export PATH

# MAN files
export MANPATH="$HOME/man:$MANPATH"


## Linux で macOS のコマンドを使う

# open をデスクトップの既定アプリで開く xdg-open に読み替える
if ! command -v open >/dev/null 2>&1 && command -v xdg-open >/dev/null 2>&1; then
  open() { xdg-open "$@" >/dev/null 2>&1; }
fi


## Alias

alias l='ls -l'
alias la='ls -a'
alias op='open'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias od='open ~/Downloads'
alias tmp='cd ~/tmp'

## rm をゴミ箱送りにする（macOS は rmtrash、Linux は trash-cli）
if command -v rmtrash >/dev/null 2>&1; then
  alias rm='rmtrash'
elif command -v trash-put >/dev/null 2>&1; then
  alias rm='trash-put'
fi

## Git commands
alias gs='git status'
alias ga='git add -A'
alias gc='git commit -m'
alias gp='git push -u origin'
alias gch='git checkout'
alias gcm='git checkout main'
alias gcb='git checkout -b'
alias gb='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch -D'

## Claude Code
alias ai='claude'

## local AI
alias lai='open http://localhost:11500'

## Google Cloud
alias gssh='gcloud compute ssh --tunnel-through-iap'


## Neovim に渡す TERM

# herdr のペインの中は TERM=xterm-256color で、macOS 標準の terminfo には smxx
# （取り消し線）が無い。Neovim は terminfo に無い属性を送らないので、markdown の
# ~~取り消し線~~ や undercurl が見た目に反映されない。nvim にだけ拡張版を渡す。
# 拡張版の terminfo（macOS は ~/.terminfo/78/、Linux は ~/.terminfo/x/ の下）が無ければ何もしない。
# 素の Ghostty なら TERM=xterm-ghostty なので、この条件には入らない。
if [ "$TERM" = xterm-256color ] &&
  { [ -f ~/.terminfo/78/xterm-256color-herdr ] || [ -f ~/.terminfo/x/xterm-256color-herdr ]; }; then
  nvim() { TERM=xterm-256color-herdr command nvim "$@"; }
fi


## Function

mcd() {
  mkdir -p -- "$1" && cd -- "$1"
}
