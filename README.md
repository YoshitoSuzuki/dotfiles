# dotfiles

ターミナルまわりの開発環境一式。`install.sh` 1本で、アプリの導入から設定まで終わる。

- **Ghostty**（ターミナル）を開くと **herdr**（AI エージェント向けのターミナルマルチプレクサ）に入る
- シェルは **zsh** と **bash** のどちらでも同じエイリアス・PATH・関数が使える
- エディタは **Neovim**（[LazyVim](https://www.lazyvim.org/) ベース。Markdown を書きながら完成形で表示する）
- **WezTerm** は herdr が固まったときの予備のターミナル
- **Zed** は GUI のエディタ（Markdown を書くとき用。vim モードで、右にプレビューを開ける）
- 見た目は全部 Tokyo Night + JetBrains Mono Nerd Font で統一
- **Claude Code** の共通ルール（CLAUDE.md）・フック・スキル・ナレッジも入れられる（下の「Claude Code」）
- 自作コマンドなど**別のリポジトリで管理しているもの**も clone して反映できる（下の「モジュール」）

対象は **macOS** と **Linux**（どちらも Apple Silicon / ARM と x86_64）。
OS と GUI の有無は自動で判定し、入れるものを変える（ssh で入るだけの Linux にはアプリを入れない）。

## 入れ方

```sh
xcode-select --install     # macOS で git が無ければ。Linux なら sudo apt install git curl
git clone https://github.com/YoshitoSuzuki/dotfiles.git ~/dotfiles
~/dotfiles/install.sh      # 環境に合わせたオプションは下の表
```

`xcode-select --install` で入るのは Xcode 本体ではなく、git やコンパイラなどのコマンド一式
（Command Line Tools）。Neovim がプラグインの取得と構文解析器のビルドに使うので必要。

| 環境 | コマンド | 入るもの |
| --- | --- | --- |
| 自分用・人に見せる Mac | `install.sh` | アプリ・設定の一式（Homebrew）と自作コマンド（`~/bin`） |
| Homebrew を使えない Mac | `install.sh --no-brew` | 同じものを公式の配布物から `~` の下に入れる（管理者権限は要らない） |
| Linux（デスクトップ） | `install.sh` | 設定の一式とフォント、CLI のツール。ターミナルアプリ本体はパッケージで入れる（下の「Linux（GUI）」） |
| Linux（ssh で入るだけ） | `install.sh` | シェルの設定（bash、zsh があれば zsh）と自作コマンドだけ |
| Linux（ssh、Neovim も使う） | `install.sh --with nvim` | 上に加えて Neovim・ripgrep・fd・lazygit・Node.js を `~/.local` に |
| 会社の PC | `install.sh --work` | 上のどれかに加えて、会社の PC 向けの安全策（下の「オプション」） |

`install.sh` がやること（何度実行しても同じ結果になる）:

1. モジュール（自作コマンドなどのリポジトリ）を clone し、コマンドを `~/bin` にリンクする（下の「モジュール」）
2. アプリを入れる。macOS は Homebrew と `Brewfile`（無ければ Homebrew から入れる。パスワードを聞かれる）。
   `--no-brew` や Linux のデスクトップでは公式の配布物から `~` の下に入れる
3. 設定ファイルをシンボリックリンクで置く。既にあるファイルは `<名前>.backup.<日時>` に退避する
4. herdr の中の Neovim で取り消し線と波線を出すための terminfo を登録する
5. `--work` のときは Claude Code の共通設定を `~/.claude` に足す（下の「Claude Code」）
6. 自分用の設定ファイル `~/.config/shell/local.sh` が無ければ雛形から作る

何が入るかは、先に `install.sh --dry-run`（ほかのオプションと組み合わせてよい）で確かめられる。

## オプション

| オプション | 何をするか | 付けないとき |
| --- | --- | --- |
| `--work` | 会社の PC 用。public の一式に次の4つを足す: Claude Code の共通設定 / `~/.claude/CLAUDE.md` に「会社のPC」と書く（共通ルールの「会社のマシンでは」を Claude が判断できるように） / `~/.config/git/work.gitconfig` の雛形を作り git から読み込む（会社のメール・プロキシなどはここに書く） / この dotfiles の push を無効にする（会社のメールで public のリポジトリにコミットしないように。pull はできる） | public（誰が使ってもよい設定だけ） |
| `--with <名前,...>` | 既定の一覧に足す。設定の名前でもモジュールの名前でもよい。カンマ区切りか、`--with` を繰り返す。`--with nvim` は Neovim 本体（`tools`）も一緒に入れる | 既定の一覧のまま |
| `--without <名前,...>` | 既定の一覧から除く（`--all` と組み合わせると、全部から除く） | 同上 |
| `--all` | 入れられるものを全部入れる（既定で入らない `opt` のモジュールと `claude` を含む）。GUI の無い環境では herdr・アプリ・ターミナルの設定は入れない | 環境ごとの既定 |
| `--gui` / `--no-gui` | GUI の有無の自動判定を上書きする。自動判定は「macOS は常にあり、Linux は `$DISPLAY` / `$WAYLAND_DISPLAY` / `$XDG_CURRENT_DESKTOP` のどれかがあればあり」 | 自動判定 |
| `--no-brew` | Homebrew を使わない。`brew` の代わりに `tools` `apps` `fonts` を入れる（macOS の GUI のときだけ意味がある。Linux はもともと Homebrew を使わない） | macOS では Homebrew を使う |
| `--no-modules` | モジュールを clone・更新しない（設定だけ入れる） | モジュールも入れる |
| `--dry-run` | 判定結果（OS・GUI・公開範囲）と、入れる設定・モジュールを表示するだけで、何も変えない | 実際に入れる |
| `-h` / `--help` | 使い方を表示する | |
| 名前を並べる（`install.sh nvim ghostty`） | 並べた名前のものだけを入れる。既定の一覧とモジュールの既定は使わない（モジュールも名前を書けば入る） | |


### 環境ごとの既定の一覧

| 環境 | 設定 |
| --- | --- |
| macOS | `brew zsh bash ghostty herdr nvim wezterm zed terminfo`（`--no-brew` なら `brew` の代わりに `tools apps fonts`） |
| Linux（GUI あり） | `tools apps fonts zsh bash ghostty herdr nvim wezterm zed terminfo` |
| Linux（GUI なし） | `zsh bash`（zsh が入っていないときは `bash` だけ）。`--all` なら `tools zsh bash nvim terminfo claude` |
| `--work` | 上に `claude` を足す |

### 設定の名前（`--with` / `--without` / 名前を並べるときに使う）

| 名前 | 入るもの |
| --- | --- |
| `brew` | Homebrew と `Brewfile` のアプリ（macOS） |
| `tools` | Neovim・ripgrep・fd・lazygit・Node.js（LTS）を `~/.local/opt` に入れ、コマンドを `~/.local/bin` にリンク |
| `apps` | herdr を `~/.local/bin` に。macOS では Ghostty・WezTerm・Zed を `~/Applications` に。Linux ではターミナルアプリが無ければ入れ方を表示するだけ |
| `fonts` | JetBrains Mono Nerd Font（macOS は `~/Library/Fonts`、Linux は `~/.local/share/fonts`） |
| `zsh` | `~/.zshrc`（`ZDOTDIR` があればその下） |
| `bash` | `~/.bashrc` / `~/.bash_profile` |
| `ghostty` / `nvim` / `wezterm` | `~/.config/<名前>` |
| `herdr` | `~/.config/herdr/config.toml` |
| `zed` | `~/.config/zed/settings.json` / `keymap.json` と `zed` コマンド |
| `terminfo` | herdr の中の Neovim で取り消し線・波線を出すための terminfo |
| `claude` | Claude Code の共通ルール・フック・スキル（下の「Claude Code」） |

モジュールの名前は `modules.tsv` を見る（下の「モジュール」）。

## モジュール

自作コマンドなど、**別のリポジトリで管理しているもの**を clone して反映させる仕組み。
一覧は `modules.tsv`（タブ区切り）に書く。

| 列 | 中身 |
| --- | --- |
| 名前 | `--with` / `--without` で使う名前 |
| 種類 | `data`（置き場所に clone するだけ）か `tool`（clone して、コマンドを `~/bin` にリンクする） |
| OS | `all` / `macos` / `linux` |
| 既定 | `yes`（既定で入る）か `opt`（`--with <名前>` か `--all` のときだけ入る） |
| リポジトリ | clone する URL |
| 置き場所 | `-` なら `~/bin-src/<名前>` |
| コマンド | `tool` のとき、`~/bin` にリンクするファイル（リポジトリ内のパスを空白区切り） |

今の一覧:

| 名前 | 種類 | 既定 | 中身 |
| --- | --- | --- | --- |
| `bin` | data | yes | 小さな自作コマンド（`crun` `cprun` `md` `ch`）。[bin-commands](https://github.com/YoshitoSuzuki/bin-commands) を `~/bin` に clone する（PATH に入っている） |
| `webpin` | tool | opt | [webpin](https://github.com/YoshitoSuzuki/webpin)。`~/bin-src/webpin` に clone し、`~/bin/webpin` にリンクする |

置き場所の決まり:

```
~/bin/          小さなコマンドのリポジトリ（実体はここ。ここで編集して push する）。PATH に入っている
  crun  md …
  webpin -> ~/bin-src/webpin/bin/webpin    install.sh が張るリンク
~/bin-src/      大きなツールのリポジトリを並べる場所（ここ自体は Git で管理しない）
  webpin/       それぞれ独立したリポジトリ。ここで編集して push する
```

- リポジトリの中に別のリポジトリは入れない（横に並べる）
- `~/bin` に張ったリンクは `~/bin/.git/info/exclude` の `# >>> dotfiles modules` から `# <<< dotfiles modules` までに
  書き込んで、`~/bin` のリポジトリの Git 管理から外す。`.gitignore` と違ってコミットされないので、
  リンクの名前が公開されない。この範囲は install.sh が毎回書き直すので、手で書く除外はその外に書く
- 既に置き場所にリポジトリがあれば `git pull --ff-only` だけをする。**別のリポジトリが置かれていたら何もしない**
  （警告を出す。入れ替えるなら手で退避してから実行し直す）
- 置き場所に Git でないファイルが既にあるとき（Claude Code が先に作った `~/.claude` など）は、
  同じ名前のファイルを `.backup.<日時>` に退避してから、リポジトリの内容を重ねる
- `~/bin` に同じ名前の実体のファイルがあるときは、リンクを張らずに警告する
- どのモジュールにも属さなくなったリンクは警告だけを出す（自動では消さない）
- リポジトリの直下に `install.sh` があれば、clone・更新のあとに実行する（常駐ジョブの登録など、
  反映の手順は各リポジトリが自分で持つ）

## 環境ごとの補足

### Homebrew を使わない場合

会社の Mac などで Homebrew を入れられないときは `install.sh --no-brew` を使う。
各アプリを公式の配布物から直接ダウンロードして、自分のホームの下に入れる。**管理者権限は要らない**。

| もの | 入手元 | 入る場所 |
| --- | --- | --- |
| Ghostty / WezTerm / Zed | ghostty.org / GitHub Releases / zed.dev | `~/Applications` |
| herdr | herdr.dev の公式インストーラ | `~/.local/bin` |
| Neovim / ripgrep / fd / lazygit | GitHub Releases | `~/.local/opt/<名前>`（コマンドは `~/.local/bin` にリンク） |
| Node.js（LTS の最新版） | nodejs.org | 同上 |
| JetBrains Mono Nerd Font | Nerd Fonts の GitHub Releases | `~/Library/Fonts` |

- すでに入っているもの（Homebrew 版を含む）は飛ばす
- `rm` をゴミ箱送りにする `rmtrash` は入らない（`rm` は通常の削除のまま）
- 自動では更新されない。新しい版にするときは `~/.local/opt/<名前>` を消してから `install.sh tools`
- **会社の Mac では、Homebrew を使うかどうかに関係なく、ソフトを入れてよいかを先に社内のルールで確認する**

### Linux（ssh で入るだけ）

既定ではシェルの設定（bash、zsh が入っていれば zsh）と自作コマンドだけを入れる。
エイリアス・PATH・関数は macOS と同じものが使える。

- Neovim も使うなら `install.sh --with nvim`。プラグインのビルドに git と C コンパイラが要る
  （Debian / Ubuntu なら `sudo apt install git build-essential`。無ければ install.sh が警告する）
- GNU screen 4.x などフルカラーを扱えない端末（`$TERM` が `screen*` で `$COLORTERM` が無い）では、
  Neovim は 256 色の配色になる
- `open` は `xdg-open` に読み替わる。`rm` をゴミ箱送りにしたいなら `trash-cli` を入れる

### Linux（GUI）

デスクトップのセッションから実行すると、設定の一式・フォント・CLI のツール・herdr を入れる。
ターミナルアプリ本体は管理者権限が要るので自動では入れない。無ければ install.sh が知らせるので、
ディストリビューションのパッケージか公式の手順で入れる（Ghostty: <https://ghostty.org/docs/install/binary>、
WezTerm: <https://wezterm.org/install/linux.html>、Zed: `curl -f https://zed.dev/install.sh | sh`）。

## 入れたあとにやること

1. **Ghostty を開く**（Spotlight で「Ghostty」）。そのまま herdr の画面になる。
   ssh で入るだけの Linux なら、代わりにログインし直すか `exec bash -l` を実行するだけでよい（以降の手順は不要）
2. **`nvim` を一度起動する**。プラグインのダウンロードが始まるので、終わるまで待って `:q` で閉じる。
   言語ごとの LSP は、その言語のファイルを初めて開いたときに自動で入る
3. **`~/.config/shell/local.sh` に自分用の設定を書く**（ssh 先など。下の「自分用の設定」）
4. （Claude Code を使うなら）`herdr integration install claude` で、herdr のサイドバーに
   エージェントの状態（作業中・待機中）が出るようになる

## Claude Code

`install.sh claude` で、どのマシンの Claude Code でも同じルールで動くようにする。
中身は public なので、**個人情報・会社の情報・特定のマシンに依存する内容は入れない**
（それらは各マシンの `~/.claude/CLAUDE.md` と `~/.claude/knowledge/` に書く）。

```sh
git clone https://github.com/YoshitoSuzuki/dotfiles.git ~/dotfiles
~/dotfiles/install.sh claude
```

やること（何度実行しても同じ結果になる。既存の設定は置き換えない）:

1. `~/.claude/dotfiles` を `claude/` へのリンクにする
2. `~/.claude/CLAUDE.md` の先頭に `@~/.claude/dotfiles/CLAUDE.md`（共通ルールの読み込み）を足す。
   ファイルが無ければ作る。既にあれば元を `CLAUDE.md.backup.<日時>` に退避してから足す
3. `claude/hooks/` を `~/.claude/hooks/` に**コピー**する（リンクにしないのは、dotfiles の場所を
   変えたりブランチを切り替えたりしてもフックが動き続けるようにするため）
4. `claude/skills/` のスキルを、同じ名前のものが無いときだけリンクする
5. `~/.claude/settings.json` にフックの設定を、無ければ足す（permissions や model には触らない）

| フック | いつ | 何をする |
| --- | --- | --- |
| `japanese-reply.py` | メッセージを送ったとき | 日本語のメッセージなら「日本語の丁寧語で返す」と Claude に念押しする |
| `check-setup.sh` | セッション開始時 | 共通ルールが読み込めない状態（リンク切れなど）なら画面に警告を出す。正常なら何も出さない |

確認: `claude` を起動して `/memory` を開き、`~/.claude/dotfiles/CLAUDE.md` が読み込まれていればよい。

**会社の Mac では dotfiles を編集・コミットしない**（`git pull` だけにする）。会社の git 設定の
メールアドレスで public リポジトリにコミットしてしまうのを防ぐため。共通ルールを直すのは個人の Mac から。

## キー操作

Ghostty + herdr・Neovim・Zed・シェルの操作キーは [docs/keys.md](docs/keys.md) にまとめている。
公開範囲・GUI の判定とモジュールの仕組みは [docs/profiles.md](docs/profiles.md)。

## 自分用の設定

人に見せたくない設定や、マシン固有の設定はリポジトリに入れず、次のファイルに書く。
あれば読み込まれる。

| ファイル | 読み込むシェル |
| --- | --- |
| `~/.config/shell/local.sh` | bash と zsh の両方（共通設定の直後） |
| `~/.config/shell/local.zsh` | zsh だけ（最後） |
| `~/.config/shell/local.bash` | bash だけ（最後） |

`local.sh` で `NAMED_DIRS` 配列を定義すると、ディレクトリの短縮名として使える。

```sh
NAMED_DIRS=(
  "proj=$HOME/projects"
)
export TEX_AUTHOR='名前'
```

- zsh: `cd ~proj`、`ls ~proj/foo`
- bash: `cd proj`、`ls $proj/foo`（bash には `~名前` が無いので変数で代用）

## ファイル構成

| ファイル | 置き場所 | 中身 |
| --- | --- | --- |
| `shell/common.sh` | （`.zshrc` / `.bashrc` が読む） | bash と zsh で共通の設定（PATH、エイリアス、関数） |
| `.zshrc` | `~/.zshrc` | zsh 固有の設定（履歴、global alias、`hash -d`、プロンプト） |
| `.bashrc` / `.bash_profile` | `~/.bashrc` / `~/.bash_profile` | bash 固有の設定。zsh の機能を bash で再現している |
| `config/ghostty/` | `~/.config/ghostty` | フォント・テーマ・透過、herdr の自動起動、Cmd キーの転送 |
| `config/herdr/config.toml` | `~/.config/herdr/config.toml` | prefix キー、テーマ、サイドバーの表示 |
| `config/nvim/` | `~/.config/nvim` | LazyVim の設定（`lazy-lock.json` でプラグインの版を固定） |
| `config/wezterm/` | `~/.config/wezterm` | 予備ターミナル。Ghostty と同じ見た目・キー配置 |
| `config/zed/settings.json` / `keymap.json` | `~/.config/zed/` の同名ファイル | vim モード、保存時の整形、Markdown の折り返し、拡張の自動導入、プレビューとペイン移動のキー。`zed` コマンドも `~/.local/bin` に置く |
| `config/terminfo/herdr.terminfo` | `~/.terminfo`（`tic` で登録） | 取り消し線・波線を足した `xterm-256color` |
| `Brewfile` | | `install.sh brew` で入るアプリ（macOS） |
| `modules.tsv` | | モジュール（自作コマンドなどのリポジトリ）の一覧。上の「モジュール」 |
| `local.sh.example` | `~/.config/shell/local.sh` | 自分用設定の雛形 |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` から読み込む | Claude Code の共通ルール |
| `claude/hooks/` | `~/.claude/hooks/`（コピー） | Claude Code のフック（上の「Claude Code」） |
| `claude/skills/` | `~/.claude/skills/` | Claude Code のスキル（docs/ を整備する project-docs） |
| `claude/knowledge/` | `~/.claude/dotfiles/knowledge/` | どのマシンでも使える知識。Claude が作業前に `INDEX.md` を読む |
| `claude/settings-merge.py` | | `~/.claude/settings.json` にフックの設定を足す |

## 更新

```sh
git -C ~/dotfiles pull
```

設定はリンクなので pull した時点で反映される。開いているものは読み直す:
シェルは `exec $SHELL`、Ghostty は `Cmd+Shift+,`、herdr は `herdr server reload-config`、Neovim は再起動。
Claude Code の共通ルールは次に起動したセッションから反映される。`claude/hooks/` が変わったときだけ
`install.sh claude` を実行し直す（フックはコピーなので pull だけでは更新されない）。

モジュールも更新するなら、最初に入れたときと同じオプションで `install.sh` を実行し直す
（各モジュールを `git pull --ff-only` し、増えたコマンドのリンクを張る。ほかの設定は「設定済み」と出るだけ）。

## zsh と bash の違い

| 機能 | zsh | bash |
| --- | --- | --- |
| ディレクトリ名だけで移動 | `auto_cd` | `autocd`（bash 4 以降のみ。macOS 標準の 3.2 では無効） |
| 入力途中からの履歴検索 | `Ctrl-P` / `Ctrl-N` | 同じ |
| `G` `L` `A`（`\| grep` などの global alias） | 使える | 無い |
| `vim` → `nvim` | 行のどこでも置き換わる | 行頭のみ |
| 右プロンプト | ` ###` | 無い |
| 設定の編集 / 再読み込み | `ezh` / `szh` | `ebh` / `sbh` |

## うまくいかないとき

| 症状 | 対処 |
| --- | --- |
| アイコンが豆腐（□）になる | Nerd Font が入っていない。`install.sh brew` |
| Neovim で `~~取り消し線~~` が出ない | terminfo が未登録。`install.sh terminfo` |
| `nested herdr is disabled` で落ちる | herdr の中から `open -a Ghostty` した。Dock や Spotlight から開く |
| herdr の設定変更が効かない | `ls -l ~/.config/herdr/config.toml` がリンクでなくなっていたら `install.sh herdr` |
| 元の設定に戻したい | リンクを消して `.backup.<日時>` のファイルを元の名前に戻す |
