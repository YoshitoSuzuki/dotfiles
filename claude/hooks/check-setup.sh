#!/bin/sh
# SessionStart フック: dotfiles の共通ルール（~/.claude/dotfiles/CLAUDE.md）が読み込めない状態なら知らせる。
# dotfiles の場所を移した・共通ファイルが無いコミットに切り替えた、などで import が切れると
# ルールの大半が黙って消えるため。正常なときは何も出さない。
# このファイルは install.sh claude が ~/.claude/hooks/ にコピーする（dotfiles が壊れていても動くように）。
cat >/dev/null 2>&1

shared=$HOME/.claude/dotfiles/CLAUDE.md
problem=
if [ ! -r "$shared" ]; then
  problem="$shared が読めません（dotfiles の場所の変更・ブランチの切り替えなど）。dotfiles の install.sh claude を実行し直してください"
elif ! grep -q '^@~/.claude/dotfiles/CLAUDE.md' "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
  problem="~/.claude/CLAUDE.md に共通ルールの読み込み行（@~/.claude/dotfiles/CLAUDE.md）がありません"
fi
[ -n "$problem" ] || exit 0

msg="共通の Claude 設定が読み込まれていません: $problem"
printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s。作業の前にユーザーにこのことを伝えること"}}\n' "$msg" "$msg"
