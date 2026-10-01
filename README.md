# dotfiles

zsh と bash で同じ操作感になるシェル設定。macOS（Apple Silicon・Homebrew）向け。
macOS 標準の bash 3.2 でも動く。

## 使い方

```sh
git clone https://github.com/YoshitoSuzuki/dotfiles.git ~/dotfiles
~/dotfiles/install.sh          # zsh と bash の両方。片方だけなら install.sh zsh / install.sh bash
exec $SHELL
```

`install.sh` はホームディレクトリに次のシンボリックリンクを置く。既にあるファイルは
`<名前>.backup.<日時>` に退避する。

| リンク | 実体 |
| --- | --- |
| `~/.zshrc`（`ZDOTDIR` があればその下） | `.zshrc` |
| `~/.bashrc` | `.bashrc` |
| `~/.bash_profile` | `.bash_profile` |

更新は `git -C ~/dotfiles pull` だけでよい。

## ファイル構成

| ファイル | 中身 |
| --- | --- |
| `shell/common.sh` | bash と zsh で共通の設定（PATH、エイリアス、関数） |
| `.zshrc` | zsh 固有の設定（履歴、global alias、`hash -d`、プロンプト） |
| `.bashrc` | bash 固有の設定。zsh の機能を bash で再現している |
| `.bash_profile` | ログインシェルの bash から `.bashrc` を読む |
| `local.sh.example` | 自分用設定の雛形 |

## 自分用の設定

人に見せたくない設定や、マシン固有の設定はリポジトリに入れず、次のファイルに書く。
あれば読み込まれる（`install.sh` が `local.sh` を雛形から作る）。

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
```

- zsh: `cd ~proj`、`ls ~proj/foo`
- bash: `cd proj`、`ls $proj/foo`（bash には `~名前` が無いので変数で代用）

## zsh と bash の違い

| 機能 | zsh | bash |
| --- | --- | --- |
| ディレクトリ名だけで移動 | `auto_cd` | `autocd`（bash 4 以降のみ） |
| 入力途中からの履歴検索 | `Ctrl-P` / `Ctrl-N` | 同じ |
| `G` `L` `A`（`\| grep` などの global alias） | 使える | 無い |
| `vim` → `nvim` | 行のどこでも置き換わる | 行頭のみ |
| 右プロンプト | ` ###` | 無い |
| 設定の編集 / 再読み込み | `ezh` / `szh` | `ebh` / `sbh` |
