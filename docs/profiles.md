# 環境の判定とモジュールの仕組み

`install.sh` が「何を入れるか」を決める仕組みの説明。使い方は README の「入れ方」「オプション」「モジュール」。

## 判定の軸

入れるものは次の3つで決まる。OS と GUI は自動で判定し、会社の PC かどうかだけをオプションで指定する。

| 軸 | 値 | 決め方 |
| --- | --- | --- |
| OS | `macos` / `linux` | `uname -s` |
| GUI | あり / なし | macOS は常にあり。Linux は `$DISPLAY` / `$WAYLAND_DISPLAY` / `$XDG_CURRENT_DESKTOP` のどれかがあればあり。`--gui` / `--no-gui` で上書き |
| 会社の PC | `--work` | 付けたときだけ |

想定している環境と、それぞれのコマンド:

| 環境 | コマンド |
| --- | --- |
| Mac / Linux デスクトップ | `install.sh` |
| Linux サーバー | `install.sh`（Neovim も使うなら `--with nvim`） |
| 会社の Mac / Linux | `install.sh --work` |

- `--work` は中身をほかの環境と同じにして、会社の PC で起きやすい事故を防ぐ設定だけを足す。
  特に、この dotfiles の push 先を `no-push` にして、会社の git のメールで public のリポジトリに
  コミット・push できないようにしている（「会社のマシンでは pull だけ」をルールではなく仕組みで守る）

実行の順番: モジュール → 設定（`targets`）→ `--work` の安全策 → `local.sh` の雛形。

モジュールを設定より先に入れるのは、clone したリポジトリの内容を先に置いておくため。
`claude` の設定は既存の `CLAUDE.md` に読み込み行を足すだけなので、あとから入れても内容を壊さない。

## モジュール

- 一覧は `modules.tsv`。awk で OS に合うものだけを選び、同じ名前が複数あれば後ろの行を使う（`modules_table`）
- `tool` のコマンドは `~/bin` にリンクする。`~/bin` 自体が `bin` モジュールのリポジトリなので、
  リンクは `~/bin/.git/info/exclude` の管理範囲（`# >>> dotfiles modules` 〜 `# <<< dotfiles modules`）に
  書いて Git 管理から外す。**`.gitignore` に書かないのは、公開されてリンクの名前（使っているツール）が見えてしまうため**
- 既にある場所に別のリポジトリが置かれていたら触らない。未 push の変更などを消さないため
- Git でないファイルが既にある場所には、同じ名前のファイルだけを退避してリポジトリを重ねる（`adopt_repo`）。
  Claude Code を先に入れたマシンの `~/.claude` のような場所を想定している

## Linux の CLI で Neovim を入れない理由と、入れるとき

ssh で入る Linux は GNU screen 4.x の中で使うことが多く、フルカラーが使えないと Neovim の配色が崩れる。
そのため既定では入れず、`--with nvim` で入れられるようにした。入れたときは、
`config/nvim/init.lua` の最後で「`$TERM` が `screen*` で `$COLORTERM` が truecolor でなければ
`termguicolors` を切る」ようにしている（LazyVim が読み込みの途中で有効にするので、読み込みのあとで上書きする）。

## 確認のしかた

- 判定と一覧: `install.sh --dry-run`（`--work` / `--no-gui` などと組み合わせる）
- Linux: Docker の `ubuntu:24.04` で一般ユーザーを作り、`install.sh` / `--with nvim` / `--work` /
  `DISPLAY=:0 install.sh --dry-run` を試す
