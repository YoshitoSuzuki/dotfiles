# 公開範囲・GUI・モジュールの仕組み

`install.sh` が「何を入れるか」を決める仕組みの説明。使い方は README の「入れ方」「オプション」「モジュール」。

## 3つの軸

入れるものは次の3つで決まる。OS と GUI は自動で判定し、公開範囲だけをオプションで指定する。

| 軸 | 値 | 決め方 |
| --- | --- | --- |
| OS | `macos` / `linux` | `uname -s` |
| GUI | あり / なし | macOS は常にあり。Linux は `$DISPLAY` / `$WAYLAND_DISPLAY` / `$XDG_CURRENT_DESKTOP` のどれかがあればあり。`--gui` / `--no-gui` で上書き |
| 公開範囲 | `public` / `work` / `private` | オプション無しで public。`--work` / `--private` |

**オプション無しを public にしているのは、他人が clone して実行しても個人の設定に触れないようにするため**。

想定している環境と、それぞれのコマンド:

| 環境 | コマンド |
| --- | --- |
| 個人の Mac | `install.sh --private` |
| 個人の Linux（サーバー・デスクトップ） | `install.sh --private`（サーバーで Neovim も使うなら `--with nvim`） |
| 公開用の Mac / Linux デスクトップ | `install.sh` |
| 公開用の Linux サーバー | `install.sh`（`--with nvim`） |
| 会社の Mac / Linux | `install.sh --work` |

## 層

```
public   ~/dotfiles           誰が使ってもよい設定と、public のモジュール（modules.tsv）
work     （ローカルだけ）      public に安全策を足す。会社の設定はどのリポジトリにも入れない
private  ~/dotfiles-private   個人の設定と、private のモジュール。DOTFILES_PRIVATE_REPO で差し替えられる
```

- `--work` は中身を public と同じにして、会社の PC で起きやすい事故を防ぐ設定だけを足す。
  特に、dotfiles の push 先を `no-push` にして、会社の git のメールで public のリポジトリに
  コミット・push できないようにしている（「会社のマシンでは pull だけ」をルールではなく仕組みで守る）
- `--private` は、public の一式を入れる前に private リポジトリを clone しておく。
  そうすることで、そこの `modules.tsv` が public の一覧に重なる
- 入口は public の `install.sh` だけにする。private の `install.sh` から public の install.sh を呼び返さない

実行の順番: private リポジトリの clone → モジュール → 設定（`targets`）→ `--work` の安全策 →
private の `install.sh` → `local.sh` の雛形。

モジュールを設定より先に入れるのは、`~/.claude` などを先にリポジトリの内容にしておくため。
`claude` の設定は既存の `CLAUDE.md` に読み込み行を足すだけなので、あとから入れても内容を壊さない。

## モジュール

- 一覧は public の `modules.tsv` と private の `modules.tsv`。awk で「同じ名前は private を優先」に
  まとめてから順に処理する（`modules_table`）
- 同じ役割で public 版と private 版があるもの（自作コマンドの `bin`）は、同じ名前で両方の一覧に書く。
  private のときだけ private 版に置き換わる
- `tool` のコマンドは `~/bin` にリンクする。`~/bin` 自体が `bin` モジュールのリポジトリなので、
  リンクは `~/bin/.git/info/exclude` の管理範囲（`# >>> dotfiles modules` 〜 `# <<< dotfiles modules`）に
  書いて Git 管理から外す。**`.gitignore` に書かないのは、公開されてリンクの名前（使っているツール）が見えてしまうため**
- 既にある場所に別のリポジトリが置かれていたら触らない。public から private に切り替えたときに
  `~/bin` の中身（未 push の変更など）を消さないため
- Git でないファイルが既にある場所には、同じ名前のファイルだけを退避してリポジトリを重ねる（`adopt_repo`）。
  Claude Code を先に入れたマシンの `~/.claude` を想定している

## Linux の CLI で Neovim を入れない理由と、入れるとき

ssh で入る Linux は GNU screen 4.x の中で使うことが多く、フルカラーが使えないと Neovim の配色が崩れる。
そのため既定では入れず、`--with nvim` で入れられるようにした。入れたときは、
`config/nvim/init.lua` の最後で「`$TERM` が `screen*` で `$COLORTERM` が truecolor でなければ
`termguicolors` を切る」ようにしている（LazyVim が読み込みの途中で有効にするので、読み込みのあとで上書きする）。

## 確認のしかた

- 判定と一覧: `install.sh --dry-run`（`--private` / `--work` / `--no-gui` などと組み合わせる）
- Linux: Docker の `ubuntu:24.04` で一般ユーザーを作り、`install.sh` / `--with nvim` / `--work` /
  `DISPLAY=:0 install.sh --dry-run` を試す。ssh 鍵の無いコンテナで `--private` が案内を出して止まることも見る
