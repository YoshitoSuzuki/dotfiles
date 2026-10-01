# macOS のターミナルで開く bash はログインシェルなので、~/.bashrc を直接は読まない。
# ここから読み込む。

# Homebrew
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# 「既定のシェルは zsh になりました」の表示を消す
export BASH_SILENCE_DEPRECATION_WARNING=1

[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
