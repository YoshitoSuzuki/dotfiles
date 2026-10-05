# dotfiles

ターミナルまわりの開発環境一式。`install.sh` 1本で、アプリの導入から設定まで終わる。

- **Ghostty**（ターミナル）を開くと **herdr**（AI エージェント向けのターミナルマルチプレクサ）に入る
- シェルは **zsh** と **bash** のどちらでも同じエイリアス・PATH・関数が使える
- エディタは **Neovim**（[LazyVim](https://www.lazyvim.org/) ベース。Markdown を書きながら完成形で表示する）
- **WezTerm** は herdr が固まったときの予備のターミナル
- **Zed** は GUI のエディタ（設定だけ。アプリは各自で入れる）
- 見た目は全部 Tokyo Night + JetBrains Mono Nerd Font で統一

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
4. 自分用の設定ファイル `~/.config/shell/local.sh` を雛形から作る

一部だけ入れたいときは名前を並べる: `install.sh nvim ghostty`
（`brew` `tools` `zsh` `bash` `ghostty` `herdr` `nvim` `wezterm` `zed` `terminfo`）

### Homebrew を使わない場合

会社の Mac などで Homebrew を入れられないときは `install.sh --no-brew` を使う。
各アプリを公式の配布物から直接ダウンロードして、自分のホームの下に入れる。**管理者権限は要らない**。

| もの | 入手元 | 入る場所 |
| --- | --- | --- |
| Ghostty / WezTerm | ghostty.org / GitHub Releases | `~/Applications` |
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

## キー操作

### Ghostty + herdr

herdr の prefix は **`Ctrl+Space`**。Cmd キーの操作は Ghostty が herdr に転送している。

| キー | 動作 |
| --- | --- |
| `Cmd+T` / `Cmd+W` | タブを開く / 閉じる |
| `Cmd+Shift+[` / `Cmd+Shift+]` | 前 / 次のタブ |
| `Cmd+1`〜`9` | 番号のタブへ |
| `Ctrl+Space` → `\` / `-` | 左右 / 上下に分割 |
| `Ctrl+Space` → `w` | ワークスペースを選ぶ（`j` / `k` で移動） |
| `Cmd+Shift+,` | Ghostty の設定を読み直す |

`Cmd+N` と Ghostty 自身のタブ・分割は無効にしている（同じ herdr が二重に映るだけになるため）。

### herdr が使えないとき（Ghostty 単体）

`Ctrl+a` のあとに次のキー。WezTerm でも同じ配置（Leader が `Ctrl+a`）。

| キー | 動作 |
| --- | --- |
| `\` / `-` | 左右 / 上下に分割 |
| `h` `j` `k` `l` | ペインの移動（Shift を足すとサイズ変更） |
| `x` | ペインを閉じる |
| `n` | herdr を通さないシェルを別ウィンドウで開く（herdr の停止・更新用） |

herdr 自体が固まって入力を受け付けないときは WezTerm を開く。

### Neovim

LazyVim の標準のまま（Leader は `Space`。`Space` を押して待つと一覧が出る）。足しているもの:

- Markdown を Obsidian のライブプレビューのように表示する（カーソル行だけ記法に戻る）
- スニペット: `main` と打って `Tab` で雛形を展開（C++ / Go / TeX / .gitignore）。
  TeX の著者名は環境変数 `TEX_AUTHOR` から入る
- TypeScript / React / Tailwind / Go / Java / R / TeX / PHP の LSP と整形

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
| `config/zed/settings.json` | `~/.config/zed/settings.json` | vim モード、保存時の整形、Markdown の折り返し。`zed` コマンドも `~/.local/bin` に置く |
| `config/terminfo/herdr.terminfo` | `~/.terminfo`（`tic` で登録） | 取り消し線・波線を足した `xterm-256color` |
| `Brewfile` | | `install.sh brew` で入るアプリ（macOS） |
| `local.sh.example` | `~/.config/shell/local.sh` | 自分用設定の雛形 |

## 更新

```sh
git -C ~/dotfiles pull
```

設定はリンクなので pull した時点で反映される。開いているものは読み直す:
シェルは `exec $SHELL`、Ghostty は `Cmd+Shift+,`、herdr は `herdr server reload-config`、Neovim は再起動。

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
