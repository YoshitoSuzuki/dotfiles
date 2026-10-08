# dotfiles

ターミナルまわりの開発環境一式。`install.sh` 1本で、アプリの導入から設定まで終わる。

- **Ghostty**（ターミナル）を開くと **herdr**（AI エージェント向けのターミナルマルチプレクサ）に入る
- シェルは **zsh** と **bash** のどちらでも同じエイリアス・PATH・関数が使える
- エディタは **Neovim**（[LazyVim](https://www.lazyvim.org/) ベース。Markdown を書きながら完成形で表示する）
- **WezTerm** は herdr が固まったときの予備のターミナル
- **Zed** は GUI のエディタ（Markdown を書くとき用。vim モードで、右にプレビューを開ける）
- 見た目は全部 Tokyo Night + JetBrains Mono Nerd Font で統一
- **Claude Code** の共通ルール（CLAUDE.md）・フック・スキル・ナレッジも入れられる（下の「Claude Code」）

対象は **macOS** と **Linux**（どちらも Apple Silicon / ARM と x86_64）。
Linux（ssh で入るだけのサーバー）では **bash の設定だけ**を入れる。

## 入れ方

```sh
xcode-select --install     # git が無ければ。ダイアログでインストールを押す
git clone https://github.com/YoshitoSuzuki/dotfiles.git ~/dotfiles
~/dotfiles/install.sh      # Homebrew を使わないなら  ~/dotfiles/install.sh --no-brew
```

`xcode-select --install` で入るのは Xcode 本体ではなく、git やコンパイラなどのコマンド一式
（Command Line Tools）。Neovim がプラグインの取得と構文解析器のビルドに使うので必要。

`install.sh` がやること（何度実行しても同じ結果になる）:

1. Homebrew が無ければ入れる（パスワードを聞かれる）。`Brewfile` のアプリを入れる。
   `--no-brew` のときは Homebrew を使わずに入れる（下の「Homebrew を使わない場合」）
2. 設定ファイルをシンボリックリンクで置く。既にあるファイルは `<名前>.backup.<日時>` に退避する
3. herdr の中の Neovim で取り消し線と波線を出すための terminfo を登録する
4. Claude Code の共通設定を `~/.claude` に足す（既存の設定は置き換えない。下の「Claude Code」）
5. 自分用の設定ファイル `~/.config/shell/local.sh` を雛形から作る

一部だけ入れたいときは名前を並べる: `install.sh nvim ghostty`
（`brew` `tools` `zsh` `bash` `ghostty` `herdr` `nvim` `wezterm` `zed` `terminfo` `claude`）

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

### Linux

```sh
sudo apt install git    # Debian / Ubuntu の場合。Fedora なら dnf
git clone https://github.com/YoshitoSuzuki/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Linux では `install.sh` は `~/.bashrc` / `~/.bash_profile` のリンクと `~/.config/shell/local.sh` の
雛形だけを置く。アプリ（Neovim・herdr など）やほかの設定は入れない。
サーバーでは GNU screen など色の扱いが違う環境で開くことが多く、Neovim の配色が崩れるため
（screen 4.x はフルカラーを扱えない）。エイリアス・PATH・関数は macOS と同じものが使える。

- `open` は `xdg-open` に読み替わる。`rm` をゴミ箱送りにしたいなら `trash-cli` を入れる
- 名前を並べれば（`install.sh nvim` など）ほかの設定も入れられるが、想定しているのは macOS だけ

## 入れたあとにやること

1. **Ghostty を開く**（Spotlight で「Ghostty」）。そのまま herdr の画面になる。
   Linux のサーバーなら代わりにログインし直すか `exec bash -l` を実行するだけでよい（以降の手順は不要）
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
