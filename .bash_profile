# macOS のターミナルで開く bash や ssh でログインした bash はログインシェルなので、
# ~/.bashrc を直接は読まない。ここから読み込む。

# Homebrew（macOS / Linux）
for _brew in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  [ -x "$_brew" ] && eval "$("$_brew" shellenv)"
done
unset _brew

# 「既定のシェルは zsh になりました」の表示を消す
export BASH_SILENCE_DEPRECATION_WARNING=1

[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
