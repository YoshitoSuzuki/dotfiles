#!/bin/zsh
# サイドバーのスペース名を、プロンプトと同じく1つ上のディレクトリまで（%2~）出すために、
# 各スペースの代表ペイン（最初のタブの最初のペイン）の場所を $dir として herdr に送る。
# 自分で名前を付けたスペースはその名前を送る。
# config.toml の [ui.sidebar.spaces] が workspace の代わりに $dir を表示している。

local ws label cwd old name dir herdr=${HERDR_BIN_PATH:-herdr}
$herdr api snapshot | jq -r '.result.snapshot as $s | $s.workspaces[] |
  .workspace_id as $w |
  (first($s.tabs[] | select(.workspace_id == $w)) .tab_id) as $t |
  (first($s.panes[] | select(.tab_id == $t)) | .foreground_cwd // .cwd) as $cwd |
  [$w, .label, $cwd, (.tokens.dir // "")] | @tsv' |
while IFS=$'\t' read -r ws label cwd old; do
  [[ -d $cwd ]] || continue
  # herdr が自動で付ける名前（git リポジトリならその名前、それ以外はディレクトリ名）。
  # cd の直後は git を調べ終わる前のディレクトリ名が付いていることがあるので、どちらも自動とみなす
  name=$(git -C $cwd rev-parse --show-toplevel 2>/dev/null) || name=$cwd
  [[ $name == $HOME ]] && name='~' || name=${name:t}
  if [[ $label == $name || $label == ${cwd:t} || ( $label == '~' && $cwd == $HOME ) ]]; then
    dir=$(cd -q $cwd && print -P '%2~')
  else
    dir=$label
  fi
  [[ $dir == $old ]] || $herdr workspace report-metadata $ws --source space-dir --token "dir=$dir" >/dev/null
done
